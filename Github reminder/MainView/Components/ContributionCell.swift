//
//  SwiftUIView.swift
//  Github reminder
//
//  Created by Maksim Ponomarev on 1/14/25.
//

import SwiftUI

struct ContributionCell: Identifiable {
	let id = UUID()
	let date: Date
	var contributions: Int
	var completedContributions: Int = 0
}
