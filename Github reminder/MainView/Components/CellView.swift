//
//  CellView.swift
//  Github reminder
//
//  Created by Maksim Ponomarev on 1/14/25.
//

import SwiftUI

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

//#Preview {
//    CellView()
//}
