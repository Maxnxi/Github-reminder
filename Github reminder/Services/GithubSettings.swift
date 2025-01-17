//
//  GithubSettings.swift
//  Github reminder
//
//  Created by Maksim Ponomarev on 1/17/25.
//

import Foundation
import Security

class GithubSettings: ObservableObject {
	@Published var username: String {
		didSet {
			UserDefaults.standard.set(username, forKey: "github_username")
		}
	}
	
	@Published var repository: String {
		didSet {
			UserDefaults.standard.set(repository, forKey: "github_repository")
		}
	}
	
	init() {
		self.username = UserDefaults.standard.string(forKey: "github_username") ?? ""
		self.repository = UserDefaults.standard.string(forKey: "github_repository") ?? ""
	}
	
	// Save token to Keychain
	func saveToken(_ token: String) {
		let tag = "com.github.token"
		let tokenData = token.data(using: .utf8)!
		
		// Delete existing token if exists
		let deleteQuery: [String: Any] = [
			kSecClass as String: kSecClassGenericPassword,
			kSecAttrAccount as String: tag
		]
		SecItemDelete(deleteQuery as CFDictionary)
		
		// Save new token
		let query: [String: Any] = [
			kSecClass as String: kSecClassGenericPassword,
			kSecAttrAccount as String: tag,
			kSecValueData as String: tokenData,
			kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlocked
		]
		
		let status = SecItemAdd(query as CFDictionary, nil)
		if status != errSecSuccess {
			print("Error saving token to Keychain: \(status)")
		}
	}
	
	// Load token from Keychain
	func loadToken() -> String? {
		let tag = "com.github.token"
		let query: [String: Any] = [
			kSecClass as String: kSecClassGenericPassword,
			kSecAttrAccount as String: tag,
			kSecReturnData as String: kCFBooleanTrue!,
			kSecMatchLimit as String: kSecMatchLimitOne
		]
		
		var result: AnyObject?
		let status = SecItemCopyMatching(query as CFDictionary, &result)
		
		guard status == errSecSuccess,
			  let tokenData = result as? Data,
			  let token = String(data: tokenData, encoding: .utf8) else {
			return nil
		}
		
		return token
	}
	
	// Clear all saved data
	func clearAllData() {
		UserDefaults.standard.removeObject(forKey: "github_username")
		UserDefaults.standard.removeObject(forKey: "github_repository")
		
		let tag = "com.github.token"
		let query: [String: Any] = [
			kSecClass as String: kSecClassGenericPassword,
			kSecAttrAccount as String: tag
		]
		SecItemDelete(query as CFDictionary)
		
		username = ""
		repository = ""
	}
}
