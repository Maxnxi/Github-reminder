//
//  GithubCommitService.swift
//  Github reminder
//
//  Created by Maksim Ponomarev on 1/17/25.
//

import Foundation

class GitHubCommitService: ObservableObject {
	private let baseURL = "https://api.github.com"
	private let logger = DebugLogger.shared
	
	struct CommitError: LocalizedError {
		let message: String
		var errorDescription: String? { message }
	}
	
	enum GitHubError: Error {
		case invalidResponse(String)
		case decodingError(String)
		case apiError(Int, String)
	}
	
	func commitToRepository(
		username: String,
		repository: String,
		token: String,
		content: String,
		commitMessage: String
	) async throws {
		logger.log("Starting commit process...", type: .info)
		
		// First, get the reference to the main branch
		guard let referenceURL = URL(string: "\(baseURL)/repos/\(username)/\(repository)/git/refs/heads/main") else {
			logger.log("Invalid reference URL", type: .error)
			throw CommitError(message: "Invalid reference URL")
		}
		
		logger.log("Fetching reference from: \(referenceURL.absoluteString)", type: .debug)
		
		var request = URLRequest(url: referenceURL)
		request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
		request.setValue("application/json", forHTTPHeaderField: "Content-Type")
		
		let (refData, refResponse) = try await URLSession.shared.data(for: request)
		
		guard let httpResponse = refResponse as? HTTPURLResponse else {
			logger.log("Invalid response type received", type: .error)
			throw GitHubError.invalidResponse("Invalid response type")
		}
		
		if httpResponse.statusCode != 200 {
			let errorMessage = String(data: refData, encoding: .utf8) ?? "Unknown error"
			logger.log("Reference request failed with status \(httpResponse.statusCode): \(errorMessage)", type: .error)
			throw GitHubError.apiError(httpResponse.statusCode, errorMessage)
		}
		
		logger.log("Reference response: \(String(data: refData, encoding: .utf8) ?? "nil")", type: .debug)
		
		// Decode reference response
		let reference: Reference
		do {
			reference = try JSONDecoder().decode(Reference.self, from: refData)
		} catch {
			logger.log("Reference decoding error: \(error)", type: .error)
			throw GitHubError.decodingError("Failed to decode reference: \(error.localizedDescription)")
		}
		
		logger.log("Successfully got reference SHA: \(reference.object.sha)", type: .info)
		
		// Get the current tree
		guard let treeURL = URL(string: "\(baseURL)/repos/\(username)/\(repository)/git/trees/\(reference.object.sha)") else {
			logger.log("Invalid tree URL", type: .error)
			throw CommitError(message: "Invalid tree URL")
		}
		
		logger.log("Fetching tree from: \(treeURL.absoluteString)", type: .debug)
		
		request = URLRequest(url: treeURL)
		request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
		
		let (treeData, treeResponse) = try await URLSession.shared.data(for: request)
		
		guard let treeHttpResponse = treeResponse as? HTTPURLResponse else {
			logger.log("Invalid tree response type", type: .error)
			throw GitHubError.invalidResponse("Invalid tree response type")
		}
		
		if treeHttpResponse.statusCode != 200 {
			let errorMessage = String(data: treeData, encoding: .utf8) ?? "Unknown error"
			logger.log("Tree request failed with status \(treeHttpResponse.statusCode): \(errorMessage)", type: .error)
			throw GitHubError.apiError(treeHttpResponse.statusCode, errorMessage)
		}
		
		logger.log("Tree response: \(String(data: treeData, encoding: .utf8) ?? "nil")", type: .debug)
		
		let currentTree: Tree
		do {
			currentTree = try JSONDecoder().decode(Tree.self, from: treeData)
		} catch {
			logger.log("Tree decoding error: \(error)", type: .error)
			throw GitHubError.decodingError("Failed to decode tree: \(error.localizedDescription)")
		}
		
		logger.log("Successfully got tree SHA: \(currentTree.sha)", type: .info)
		
		// Get current README content
		let readmeContent = try await fetchReadmeContent(
			username: username,
			repository: repository,
			token: token
		)
		
		logger.log("Current README content length: \(readmeContent.count)", type: .debug)
		
		// Create new blob with updated content
		let updatedContent = readmeContent + "\n" + content
		let blob = try await createBlob(
			username: username,
			repository: repository,
			content: updatedContent,
			token: token
		)
		
		logger.log("Created new blob with SHA: \(blob.sha)", type: .info)
		
		// Create new tree
		let newTree = try await createTree(
			username: username,
			repository: repository,
			baseTree: currentTree.sha,
			path: "README.md",
			blobSha: blob.sha,
			token: token
		)
		
		logger.log("Created new tree with SHA: \(newTree.sha)", type: .info)
		
		// Create new commit
		let commit = try await createCommit(
			username: username,
			repository: repository,
			message: commitMessage,
			parentSha: reference.object.sha,
			treeSha: newTree.sha,
			token: token
		)
		
		logger.log("Created new commit with SHA: \(commit.sha)", type: .info)
		
		// Update reference
		try await updateReference(
			username: username,
			repository: repository,
			commitSha: commit.sha,
			token: token
		)
		
		logger.log("Successfully updated reference", type: .info)
	}
	
