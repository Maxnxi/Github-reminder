//
//  MainView.swift
//  Github reminder
//
//  Created by Maksim Ponomarev on 1/14/25.
//

import SwiftUI

struct MainView: View {
	var body: some View {
		TabView {
			ContributionGridWithTable()
				.tabItem {
					Label("Desired", systemImage: "calendar")
				}
			
			ProfileView()
				.tabItem {
					Label("Profile", systemImage: "person.circle")
				}
			
			CommitView()
				.tabItem {
					Label("Commit", systemImage: "arrow.up.doc")
				}
		}
	}
}

#Preview {
	MainView()
}
