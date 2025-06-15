import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct PeopleListView: View {
    @EnvironmentObject var personStore: PersonStore
    @State private var showingAddPerson = false
    @State private var searchText = ""
    @State private var showLoadingAlert = false

    var filteredPeople: [Person] {
        if searchText.isEmpty {
            return personStore.people
        } else {
            return personStore.people.filter { person in
                person.name.lowercased().contains(searchText.lowercased()) ||
                person.birthPlace.lowercased().contains(searchText.lowercased())
            }
        }
    }

    var body: some View {
        NavigationView {
            ZStack {
                List {
                    ForEach(filteredPeople) { person in
                        NavigationLink(destination: AstrologyChartView(person: person)) {
                            PersonRowView(person: person)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                if let index = personStore.people.firstIndex(where: { $0.id == person.id }) {
                                    deletePerson(at: IndexSet(integer: index))
                                }
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                        .swipeActions(edge: .leading, allowsFullSwipe: false) {
                            Button {
                                personStore.editingPerson = person
                                showingAddPerson = true
                            } label: {
                                Label("Edit", systemImage: "pencil")
                            }
                            .tint(.blue)
                        }
                    }
                }
                .navigationTitle("Astrology Charts")
                .navigationBarItems(
                    trailing: Button(action: {
                        personStore.editingPerson = nil
                        showingAddPerson = true
                    }) {
                        Image(systemName: "plus")
                            .font(.title2)
                    }
                )
                .sheet(isPresented: $showingAddPerson) {
                    BirthDataEntryView()
                        .environmentObject(personStore)
                }
                .searchable(text: $searchText, prompt: "Search by name or place")
                .onAppear {
                    if let userID = Auth.auth().currentUser?.uid {
                        showLoadingAlert = true
                        personStore.loadCharts(for: userID) { success in
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                showLoadingAlert = false
                            }
                        }
                    }
                }

                if personStore.isLoading {
                    LoadingOverlayView(message: "Loading your charts...")
                }
            }
        }
    }

    private func deletePerson(at offsets: IndexSet) {
        guard let userID = Auth.auth().currentUser?.uid else {
            print("❌ No UID. Cannot delete.")
            return
        }

        for index in offsets {
            let person = personStore.people[index]
            let docID = person.documentID ?? person.id.uuidString // fallback if needed

            print("🗑️ Attempting to delete: \(docID) for \(person.name)")

            Firestore.firestore()
                .collection("users")
                .document(userID)
                .collection("charts")
                .document(docID)
                .delete { error in
                    if let error = error {
                        print("❌ Firestore delete error:", error.localizedDescription)
                    } else {
                        print("✅ Firestore chart deleted: \(person.name)")
                    }
                }
        }

        personStore.people.remove(atOffsets: offsets)
    }
}

import SwiftUI

struct LoadingOverlayView: View {
    var message: String
    var detailMessage: String? = nil

    var body: some View {
        ZStack {
            // Semi-transparent background
            Color.black.opacity(0.15)
                .ignoresSafeArea()

            // Loading card
            VStack(spacing: 20) {
                // Custom loading spinner
                LoadingSpinner()
                    .frame(width: 50, height: 50)

                VStack(spacing: 8) {
                    // Main message
                    Text(message)
                        .font(.headline)
                        .fontWeight(.medium)
                        .multilineTextAlignment(.center)

                    // Optional detail message
                    if let detailMessage = detailMessage {
                        Text(detailMessage)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical, 24)
            .padding(.horizontal, 24)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(UIColor.systemBackground))
                    .shadow(color: Color.black.opacity(0.15), radius: 15, x: 0, y: 4)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.gray.opacity(0.1), lineWidth: 1)
            )
            .frame(width: 260)
            .transition(.opacity)
            .animation(.easeInOut(duration: 0.3), value: true)
        }
    }
}

// Custom animated loading spinner
struct LoadingSpinner: View {
    @State private var isAnimating = false

    var body: some View {
        ZStack {
            // Background circle
            Circle()
                .stroke(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.gray.opacity(0.2), Color.gray.opacity(0.05)]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 4
                )

            // Spinning gradient arc
            Circle()
                .trim(from: 0, to: 0.7)
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: [Color.purple.opacity(0.8), Color.blue, Color.purple.opacity(0.2)]),
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 4, lineCap: .round)
                )
                .rotationEffect(Angle(degrees: isAnimating ? 360 : 0))
                .animation(
                    Animation.linear(duration: 1.5)
                        .repeatForever(autoreverses: false),
                    value: isAnimating
                )
        }
        .onAppear {
            isAnimating = true
        }
    }
}

// Preview for design time
struct LoadingOverlayView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.gray.opacity(0.2).ignoresSafeArea()

            VStack(spacing: 40) {
                LoadingOverlayView(message: "Loading your charts...")

                LoadingOverlayView(
                    message: "Loading your charts...",
                    detailMessage: "Please wait while we calculate your astrological data"
                )
            }
        }
    }
}
struct PersonRowView: View {
    let person: Person

    var body: some View {
        HStack(spacing: 15) {
            PlanetIcon(planet: person.strongestPlanet ?? "Sun", sign: person.strongestPlanetSign ?? "Gemini")
                .frame(width: 40, height: 40)

            VStack(alignment: .leading, spacing: 4) {
                Text(person.name)
                    .font(.headline)

                Text(formatBirthInfo())
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Text("\(person.sunSign ?? "Unknown") Sun • \(person.moonSign ?? "Unknown") Moon • \(person.ascendantSign ?? "Unknown") Rising")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 6)
    }

    private func formatBirthInfo() -> String {
        // Simply use the person's formattedBirthDate() method instead of creating a new formatter
        return "\(person.formattedBirthDate()) • \(person.birthPlace)"
    }
}

struct PlanetIcon: View {
    let planet: String
    let sign: String // NEW: sign of the planet, e.g., "Aries"

    var body: some View {
        ZStack {
            Circle()
                .fill(signColor) // Use sign color instead of planet color
                .frame(width: 40, height: 40)

            GlyphProvider.planetImage(for: planet)
                .resizable()
                .scaledToFit()
                .frame(width: 20, height: 20)
                .foregroundColor(.white)
        }
    }

    private var signColor: Color {
        switch sign {
        case "Aries":        return Color.red.opacity(0.5)        // Mars, masculine → light red
        case "Taurus":       return Color.yellow.opacity(0.9)     // Venus, feminine → dark yellow
        case "Gemini":       return Color.violet.opacity(0.5)     // Mercury, masculine → light violet
        case "Cancer":       return Color.green.opacity(0.9)      // Moon, feminine → dark green
        case "Leo":          return Color.orange.opacity(0.5)     // Sun, masculine → light orange
        case "Virgo":        return Color.violet.opacity(0.9)     // Mercury, feminine → dark violet
        case "Libra":        return Color.yellow.opacity(0.5)     // Venus, masculine → light yellow
        case "Scorpio":      return Color.red.opacity(0.9)        // Mars, feminine → dark red
        case "Sagittarius":  return Color.indigo.opacity(0.5)     // Jupiter, masculine → light indigo
        case "Capricorn":    return Color.blue.opacity(0.9)       // Saturn, feminine → dark blue
        case "Aquarius":     return Color.blue.opacity(0.5)       // Saturn, masculine → light blue
        case "Pisces":       return Color.indigo.opacity(0.9)     // Jupiter, feminine → dark indigo
        default:             return Color.gray
        }
    }

}




extension Color {
    static let violet = Color(red: 0.56, green: 0.0, blue: 1.0) // Approximate violet
}
