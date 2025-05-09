import SwiftUI
import Firebase
import FirebaseAuth

@main
struct AstroStatsApp: App {
    @StateObject private var personStore = PersonStore()
    let persistenceController = PersistenceController.shared
    @State private var isInitializing = true

    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                PeopleListView()
                    .environmentObject(personStore)

                // App-level initialization overlay (just for Firebase auth)
                if isInitializing {
                    LoadingOverlayView(message: "Starting AstroStats...")
                        .transition(.opacity)
                        .animation(.easeInOut(duration: 0.3), value: isInitializing)
                }
            }
            .onAppear {
                signInAndLoadCharts()
            }
        }
    }

    private func signInAndLoadCharts() {
        isInitializing = true

        if Auth.auth().currentUser == nil {
            Auth.auth().signInAnonymously { result, error in
                if let error = error {
                    print("❌ Firebase sign-in failed:", error)
                    DispatchQueue.main.async {
                        isInitializing = false
                    }
                } else if let user = result?.user {
                    print("✅ Signed in anonymously as: \(user.uid)")
                    DispatchQueue.main.async {
                        isInitializing = false
                    }
                    // PeopleListView will handle loading charts in its onAppear
                }
            }
        } else {
            let userID = Auth.auth().currentUser!.uid
            print("✅ Already signed in as: \(userID)")
            DispatchQueue.main.async {
                isInitializing = false
            }
            // PeopleListView will handle loading charts in its onAppear
        }
    }
}

