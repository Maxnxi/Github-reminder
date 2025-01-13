//
//  ContributionGrid_3.swift
//  Github reminder
//
//  Created by Maksim Ponomarev on 1/13/25.
//

import SwiftUI

//struct ContributionCell: Identifiable {
//	let id = UUID()
//	let date: Date
//	var contributions: Int
//}

struct ContributionGridWithTable_3: View {
	@State private var cells: [[ContributionCell]]
	@State private var selectedCell: ContributionCell?
	@State private var showingPopup = false
	@State private var popupPosition: CGPoint = .zero
	
	var futureContributions: [ContributionCell] {
		let today = Date()
		return cells.flatMap { $0 }
			.filter { $0.contributions > 0 && $0.date >= today }
			.sorted { $0.date < $1.date } // Ascending order
	}
	
	init() {
		let calendar = Calendar.current
		
		// Create date components for January 1st, 2025
		var startComponents = DateComponents()
		startComponents.year = 2025
		startComponents.month = 1
		startComponents.day = 1
		
		// Create date components for December 31st, 2025
		var endComponents = DateComponents()
		endComponents.year = 2025
		endComponents.month = 12
		endComponents.day = 31
		
		let startDate = calendar.date(from: startComponents)!
		let endDate = calendar.date(from: endComponents)!
		
		var allDates: [Date] = []
		var date = startDate
		
		while date <= endDate {
			allDates.append(date)
			date = calendar.date(byAdding: .day, value: 1, to: date)!
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
			// Main Grid with Months
			VStack(alignment: .leading, spacing: 2) {
				// Month Labels
				HStack(spacing: 2) {
					Text("")
						.frame(width: 30)
					ScrollView(.horizontal, showsIndicators: false) {
						HStack(spacing: 2) {
							ForEach(getMonthLabels(), id: \.self) { month in
								Text(month)
									.font(.caption2)
									.frame(width: 50, alignment: .leading)
							}
						}
						.padding(.vertical, 4)
					}
				}
				
				// Grid
				HStack(spacing: 2) {
					VStack(alignment: .trailing, spacing: 2) {
						Text("Mon").font(.caption2)
						Text("Wed").font(.caption2)
						Text("Fri").font(.caption2)
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
								HStack {
									VStack(alignment: .leading) {
										Text(cell.date.formatted(.dateTime.weekday(.wide)))
											.font(.subheadline)
										Text(cell.date.formatted(.dateTime.day().month(.wide).year()))
											.font(.caption)
											.foregroundColor(.secondary)
									}
									
									Spacer()
									
									Text("\(cell.contributions) contribution\(cell.contributions == 1 ? "" : "s")")
										.font(.subheadline)
										.foregroundColor(.green)
								}
								.padding()
								.background(Color(.secondarySystemBackground))
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
	}
	
	func getMonthLabels() -> [String] {
		let dateFormatter = DateFormatter()
		dateFormatter.dateFormat = "MMM"
		
		var months: [String] = []
		var currentMonth = ""
		
		for column in cells {
			if let firstDate = column.first?.date {
				let month = dateFormatter.string(from: firstDate)
				if month != currentMonth {
					months.append(month)
					currentMonth = month
				} else {
					months.append("")
				}
			}
		}
		
		return months
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

// Existing CellView, ContributionPopup, and Array extension remain the same...

#Preview {
	ContributionGridWithTable_3()
		.preferredColorScheme(.dark)
		.padding()
}