	private func fetchReadmeContent(
		username: String,
		repository: String,
		token: String
	) async throws -> String {
		logger.log("Fetching README content...", type: .debug)
		
		guard let url = URL(string: "\(baseURL)/repos/\(username)/\(repository)/contents/README.md") else {
			logger.log("Invalid README URL", type: .error)
			throw CommitError(message: "Invalid README URL")
		}
		
		var request = URLRequest(url: url)
		request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
		request.setValue("application/json", forHTTPHeaderField: "Content-Type")
		
		let (data, response) = try await URLSession.shared.data(for: request)
		
		guard let httpResponse = response as? HTTPURLResponse else {
			logger.log("Invalid README response type", type: .error)
			throw GitHubError.invalidResponse("Invalid README response type")
		}
		
		if httpResponse.statusCode != 200 {
			let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
			logger.log("README request failed with status \(httpResponse.statusCode): \(errorMessage)", type: .error)
			throw GitHubError.apiError(httpResponse.statusCode, errorMessage)
		}
		
		logger.log("README response: \(String(data: data, encoding: .utf8) ?? "nil")", type: .debug)
		
		let readme: ReadmeContent
		do {
			readme = try JSONDecoder().decode(ReadmeContent.self, from: data)
		} catch {
			logger.log("README decoding error: \(error)", type: .error)
			throw GitHubError.decodingError("Failed to decode README: \(error.localizedDescription)")
		}
		
		guard let decodedData = Data(base64Encoded: readme.content.replacingOccurrences(of: "\n", with: "")) else {
			logger.log("Failed to decode README content from base64", type: .error)
			throw CommitError(message: "Failed to decode README content from base64")
		}
		
		guard let content = String(data: decodedData, encoding: .utf8) else {
			logger.log("Failed to decode README content to string", type: .error)
			throw CommitError(message: "Failed to decode README content to string")
		}
		
		return content
	}
	
	private func createBlob(
		username: String,
		repository: String,
		content: String,
		token: String
	) async throws -> Blob {
		logger.log("Creating blob...", type: .debug)
		
		guard let url = URL(string: "\(baseURL)/repos/\(username)/\(repository)/git/blobs") else {
			logger.log("Invalid blob URL", type: .error)
			throw CommitError(message: "Invalid blob URL")
		}
		
		var request = URLRequest(url: url)
		request.httpMethod = "POST"
		request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
		request.setValue("application/json", forHTTPHeaderField: "Content-Type")
		
		let blobRequest = ["content": content, "encoding": "utf-8"]
		request.httpBody = try JSONEncoder().encode(blobRequest)
		
		let (data, response) = try await URLSession.shared.data(for: request)
		
		guard let httpResponse = response as? HTTPURLResponse else {
			logger.log("Invalid blob response type", type: .error)
			throw GitHubError.invalidResponse("Invalid blob response type")
		}
		
		if httpResponse.statusCode != 201 {
			let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
			logger.log("Blob creation failed with status \(httpResponse.statusCode): \(errorMessage)", type: .error)
			throw GitHubError.apiError(httpResponse.statusCode, errorMessage)
		}
		
		logger.log("Blob response: \(String(data: data, encoding: .utf8) ?? "nil")", type: .debug)
		
		do {
			return try JSONDecoder().decode(Blob.self, from: data)
		} catch {
			logger.log("Blob decoding error: \(error)", type: .error)
			throw GitHubError.decodingError("Failed to decode blob: \(error.localizedDescription)")
		}
	}
	
