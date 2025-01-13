//
//  ContributionGridView.swift
//  Github reminder
//
//  Created by Maksim Ponomarev on 1/13/25.
//

import SwiftUI

//struct ContributionGridView: View {
//    var body: some View {
//        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
//    }
//}
//
//#Preview {
//    ContributionGridView()
//}

import SwiftUI

//struct ContributionCell: Identifiable {
//	let id = UUID()
//	let date: Date
//	var contributions: Int
//}

struct ContributionGrid: View {
	@State private var cells: [[ContributionCell]]
	@State private var selectedCell: ContributionCell?
	@State private var showingPopup = false
	@State private var popupPosition: CGPoint = .zero
	
	init() {
		let calendar = Calendar.current
		let today = Date()
		let yearAgo = calendar.date(byAdding: .year, value: -1, to: today)!
		
		var allDates: [Date] = []
		var date = yearAgo
		
		while date <= today {
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
		VStack(alignment: .leading, spacing: 2) {
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
				.border(Color.white, width: 1)
				.foregroundColor(.gray)
				.padding(.trailing, 4)
				
				ScrollView(.horizontal, showsIndicators: true) {
					HStack(spacing: 2) {
						ForEach(Array(cells.enumerated()), id: \.offset) { _, column in
							VStack(spacing: 2) {
								ForEach(column) { cell in
									CellView(cell: cell) { cell, position in
										selectedCell = cell
										popupPosition = position
										showingPopup = true
									}
//									.border(Color.white, width: 1)
								}
							}
						}
					}
					.padding(.vertical, 8)
				}
				.border(Color.white, width: 1)
			}
			
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

struct CellView: View {
	let cell: ContributionCell
	let onTap: (ContributionCell, CGPoint) -> Void
	
	var body: some View {
		GeometryReader { geometry in
			RoundedRectangle(cornerRadius: 2)
				.fill(contributionColor(cell.contributions))
				.frame(width: 12, height: 12)
				.overlay(
					RoundedRectangle(cornerRadius: 2)
						.stroke(Color.gray.opacity(0.2), lineWidth: 0.5)
				)
				.onTapGesture {
					let position = CGPoint(
						x: geometry.frame(in: .global).midX,
						y: geometry.frame(in: .global).midY
					)
					onTap(cell, position)
				}
		}
		.frame(width: 12, height: 12)
	}
	
	func contributionColor(_ value: Int) -> Color {
		switch value {
		case 0: return Color(.darkGray).opacity(0.3)
		case 1: return Color.green.opacity(0.1)
		case 2: return Color.green.opacity(0.3)
		case 3: return Color.green.opacity(0.5)
		case 4: return Color.green.opacity(0.7)
		case 5...9: return Color.green.opacity(0.9)
		default: return Color(.systemBackground)
		}
	}
}

struct ContributionPopup: View {
	let position: CGPoint
	let cell: ContributionCell
	let onSelect: (Int) -> Void
	
	var body: some View {
		VStack(spacing: 8) {
			Text(cell.date.formatted(date: .abbreviated, time: .omitted))
				.font(.caption)
				.foregroundColor(.secondary)
			
			HStack {
				ForEach(0...9, id: \.self) { number in
					Button(action: {
						onSelect(number)
					}) {
						Text("\(number)")
							.font(.caption)
							.padding(8)
							.background(Color(.secondarySystemBackground))
							.cornerRadius(4)
					}
				}
			}
		}
		.padding()
		.background(Color(.systemBackground))
		.cornerRadius(8)
		.shadow(radius: 8)
		.position(x: position.x, y: position.y - 60)
	}
}

extension Array {
	func chunked(into size: Int) -> [[Element]] {
		return stride(from: 0, to: count, by: size).map {
			Array(self[$0 ..< Swift.min($0 + size, count)])
		}
	}
}

#Preview {
	ContributionGrid()
		.preferredColorScheme(.dark)
}
