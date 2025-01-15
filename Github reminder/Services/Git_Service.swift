//
//  Git_Service.swift
//  Github reminder
//
//  Created by Maksim Ponomarev on 1/15/25.
//

import Foundation

class GitHubContributionsService {
	private let baseURL = "https://api.github.com/graphql"
	
	func fetchTodayContributions(username: String, token: String) async throws -> Int {
		let query = """
		query {
		  user(login: "\(username)") {
			contributionsCollection {
			  contributionCalendar {
				totalContributions
				weeks {
				  contributionDays {
					contributionCount
					date
				  }
				}
			  }
			}
		  }
		}
		"""
		
		var request = URLRequest(url: URL(string: baseURL)!)
		request.httpMethod = "POST"
		request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
		request.setValue("application/json", forHTTPHeaderField: "Content-Type")
		
		let body = ["query": query]
		request.httpBody = try JSONSerialization.data(withJSONObject: body)
		
		let (data, _) = try await URLSession.shared.data(for: request)
		let decoder = JSONDecoder()
		let response = try decoder.decode(GitHubResponse.self, from: data)
		
		return response.data.user.contributionsCollection.contributionCalendar.weeks.last?.contributionDays.last?.contributionCount ?? 0
	}
}

// Response models
struct GitHubResponse: Codable {
	let data: GitHubData
}

struct GitHubData: Codable {
	let user: GitHubUser
}

struct GitHubUser: Codable {
	let contributionsCollection: ContributionsCollection
}

struct ContributionsCollection: Codable {
	let contributionCalendar: ContributionCalendar
}

struct ContributionCalendar: Codable {
	let totalContributions: Int
	let weeks: [ContributionWeek]
}

struct ContributionWeek: Codable {
	let contributionDays: [ContributionDay]
}

struct ContributionDay: Codable {
	let contributionCount: Int
	let date: String
}
