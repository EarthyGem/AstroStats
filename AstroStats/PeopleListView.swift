import SwiftUI

struct PeopleListView: View {
    @EnvironmentObject var personStore: PersonStore
    @State private var showingAddPerson = false
    @State private var searchText = ""
    
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
            List {
                ForEach(filteredPeople) { person in
                    NavigationLink(destination: AstrologyChartView(person: person)) {
                        PersonRowView(person: person)
                    }
                }
                .onDelete(perform: deletePerson)
            }
            .navigationTitle("Astrology Charts")
            .navigationBarItems(
                trailing: Button(action: {
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
        }
    }
    
    private func deletePerson(at offsets: IndexSet) {
        personStore.people.remove(atOffsets: offsets)
    }
}

struct PersonRowView: View {
    let person: Person
    
    var body: some View {
        HStack(spacing: 15) {
            // Planet icon based on strongest planet
            PlanetIcon(planet: person.strongestPlanet ?? "Sun")
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
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        
        return "\(dateFormatter.string(from: person.birthDate)) • \(person.birthPlace)"
    }
}

struct PlanetIcon: View {
    let planet: String
    
    var body: some View {
        ZStack {
            Circle()
                .fill(planetColor)
                .frame(width: 40, height: 40)
            
            Image(systemName: planetSymbol)
                .font(.system(size: 20))
                .foregroundColor(.white)
        }
    }
    
    private var planetColor: Color {
        switch planet.lowercased() {
        case "sun": return .orange
        case "moon": return .blue
        case "mercury": return .purple
        case "venus": return .pink
        case "mars": return .red
        case "jupiter": return .yellow
        case "saturn": return .gray
        case "uranus": return .green
        case "neptune": return .teal
        case "pluto": return .indigo
        default: return .gray
        }
    }
    
    private var planetSymbol: String {
        switch planet.lowercased() {
        case "sun": return "sun.max.fill"
        case "moon": return "moon.fill"
        case "mercury": return "mercury"
        case "venus": return "face.smiling.fill" // Approximation for Venus
        case "mars": return "arrow.up.forward.circle.fill" // Approximation for Mars
        case "jupiter": return "sparkles"
        case "saturn": return "saturn.fill"
        case "uranus": return "circle.grid.cross.fill"
        case "neptune": return "water.waves"
        case "pluto": return "p.circle.fill" // Approximation for Pluto
        default: return "star.fill"
        }
    }
}

struct PeopleListView_Previews: PreviewProvider {
    static var previews: some View {
        PeopleListView()
            .environmentObject(PersonStore())
    }
}