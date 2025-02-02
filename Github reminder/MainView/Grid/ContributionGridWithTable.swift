//
//  ContributionGridWithTable.swift
//  Github reminder
//
//  Created by Maksim Ponomarev on 1/14/25.
//

import SwiftUI

struct ContributionGridWithTable: View {
	@State private var cells: [[ContributionCell]]
	@State private var selectedCell: ContributionCell?
	@State private var showingPopup = false
	@State private var popupPosition: CGPoint = .zero
	
	@State private var todayContributions: Int = 0
	
	func fetchGitHubContributions() async {
		do {
			let service = GitHubContributionsService()
			let contributions = try await service.fetchTodayContributions(
				username: "Maxnxi", // "YOUR_GITHUB_USERNAME",
				token: "YOUR_GITHUB_TOKEN"
			)
			debugPrint("Users today contributions: \(contributions)")
			// Update the UI with the fetched contributions
			if let idx = cells.firstIndex(where: { $0.contains(where: { Calendar.current.isDateInToday($0.date) }) }) {
				if let cellIdx = cells[idx].firstIndex(where: { Calendar.current.isDateInToday($0.date) }) {
					cells[idx][cellIdx].contributions = contributions
				}
			}
		} catch {
			print("Error fetching contributions:", error)
		}
	}
	
	func isToday(date: Date) -> Bool {
		Calendar.current.isDateInToday(date)
	}
	
	var futureContributions: [ContributionCell] {
		let today = Date()
		
		return cells.flatMap { $0 }
			.filter {
				$0.contributions > 0 &&
				(isToday(date: $0.date) || $0.date >= today)
			}
			.sorted { $0.date < $1.date }
	}
	
	init() {
		var calendar = Calendar.current
		calendar.firstWeekday = 1  // 1 means Sunday is the first day
		
		var startComponents = DateComponents()
		startComponents.year = 2025
		startComponents.month = 1
		startComponents.day = 1
		
		var endComponents = DateComponents()
		endComponents.year = 2025
		endComponents.month = 12
		endComponents.day = 31
		
		let startDate = calendar.date(from: startComponents)!
		let endDate = calendar.date(from: endComponents)!
		
		// If start date isn't a Sunday, we need to go back to the previous Sunday
		var currentDate = startDate
		while calendar.component(.weekday, from: currentDate) != 1 {  // 1 is Sunday
			currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate)!
		}
		
		var allDates: [Date] = []
		while currentDate <= endDate {
			allDates.append(currentDate)
			currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
		}
		
		// Add remaining days until Saturday if needed
		while calendar.component(.weekday, from: currentDate) != 7 {  // 7 is Saturday
			allDates.append(currentDate)
			currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
		}
		
		let weeks = allDates.chunked(into: 7)
		_cells = State(initialValue: weeks.map { week in
			week.map { date in
				ContributionCell(date: date, contributions: 0)
			}
		})
	}
	
	var body: some View {
		VStack(alignment: .leading, spacing: 16) {
			VStack(alignment: .leading, spacing: 2) {
				// Month Labels
				HStack(spacing: 2) {
					Text("")
						.frame(width: 30)
					MonthLabelsView(cells: cells)
				}
				
				// Grid
				HStack(spacing: 2) {
					VStack(alignment: .trailing, spacing: 1) {
						Text("Sun").font(.caption2)
						Text("Mon").font(.caption2)
						Text("Tue").font(.caption2)
						Text("Wed").font(.caption2)
						Text("Thu").font(.caption2)
						Text("Fri").font(.caption2)
						Text("Sat").font(.caption2)
					}
					.foregroundColor(.gray)
					.padding(.trailing, 4)
					
					ScrollView(.horizontal, showsIndicators: false) {
						HStack(spacing: 2) {
							ForEach(Array(cells.enumerated()), id: \.offset) { _, column in
								VStack(spacing: 2) {
									ForEach(column) { cell in
										CellView(cell: cell) { cell, position in
											selectedCell = cell
											popupPosition = position
											showingPopup = true
										}
									}
								}
							}
						}
						.padding(.vertical, 8)
					}
				}
				
				// Legend
				HStack {
					Text("Less")
					ForEach(0..<5) { level in
						RoundedRectangle(cornerRadius: 2)
							.fill(contributionColor(level * 2))
							.frame(width: 12, height: 12)
					}
					Text("More")
				}
				.font(.caption2)
				.foregroundColor(.gray)
			}
			
			// Future Contributions Table
			if !futureContributions.isEmpty {
				VStack(alignment: .leading, spacing: 8) {
					Text("Upcoming Contributions")
						.font(.headline)
					
					ScrollView {
						VStack(spacing: 1) {
							ForEach(futureContributions) { cell in
								ContributionTableCell(
									cell: cell,
									onIncrementCompleted: { incrementCompletedContributions(for: cell) }
								)
							}
						}
					}
					.frame(maxHeight: 300)
				}
			}
		}
		.overlay(
			Group {
				if showingPopup {
					ContributionPopup(
						position: popupPosition,
						cell: selectedCell!,
						onSelect: { value in
							if let idx = cells.firstIndex(where: { $0.contains(where: { $0.id == selectedCell?.id }) }) {
								if let cellIdx = cells[idx].firstIndex(where: { $0.id == selectedCell?.id }) {
									cells[idx][cellIdx].contributions = value
								}
							}
							showingPopup = false
						}
					)
				}
			}
		)
		.task {
			await fetchGitHubContributions()
		}
	}
	
	func incrementCompletedContributions(for cell: ContributionCell) {
		if let idx = cells.firstIndex(where: { $0.contains(where: { $0.id == cell.id }) }) {
			if let cellIdx = cells[idx].firstIndex(where: { $0.id == cell.id }) {
				if cells[idx][cellIdx].completedContributions < cells[idx][cellIdx].contributions {
					cells[idx][cellIdx].completedContributions += 1
				}
			}
		}
	}
	
	func contributionColor(_ value: Int) -> Color {
		switch value {
		case 0: return Color(.systemBackground)
		case 1: return Color.green.opacity(0.1)
		case 2: return Color.green.opacity(0.3)
		case 3: return Color.green.opacity(0.5)
		case 4: return Color.green.opacity(0.7)
		case 5...9: return Color.green.opacity(0.9)
		default: return Color(.systemBackground)
		}
	}
}

#Preview {
    ContributionGridWithTable()
}
