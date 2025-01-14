//
//  MonthLabelsView.swift
//  Github reminder
//
//  Created by Maksim Ponomarev on 1/14/25.
//

import SwiftUI

struct MonthLabelsView: View {
	let cells: [[ContributionCell]]
	
	var body: some View {
		ScrollView(.horizontal, showsIndicators: false) {
			HStack(spacing: 2) {
				ForEach(monthLabels(), id: \.offset) { label in
					Text(label.text)
						.font(.caption2)
						.frame(width: CGFloat(label.width * 14), alignment: .leading)
				}
			}
			.padding(.vertical, 4)
		}
	}
	
	struct MonthLabel {
		let text: String
		let offset: Int
		let width: Int
	}
	
	func monthLabels() -> [MonthLabel] {
		let dateFormatter = DateFormatter()
		dateFormatter.dateFormat = "MMM"
		
		var labels: [MonthLabel] = []
		var currentMonth = ""
		var currentWidth = 0
		var offset = 0
		
		for column in cells {
			if let firstDate = column.first?.date {
				let month = dateFormatter.string(from: firstDate)
				if month != currentMonth {
					if !currentMonth.isEmpty {
						labels.append(MonthLabel(text: currentMonth, offset: offset - currentWidth, width: currentWidth))
					}
					currentMonth = month
					currentWidth = 1
				} else {
					currentWidth += 1
				}
			}
			offset += 1
		}
		
		// Add the last month
		if !currentMonth.isEmpty {
			labels.append(MonthLabel(text: currentMonth, offset: offset - currentWidth, width: currentWidth))
		}
		
		return labels
	}
}

//#Preview {
//    MonthLabelsView()
//}