	private func createTree(
		username: String,
		repository: String,
		baseTree: String,
		path: String,
		blobSha: String,
		token: String
	) async throws -> Tree {
		logger.log("Creating tree...", type: .debug)
		
		guard let url = URL(string: "\(baseURL)/repos/\(username)/\(repository)/git/trees") else {
			logger.log("Invalid tree URL", type: .error)
			throw CommitError(message: "Invalid tree URL")
		}
		
		var request = URLRequest(url: url)
		request.httpMethod = "POST"
		request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
		request.setValue("application/json", forHTTPHeaderField: "Content-Type")
		
		let treeRequest = [
			"base_tree": baseTree,
			"tree": [
				[
					"path": path,
					"mode": "100644",
					"type": "blob",
					"sha": blobSha
				]
			]
		] as [String : Any]
		
		request.httpBody = try JSONSerialization.data(withJSONObject: treeRequest)
		
		let (data, response) = try await URLSession.shared.data(for: request)
		
		guard let httpResponse = response as? HTTPURLResponse else {
			logger.log("Invalid create tree response type", type: .error)
			throw GitHubError.invalidResponse("Invalid create tree response type")
		}
		
		if httpResponse.statusCode != 201 {
			let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
			logger.log("Tree creation failed with status \(httpResponse.statusCode): \(errorMessage)", type: .error)
			throw GitHubError.apiError(httpResponse.statusCode, errorMessage)
		}
		
		logger.log("Create tree response: \(String(data: data, encoding: .utf8) ?? "nil")", type: .debug)
		
		do {
			return try JSONDecoder().decode(Tree.self, from: data)
		} catch {
			logger.log("Create tree decoding error: \(error)", type: .error)
			throw GitHubError.decodingError("Failed to decode created tree: \(error.localizedDescription)")
		}
	}
	
	private func createCommit(
		username: String,
		repository: String,
		message: String,
		parentSha: String,
		treeSha: String,
		token: String
	) async throws -> Commit {
		logger.log("Creating commit...", type: .debug)
		
		guard let url = URL(string: "\(baseURL)/repos/\(username)/\(repository)/git/commits") else {
			logger.log("Invalid commit URL", type: .error)
			throw CommitError(message: "Invalid commit URL")
		}
		
		var request = URLRequest(url: url)
		request.httpMethod = "POST"
		request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
		request.setValue("application/json", forHTTPHeaderField: "Content-Type")
		
		let commitRequest: [String: Any] = [
			"message": message,
			"parents": [parentSha],
			"tree": treeSha
		]
		
		request.httpBody = try JSONSerialization.data(withJSONObject: commitRequest)
		
		let (data, response) = try await URLSession.shared.data(for: request)
		
		guard let httpResponse = response as? HTTPURLResponse else {
			logger.log("Invalid create commit response type", type: .error)
			throw GitHubError.invalidResponse("Invalid create commit response type")
		}
		
		if httpResponse.statusCode != 201 {
			let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
			logger.log("Commit creation failed with status \(httpResponse.statusCode): \(errorMessage)", type: .error)
			throw GitHubError.apiError(httpResponse.statusCode, errorMessage)
		}
		
		logger.log("Create commit response: \(String(data: data, encoding: .utf8) ?? "nil")", type: .debug)
		
		do {
			return try JSONDecoder().decode(Commit.self, from: data)
		} catch {
			logger.log("Create commit decoding error: \(error)", type: .error)
			throw GitHubError.decodingError("Failed to decode created commit: \(error.localizedDescription)")
		}
	}
	
