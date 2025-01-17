//
//  DebugConsoleView.swift
//  Github reminder
//
//  Created by Maksim Ponomarev on 1/17/25.
//

import SwiftUI
import OSLog

class DebugLogger: ObservableObject {
	@Published var logs: [LogEntry] = []
	static let shared = DebugLogger()
	
	struct LogEntry: Identifiable, Equatable {
		let id = UUID()
		let timestamp: Date
		let message: String
		let type: LogType
		
		var formattedTimestamp: String {
			let formatter = DateFormatter()
			formatter.dateFormat = "HH:mm:ss.SSS"
			return formatter.string(from: timestamp)
		}
	}
	
	enum LogType {
		case info
		case error
		case debug
		
		var color: Color {
			switch self {
			case .info: return .green
			case .error: return .red
			case .debug: return .blue
			}
		}
	}
	
	func log(_ message: String, type: LogType = .info) {
		DispatchQueue.main.async {
			self.logs.append(LogEntry(timestamp: Date(), message: message, type: type))
		}
	}
	
	func clear() {
		logs.removeAll()
	}
}

struct ConsoleView: View {
	@StateObject private var logger = DebugLogger.shared
	@State private var autoScroll = true
	@State private var searchText = ""
	
	var filteredLogs: [DebugLogger.LogEntry] {
		if searchText.isEmpty {
			return logger.logs
		}
		return logger.logs.filter { $0.message.localizedCaseInsensitiveContains(searchText) }
	}
	
	var body: some View {
		NavigationView {
			VStack(spacing: 0) {
				// Search bar
				TextField("Search logs...", text: $searchText)
					.textFieldStyle(RoundedBorderTextFieldStyle())
					.padding()
				
				// Logs list
				ScrollViewReader { proxy in
					List(filteredLogs) { entry in
						VStack(alignment: .leading, spacing: 2) {
							HStack(alignment: .top) {
								Text(entry.formattedTimestamp)
									.font(.system(.caption, design: .monospaced))
									.foregroundColor(.gray)
								
								Text(entry.message)
									.font(.system(.body, design: .monospaced))
									.foregroundColor(entry.type.color)
							}
						}
						.listRowBackground(Color(.secondarySystemBackground))
					}
					.onChange(of: logger.logs) { _ in
						if autoScroll {
							withAnimation {
								proxy.scrollTo(filteredLogs.last?.id, anchor: .bottom)
							}
						}
					}
				}
			}
			.navigationTitle("Debug Console")
			.navigationBarTitleDisplayMode(.inline)
			.toolbar {
				ToolbarItem(placement: .navigationBarTrailing) {
					Button(action: { logger.clear() }) {
						Text("Clear")
							.foregroundColor(.red)
					}
				}
				
				ToolbarItem(placement: .navigationBarLeading) {
					Toggle("Auto-scroll", isOn: $autoScroll)
						.toggleStyle(SwitchToggleStyle(tint: .green))
				}
			}
		}
	}
}

#Preview {
	ConsoleView()
}
