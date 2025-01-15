//
//  ProfileView.swift
//  Github reminder
//
//  Created by Maksim Ponomarev on 1/15/25.
//

import SwiftUI

struct ProfileView: View {
	@StateObject private var githubService = GitHubService()
	@State private var username: String = ""
	@State private var hasSubmitted = false
	
	var body: some View {
		NavigationView {
			ScrollView {
				VStack(spacing: 20) {
					// Username input
					if !hasSubmitted {
						VStack(spacing: 10) {
							TextField("Enter GitHub username", text: $username)
								.textFieldStyle(RoundedBorderTextFieldStyle())
								.autocapitalization(.none)
							
							Button("Load Profile") {
								Task {
									await githubService.fetchProfile(username: username)
									hasSubmitted = true
								}
							}
							.disabled(username.isEmpty)
						}
						.padding()
					}
					
					// Loading state
					if githubService.isLoading {
						ProgressView()
					}
					
					// Error state
					if let error = githubService.error {
						VStack {
							Text("Error loading profile")
								.foregroundColor(.red)
							Text(error.localizedDescription)
								.font(.caption)
							
							Button("Try Again") {
								hasSubmitted = false
								githubService.error = nil
							}
							.padding(.top)
						}
						.padding()
					}
					
					// Profile content
					if let profile = githubService.profile {
						VStack(spacing: 20) {
							// Avatar
							AsyncImage(url: URL(string: profile.avatarUrl)) { image in
								image
									.resizable()
									.aspectRatio(contentMode: .fit)
							} placeholder: {
								ProgressView()
							}
							.frame(width: 120, height: 120)
							.clipShape(Circle())
							.overlay(Circle().stroke(Color.gray, lineWidth: 2))
							
							// Profile info
							VStack(spacing: 8) {
								Text(profile.name ?? profile.login)
									.font(.title2)
									.bold()
								
								if let bio = profile.bio {
									Text(bio)
										.font(.subheadline)
										.foregroundColor(.secondary)
										.multilineTextAlignment(.center)
								}
							}
							
							// Stats
							HStack(spacing: 30) {
								StatView(value: profile.publicRepos, title: "Repos")
								StatView(value: profile.followers, title: "Followers")
								StatView(value: profile.following, title: "Following")
							}
							
							// Member since
							if let date = ISO8601DateFormatter().date(from: profile.createdAt) {
								Text("Member since: \(date.formatted(.dateTime.month().year()))")
									.font(.caption)
									.foregroundColor(.secondary)
							}
							
							// Change user button
							Button("Change User") {
								hasSubmitted = false
								githubService.profile = nil
							}
							.padding(.top)
						}
						.padding()
					}
				}
			}
			.navigationTitle("GitHub Profile")
		}
	}
}

struct StatView: View {
	let value: Int
	let title: String
	
	var body: some View {
		VStack {
			Text("\(value)")
				.font(.title3)
				.bold()
			Text(title)
				.font(.caption)
				.foregroundColor(.secondary)
		}
	}
}

#Preview {
	ProfileView()
}
