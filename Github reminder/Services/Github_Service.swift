//
//  Github_Service.swift
//  Github reminder
//
//  Created by Maksim Ponomarev on 1/15/25.
//


import Foundation

struct GitHubProfile: Codable {
	let login: String
	let name: String?
	let avatarUrl: String
	let bio: String?
	let publicRepos: Int
	let followers: Int
	let following: Int
	let createdAt: String
	
	enum CodingKeys: String, CodingKey {
		case login
		case name
		case avatarUrl = "avatar_url"
		case bio
		case publicRepos = "public_repos"
		case followers
		case following
		case createdAt = "created_at"
	}
}

class GitHubService: ObservableObject {
	@Published var profile: GitHubProfile?
	@Published var isLoading = false
	@Published var error: Error?
	
	private let baseURL = "https://api.github.com"
	
	func fetchProfile(username: String) async {
		isLoading = true
		error = nil
		
		guard let url = URL(string: "\(baseURL)/users/\(username)") else {
			error = NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
			isLoading = false
			return
		}
		
		do {
			let (data, _) = try await URLSession.shared.data(from: url)
			let decoder = JSONDecoder()
			let profile = try decoder.decode(GitHubProfile.self, from: data)
			
			DispatchQueue.main.async {
				self.profile = profile
				self.isLoading = false
			}
		} catch {
			DispatchQueue.main.async {
				self.error = error
				self.isLoading = false
			}
		}
	}
}
