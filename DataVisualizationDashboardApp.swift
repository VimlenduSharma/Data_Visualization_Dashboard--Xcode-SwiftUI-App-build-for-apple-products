//
//  DataVisualizationDashboardApp.swift
//  DataVisualizationDashboard
//
//  Created by Vimlendu Sharma on 23/02/25.
//

import SwiftUI
import SwiftData

@main
struct DataVisualizationDashboardApp: App {
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
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
