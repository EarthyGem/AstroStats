//
//  AstroStatsApp.swift
//  AstroStats
//
//  Created by Errick Williams on 5/1/25.
//

import SwiftUI
@main

struct AstroStatsApp: App {
    @StateObject private var personStore = PersonStore()
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            // Single root NavigationView
            NavigationView {
                PeopleListView()
                    .environmentObject(personStore)
                    .environment(\.managedObjectContext, persistenceController.container.viewContext)
            }
        }
    }
}