	private func updateReference(
		username: String,
		repository: String,
		commitSha: String,
		token: String
	) async throws {
		logger.log("Updating reference...", type: .debug)
		
		guard let url = URL(string: "\(baseURL)/repos/\(username)/\(repository)/git/refs/heads/main") else {
			logger.log("Invalid reference URL", type: .error)
			throw CommitError(message: "Invalid reference URL")
		}
		
		var request = URLRequest(url: url)
		request.httpMethod = "PATCH"
		request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
		request.setValue("application/json", forHTTPHeaderField: "Content-Type")
		
		let referenceRequest = [
			"sha": commitSha,
			"force": true
		] as [String : Any]
		
		request.httpBody = try JSONSerialization.data(withJSONObject: referenceRequest)
		
		let (data, response) = try await URLSession.shared.data(for: request)
		
		guard let httpResponse = response as? HTTPURLResponse else {
			logger.log("Invalid update reference response type", type: .error)
			throw GitHubError.invalidResponse("Invalid update reference response type")
		}
		
		if httpResponse.statusCode != 200 {
			let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
			logger.log("Reference update failed with status \(httpResponse.statusCode): \(errorMessage)", type: .error)
			throw GitHubError.apiError(httpResponse.statusCode, errorMessage)
		}
		
		logger.log("Update reference response: \(String(data: data, encoding: .utf8) ?? "nil")", type: .debug)
		logger.log("Successfully completed the commit process! 🎉", type: .info)
	}
}


struct CreateCommitRequest: Codable {
	let message: String
	let parents: [String]
	let tree: String
}


// Response Models
struct Reference: Codable {
	let ref: String?
	let nodeId: String?
	let url: String?
	let object: ReferenceObject
	
	enum CodingKeys: String, CodingKey {
		case ref
		case nodeId = "node_id"
		case url
		case object
	}
}

struct ReferenceObject: Codable {
	let sha: String
	let type: String?
	let url: String?
}

struct Tree: Codable {
	let sha: String
	let url: String?
	let truncated: Bool?
	let tree: [TreeItem]?
}

struct TreeItem: Codable {
	let path: String?
	let mode: String?
	let type: String?
	let sha: String?
	let size: Int?
	let url: String?
}

struct Blob: Codable {
	let sha: String
	let url: String?
	let size: Int?
	let content: String?
	let encoding: String?
}

struct Commit: Codable {
	let sha: String
	let url: String?
	let author: GitAuthor?
	let committer: GitAuthor?
	let message: String?
	let tree: CommitTree?
	let parents: [CommitParent]?
	
	enum CodingKeys: String, CodingKey {
		case sha
		case url
		case author
		case committer
		case message
		case tree
		case parents
	}
}

struct CommitTree: Codable {
	let sha: String
	let url: String?
}

struct CommitParent: Codable {
	let sha: String
	let url: String?
	let htmlUrl: String?
	
	enum CodingKeys: String, CodingKey {
		case sha
		case url
		case htmlUrl = "html_url"
	}
}

struct GitAuthor: Codable {
	let name: String?
	let email: String?
	let date: String?
}

struct ReadmeContent: Codable {
	let name: String?
	let path: String?
	let sha: String?
	let size: Int?
	let url: String?
	let htmlUrl: String?
	let gitUrl: String?
	let downloadUrl: String?
	let type: String?
	let content: String
	let encoding: String?
	
	enum CodingKeys: String, CodingKey {
		case name
		case path
		case sha
		case size
		case url
		case htmlUrl = "html_url"
		case gitUrl = "git_url"
		case downloadUrl = "download_url"
		case type
		case content
		case encoding
	}
}

struct ErrorResponse: Codable {
	let message: String
	let documentationUrl: String?
	
	enum CodingKeys: String, CodingKey {
		case message
		case documentationUrl = "documentation_url"
	}
}
