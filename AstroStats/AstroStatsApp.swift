//
//  AstroStatsApp.swift
//  AstroStats
//
//  Created by Errick Williams on 5/1/25.
//

import SwiftUI
import Firebase
import FirebaseAuth

@main
struct AstroStatsApp: App {
    @StateObject private var personStore = PersonStore()
    let persistenceController = PersistenceController.shared

    init() {
        FirebaseApp.configure()
        signInAndLoadCharts()
    }

    var body: some Scene {
        WindowGroup {
            PeopleListView()
                .environmentObject(personStore)
        }
    }

    private func signInAndLoadCharts() {
        if Auth.auth().currentUser == nil {
            Auth.auth().signInAnonymously { result, error in
                if let error = error {
                    print("❌ Firebase sign-in failed:", error)

                } else if let user = result?.user {
                    print("✅ Signed in anonymously as: \(user.uid)")
                    personStore.loadCharts(for: user.uid)
                }
            }
        } else {
            let userID = Auth.auth().currentUser!.uid
            print("✅ Already signed in as: \(userID)")
            personStore.loadCharts(for: userID)
        }
    }
}
