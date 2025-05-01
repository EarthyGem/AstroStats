//
//  AstroStatsApp.swift
//  AstroStats
//
//  Created by Errick Williams on 5/1/25.
//

import SwiftUI

@main
struct AstroStatsApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
