//
//  CommitView.swift
//  Github reminder
//
//  Created by Maksim Ponomarev on 1/17/25.
//

import SwiftUI

struct CommitView: View {
	@StateObject private var commitService = GitHubCommitService()
	@StateObject private var settings = GithubSettings()
	
	@State private var token: String = ""
	@State private var content: String = ""
	@State private var commitMessage: String = ""
	
	@State private var isLoading = false
	@State private var errorMessage: String?
	@State private var showingSuccess = false
	@State private var showingError = false
	@State private var showingClearConfirmation = false
	
	init() {
		_token = State(initialValue: GithubSettings().loadToken() ?? "")
	}
	
	var body: some View {
		NavigationView {
			Form {
				Section(header: Text("GitHub Details")) {
					TextField("GitHub Username", text: $settings.username)
						.textInputAutocapitalization(.never)
						.autocorrectionDisabled()
					
					TextField("Repository Name", text: $settings.repository)
						.textInputAutocapitalization(.never)
						.autocorrectionDisabled()
					
					SecureField("GitHub Token", text: $token)
						.textHelp("Requires repo scope access")
						.onChange(of: token) { newValue in
							settings.saveToken(newValue)
						}
				}
				
				Section(header: Text("Commit Details")) {
					TextEditor(text: $content)
						.frame(minHeight: 100)
						.overlay(
							Group {
								if content.isEmpty {
									Text("Content to add to README")
										.foregroundColor(.gray)
										.padding(.leading, 4)
								}
							},
							alignment: .topLeading
						)
					
					TextField("Commit Message", text: $commitMessage)
						.textInputAutocapitalization(.sentences)
				}
				
				Section {
					Button(action: {
						Task {
							await commitChanges()
						}
					}) {
						if isLoading {
							HStack {
								Spacer()
								ProgressView()
									.progressViewStyle(CircularProgressViewStyle())
								Spacer()
							}
						} else {
							Text("Push Changes")
								.frame(maxWidth: .infinity)
						}
					}
					.disabled(isLoading || !isFormValid)
				}
				
				Section {
					Button(role: .destructive) {
						showingClearConfirmation = true
					} label: {
						Text("Clear Saved Data")
							.frame(maxWidth: .infinity)
					}
				}
			}
			.navigationTitle("Make Commit")
			.alert("Success", isPresented: $showingSuccess) {
				Button("OK", role: .cancel) {
					// Clear the content and commit message after successful push
					content = ""
					commitMessage = ""
				}
			} message: {
				Text("Changes have been successfully pushed to GitHub")
			}
			.alert("Error", isPresented: $showingError) {
				Button("OK", role: .cancel) { }
			} message: {
				Text(errorMessage ?? "An unknown error occurred")
			}
			.confirmationDialog(
				"Clear Saved Data",
				isPresented: $showingClearConfirmation,
				titleVisibility: .visible
			) {
				Button("Clear All", role: .destructive) {
					settings.clearAllData()
					token = ""
				}
				Button("Cancel", role: .cancel) { }
			} message: {
				Text("This will clear all saved GitHub credentials. Are you sure?")
			}
		}
	}
	
	private var isFormValid: Bool {
		!settings.username.isEmpty &&
		!settings.repository.isEmpty &&
		!token.isEmpty &&
		!content.isEmpty &&
		!commitMessage.isEmpty
	}
	
	private func commitChanges() async {
		isLoading = true
		errorMessage = nil
		
		do {
			try await commitService.commitToRepository(
				username: settings.username,
				repository: settings.repository,
				token: token,
				content: content,
				commitMessage: commitMessage
			)
			
			showingSuccess = true
		} catch let error as GitHubCommitService.GitHubError {
			switch error {
			case .invalidResponse(let message):
				errorMessage = "Invalid response: \(message)"
			case .decodingError(let message):
				errorMessage = "Failed to process response: \(message)"
			case .apiError(let code, let message):
				errorMessage = "GitHub API error (\(code)): \(message)"
			}
			showingError = true
		} catch {
			errorMessage = error.localizedDescription
			showingError = true
		}
		
		isLoading = false
	}
}

struct TextFieldHelp: ViewModifier {
	let text: String
	
	func body(content: Content) -> some View {
		VStack(alignment: .leading, spacing: 4) {
			content
			Text(text)
				.font(.caption)
				.foregroundColor(.gray)
		}
	}
}

extension View {
	func textHelp(_ text: String) -> some View {
		modifier(TextFieldHelp(text: text))
	}
}

#Preview {
	CommitView()
}
