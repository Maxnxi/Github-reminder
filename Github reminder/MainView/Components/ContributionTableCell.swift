//
//  ContributionTableCell.swift
//  Github reminder
//
//  Created by Maksim Ponomarev on 1/14/25.
//

import SwiftUI

struct ContributionTableCell: View {
	let cell: ContributionCell
	let onIncrementCompleted: () -> Void
	
	var isToday: Bool {
		Calendar.current.isDateInToday(cell.date)
	}
	
	var body: some View {
		VStack(alignment: .leading, spacing: 4) {
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
			
			if isToday {
				HStack {
					Text("Completed: \(cell.completedContributions)/\(cell.contributions)")
						.font(.caption)
						.foregroundColor(.secondary)
					
					Spacer()
					
					if cell.completedContributions < cell.contributions {
						Button(action: onIncrementCompleted) {
							Image(systemName: "plus.circle.fill")
								.foregroundColor(.green)
						}
					}
				}
				.border(Color.green, width: 1)
			}
		}
		.padding()
		.background(Color(.secondarySystemBackground))
	}
}

//#Preview {
//    ContributionTableCell()
//}
