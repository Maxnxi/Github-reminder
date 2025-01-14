//
//  ContributionPopup.swift
//  Github reminder
//
//  Created by Maksim Ponomarev on 1/14/25.
//

import SwiftUI

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

//#Preview {
//    ContributionPopup()
//}
