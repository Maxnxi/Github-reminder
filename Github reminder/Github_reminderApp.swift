//
//  Github_reminderApp.swift
//  Github reminder
//
//  Created by Maksim Ponomarev on 1/13/25.
//

import SwiftUI
import SwiftData

@main
struct Github_reminderApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
//            ContentView()
//			ContributionGrid()
			ContributionGridWithTable()
        }
        .modelContainer(sharedModelContainer)
    }
}
