import MapKit
import FirebaseAuth
import CoreLocation
import SwiftEphemeris
import FirebaseFirestore
struct BirthDataEntryView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var personStore: PersonStore
    
    @State private var name: String = ""
    @State private var birthDate = Date()
    @State private var birthPlace: String = ""
    @State private var showingPlacePicker = false
    @State private var latitude: Double = 0.0
    @State private var longitude: Double = 0.0
    @State private var resolvedTimeZone: TimeZone? = nil

    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showingError = false
    
    private let dateRange: ClosedRange<Date> = {
        let calendar = Calendar.current
        let startComponents = DateComponents(year: 1900, month: 1, day: 1)
        let endComponents = DateComponents(year: 2025, month: 12, day: 31)
        return calendar.date(from: startComponents)!...calendar.date(from: endComponents)!
    }()
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Personal Information")) {
                    TextField("Name", text: $name)
                        .padding(.vertical, 8)
                    
                    DatePicker("Birth Date & Time", selection: $birthDate, in: dateRange, displayedComponents: [.date, .hourAndMinute])
                        .datePickerStyle(GraphicalDatePickerStyle())
                        .padding(.vertical, 8)
                    
                    VStack(alignment: .leading) {
                        Text("Birth Place")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Button(action: {
                            showingPlacePicker = true
                        }) {
                            HStack {
                                Text(birthPlace.isEmpty ? "Select Location" : birthPlace)
                                    .foregroundColor(birthPlace.isEmpty ? .secondary : .primary)
                                Spacer()
                                Image(systemName: "mappin.circle.fill")
                                    .foregroundColor(.blue)
                            }
                        }
                        .padding(.vertical, 8)
                        
                        if latitude != 0 && longitude != 0 {
                            Text("Coordinates: \(latitude, specifier: "%.4f"), \(longitude, specifier: "%.4f")")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Section {
                    Button(action: saveData) {
                        HStack {
                            Spacer()
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                            } else {
                                Text("Save")
                                    .fontWeight(.semibold)
                            }
                            Spacer()
                        }
                    }
                    .disabled(name.isEmpty || birthPlace.isEmpty || isLoading)
                    .padding(.vertical, 8)
                    .listRowBackground(Color.blue.opacity(0.2))
                }
            }
            .navigationTitle("New Birth Chart")
            .sheet(isPresented: $showingPlacePicker) {
                LocationSearchView(selectedLocation: $birthPlace, latitude: $latitude, longitude: $longitude)
            }
            .alert(isPresented: $showingError) {
                Alert(
                    title: Text("Error"),
                    message: Text(errorMessage ?? "An unknown error occurred"),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }
    func resolveTimeZone(for location: CLLocation, birthDate: Date, placeName: String, completion: @escaping (Result<TimeZone, TimeZoneResolutionError>) -> Void) {
        let thresholdDate = Calendar.current.date(from: DateComponents(year: 1883, month: 11, day: 18))!

        CLGeocoder().reverseGeocodeLocation(location) { placemarks, error in
            if let error = error {
                completion(.failure(.custom("Failed to determine time zone: \(error.localizedDescription)")))
                return
            }

            guard let placemark = placemarks?.first, let timeZone = placemark.timeZone else {
                completion(.failure(.custom("Could not resolve time zone from location.")))
                return
            }

            if birthDate < thresholdDate {
                completion(.failure(.custom("This birth date requires using Local Mean Time (LMT), which is not currently supported in this mode.")))
                return
            }

            let override = adjustForTimeZoneException(
                date: birthDate,
                location: placeName,
                latitude: location.coordinate.latitude,
                longitude: location.coordinate.longitude,
                geocodedTimeZoneIdentifier: timeZone.identifier
            )

            if let tz = TimeZone(identifier: override) {
                completion(.success(tz))
            } else {
                completion(.failure(.custom("Unrecognized time zone identifier: \(override)")))
            }
        }
    }
    
    func adjustForTimeZoneException(date: Date, location: String, latitude: Double, longitude: Double, geocodedTimeZoneIdentifier: String) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        // Define the threshold date for using LMT (before standardized time zones were adopted)
        let thresholdDate = Calendar.current.date(from: DateComponents(year: 1883, month: 11, day: 18))!

        // If the date is before the threshold, calculate Local Mean Time (LMT)
        if date < thresholdDate {
            print("Using LMT before \(dateFormatter.string(from: thresholdDate)) for location \(location)")
            return "LMT" // We return a flag to indicate LMT
        }

        // Otherwise, check if there are any time zone exceptions
        let exceptions = loadTimeZoneExceptions()
        print("Adjusting for time zone exceptions on \(dateFormatter.string(from: date)) at location \(location)")

        for exception in exceptions {
            print("Checking exception for \(exception.location) from \(dateFormatter.string(from: exception.startDate)) to \(dateFormatter.string(from: exception.endDate))")
            if exception.location == location,
               date >= exception.startDate,
               date <= exception.endDate {
                print("Time zone exception found for \(location): \(exception.timeZoneIdentifier) overrides geocoded time zone \(geocodedTimeZoneIdentifier)")
                return exception.timeZoneIdentifier
            }
        }

        print("No time zone exception applicable. Using geocoded time zone: \(geocodedTimeZoneIdentifier)")
        return geocodedTimeZoneIdentifier // Use geocoded time zone if no exception found
    }
    func loadTimeZoneExceptions() -> [TimeZoneException] {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let exceptions: [TimeZoneException] = [
            TimeZoneException(location: "Atlanta, GA, United States", startDate: dateFormatter.date(from: "1918-01-01")!, endDate: dateFormatter.date(from: "1931-12-03")!, timeZoneIdentifier: "America/Chicago", offset: "-06:00"),
            TimeZoneException(location: "Hope, AR, United States", startDate: dateFormatter.date(from: "1946-01-01")!, endDate: dateFormatter.date(from: "1946-12-31")!, timeZoneIdentifier: "America/Chicago", offset: "-06:00"),
            TimeZoneException(location: "Louisville, KY, United States", startDate: dateFormatter.date(from: "1942-01-01")!, endDate: dateFormatter.date(from: "1945-12-31")!, timeZoneIdentifier: "America/Chicago", offset: "-04:00"),
            TimeZoneException(location: "Flatwoods, KY, United States", startDate: dateFormatter.date(from: "1961-01-01")!, endDate: dateFormatter.date(from: "1961-12-31")!, timeZoneIdentifier: "America/Chicago", offset: "-04:00")
        ]
        for exception in exceptions {
            print("Loaded time zone exception for \(exception.location) from \(dateFormatter.string(from: exception.startDate)) to \(dateFormatter.string(from: exception.endDate)) with offset \(exception.offset)")
        }
        return exceptions
    }
    
    private func saveData() {
        guard !name.isEmpty, !birthPlace.isEmpty else {
            errorMessage = "Please fill in all fields"
            showingError = true
            return
        }

        isLoading = true

        if latitude != 0 && longitude != 0 {
            let location = CLLocation(latitude: latitude, longitude: longitude)
            resolveTimeZone(for: location, birthDate: birthDate, placeName: birthPlace) { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let timeZone):
                        let adjustedDate = self.applyTimeZone(self.birthDate, with: timeZone)
                        self.resolvedTimeZone = timeZone
                  

                        print("🟢 BIRTH DATA DEBUG:")
                        print("Name: \(self.name)")
                        print("Birthplace: \(self.birthPlace)")
                        print("Latitude: \(self.latitude), Longitude: \(self.longitude)")
                        print("Input BirthDate (local): \(self.birthDate)")
                        print("TimeZone Used: \(timeZone.identifier)")
                        print("Offset: \(timeZone.secondsFromGMT(for: self.birthDate)) seconds")
                        print("Adjusted Date (UTC): \(adjustedDate)")
                        print("✅ Final UTC Date:", adjustedDate)
                        self.addPerson(using: adjustedDate, timeZoneID: timeZone.identifier)


                    case .failure(let error):
                        self.errorMessage = error.localizedDescription
                        self.showingError = true
                        self.isLoading = false
                    }
                }
            
            }
            return
        }

        geocodeLocation()
    }

    private func applyTimeZone(_ date: Date, with timeZone: TimeZone) -> Date {
        // The date was entered assuming it's in the timeZone — but Swift thinks it's in the device’s local time zone.
        // So we reinterpret it as if it was *entered in timeZone*, not currentTimeZone.
        
        let local = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
        
        var components = DateComponents()
        components.year = local.year
        components.month = local.month
        components.day = local.day
        components.hour = local.hour
        components.minute = local.minute
        components.second = local.second
        components.timeZone = timeZone

        // Construct the correctly-localized Date in UTC
        return Calendar(identifier: .gregorian).date(from: components)!
    }

    private func geocodeLocation() {
        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(birthPlace) { placemarks, error in
            DispatchQueue.main.async {
                if let error = error {
                    errorMessage = "Could not find the location: \(error.localizedDescription)"
                    showingError = true
                    isLoading = false
                    return
                }

                guard let placemark = placemarks?.first,
                      let location = placemark.location else {
                    errorMessage = "Invalid location"
                    showingError = true
                    isLoading = false
                    return
                }

                latitude = location.coordinate.latitude
                longitude = location.coordinate.longitude

                resolveTimeZone(for: location, birthDate: birthDate, placeName: birthPlace) { result in
                    DispatchQueue.main.async {
                        switch result {
                        case .success(let timeZone):
                            let adjustedDate = self.applyTimeZone(self.birthDate, with: timeZone)
                            self.resolvedTimeZone = timeZone
                    
                            self.addPerson(using: adjustedDate, timeZoneID: timeZone.identifier)


                            print("✅ Final UTC Date:", adjustedDate)
                        case .failure(let error):
                            self.errorMessage = error.localizedDescription
                            self.showingError = true
                            self.isLoading = false
                        }
                    }
                }
            }
        }
    }
    private func addPerson(using adjustedDate: Date, timeZoneID: String) {
        let newPerson = Person(
            name: name,
            birthDate: adjustedDate,
            birthPlace: birthPlace,
            latitude: latitude,
            longitude: longitude,
            timeZoneID: timeZoneID
        )

        // Reinterpret the adjusted UTC date into local time using timeZoneID
        let timeZone = TimeZone(identifier: timeZoneID) ?? TimeZone(abbreviation: "UTC")!
        let localComponents = Calendar(identifier: .gregorian).dateComponents(in: timeZone, from: adjustedDate)
        var adjustedComponents = DateComponents()
        adjustedComponents.calendar = Calendar(identifier: .gregorian)
        adjustedComponents.timeZone = timeZone
        adjustedComponents.year = localComponents.year
        adjustedComponents.month = localComponents.month
        adjustedComponents.day = localComponents.day
        adjustedComponents.hour = localComponents.hour
        adjustedComponents.minute = localComponents.minute
        adjustedComponents.second = localComponents.second

        guard let interpretedLocalDate = adjustedComponents.date else {
            print("⚠️ Failed to reconstruct interpreted local date")
            self.errorMessage = "Internal date error"
            self.showingError = true
            self.isLoading = false
            return
        }

        let chartCake = ChartCake(
            birthDate: interpretedLocalDate,
            latitude: latitude,
            longitude: longitude,
            name: name,
            sexString: "Male", // <- adjust if needed
            categoryString: "Friend", // <- adjust if needed
            roddenRating: "AA",
            birthPlace: birthPlace
        )

        personStore.calculateAstrologicalData(for: newPerson, using: chartCake) { updatedPerson in
            DispatchQueue.main.async {
                let userID = Auth.auth().currentUser?.uid ?? "unknown_user"
                self.personStore.saveToFirestore(person: updatedPerson, userID: userID)
                self.personStore.people.append(updatedPerson)
                self.isLoading = false
                self.presentationMode.wrappedValue.dismiss()
            }
        }
    }

}


struct BirthDataEntryView_Previews: PreviewProvider {
    static var previews: some View {
        BirthDataEntryView()
            .environmentObject(PersonStore())
    }
}
import Foundation
import SwiftUI

struct Person: Identifiable {
    let id = UUID()
    var documentID: String? // 🔥 Add this line

    let name: String
    let birthDate: Date
    let birthPlace: String
    let latitude: Double
    let longitude: Double
    var timeZoneID: String?

    // Astrological data
    var strongestPlanetSign: String?
    var sunSign: String?
    var moonSign: String?
    var ascendantSign: String?
    var strongestPlanet: String?
    var planetScores: [CelestialObject: Double]?
    var signScores: [Zodiac: Double]?
    var houseScores: [Int: Double]?
    var harmonyDiscordScores: [CelestialObject: (harmony: Double, discord: Double, net: Double)]?
    var signHarmonyDiscordScores: [Zodiac: (harmony: Double, discord: Double, net: Double)]?
    var aspectScores: [(Kind, Double)]?

    // MARK: - Computed Properties

    var strongestSign: String? {
        guard let scores = signScores else { return nil }
        return scores.max(by: { $0.value < $1.value })?.key.keyName
    }

    var strongestHouse: String? {
        guard let scores = houseScores else { return nil }
        if let maxEntry = scores.max(by: { $0.value < $1.value }) {
            return "\(ordinal(maxEntry.key)) House"
        }
        return nil
    }
    var strongestAspectKind: Kind? {
        aspectScores?.first?.0
    }

    func formattedBirthDate() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy 'at' h:mma"
        
        if let tzID = self.timeZoneID, let timeZone = TimeZone(identifier: tzID) {
            formatter.timeZone = timeZone
        }
        
        return formatter.string(from: birthDate)
    }

    // MARK: - Initializer

    init(name: String, birthDate: Date, birthPlace: String, latitude: Double, longitude: Double, timeZoneID: String? = nil, documentID: String? = nil) {
        self.name = name
        self.birthDate = birthDate
        self.birthPlace = birthPlace
        self.latitude = latitude
        self.longitude = longitude
        self.timeZoneID = timeZoneID
        self.documentID = documentID
    }

    // MARK: - Helper

    private func ordinal(_ number: Int) -> String {
        switch number {
        case 1: return "1st"
        case 2: return "2nd"
        case 3: return "3rd"
        case 21: return "21st"
        case 22: return "22nd"
        case 23: return "23rd"
        default: return "\(number)th"
        }
    }
}

import Foundation
import FirebaseFirestore
import SwiftUI

class PersonStore: ObservableObject {
    @Published var people: [Person] = []
    @Published var editingPerson: Person? = nil
    @Published var isLoading = false

    init() {
        // Empty initializer
    }

    func loadCharts(for userID: String, completion: ((Bool) -> Void)? = nil) {
        self.isLoading = true
        print("🔍 Loading charts for user: \(userID)")

        let db = Firestore.firestore()
        db.collection("users").document(userID).collection("charts").getDocuments { snapshot, error in
            if let error = error {
                print("❌ Error loading charts: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.isLoading = false
                    completion?(false)
                }
                return
            }

            guard let documents = snapshot?.documents else {
                print("⚠️ No documents found")
                DispatchQueue.main.async {
                    self.isLoading = false
                    completion?(true)
                }
                return
            }

            print("📊 Found \(documents.count) charts")
            var loadedPeople: [Person] = []
            let group = DispatchGroup()

            for doc in documents {
                let data = doc.data()

                guard let name = data["name"] as? String,
                      let birthPlace = data["birthPlace"] as? String,
                      let latitude = data["latitude"] as? Double,
                      let longitude = data["longitude"] as? Double,
                      let timeStamp = data["birthDate"] as? Timestamp else {
                    print("⚠️ Missing required fields in document")
                    continue
                }

                let birthDate = timeStamp.dateValue()
                let timeZoneID = data["timeZone"] as? String
                let docID = doc.documentID

                let person = Person(
                    name: name,
                    birthDate: birthDate,
                    birthPlace: birthPlace,
                    latitude: latitude,
                    longitude: longitude,
                    timeZoneID: timeZoneID,
                    documentID: docID
                )

                // Safely interpret local time
                let timeZone = TimeZone(identifier: timeZoneID ?? "UTC") ?? TimeZone(abbreviation: "UTC")!
                let localComponents = Calendar(identifier: .gregorian).dateComponents(in: timeZone, from: birthDate)
                var adjustedComponents = DateComponents()
                adjustedComponents.calendar = Calendar(identifier: .gregorian)
                adjustedComponents.timeZone = timeZone
                adjustedComponents.year = localComponents.year
                adjustedComponents.month = localComponents.month
                adjustedComponents.day = localComponents.day
                adjustedComponents.hour = localComponents.hour
                adjustedComponents.minute = localComponents.minute
                adjustedComponents.second = localComponents.second

                guard let interpretedLocalDate = adjustedComponents.date else {
                    print("⚠️ Failed to reconstruct local date for chart: \(name)")
                    continue
                }

                let chartCake = ChartCake(
                    birthDate: interpretedLocalDate,
                    latitude: latitude,
                    longitude: longitude,
                    name: name,
                    sexString: "Male", // ← customize as needed
                    categoryString: "Friend", // ← customize as needed
                    roddenRating: "AA",
                    birthPlace: birthPlace
                )

                group.enter()
                self.calculateAstrologicalData(for: person, using: chartCake) { fullPerson in
                    loadedPeople.append(fullPerson)
                    group.leave()
                }
            }

            group.notify(queue: .main) {
                self.people = loadedPeople.sorted(by: { $0.name < $1.name })
                self.isLoading = false
                completion?(true)
                print("✅ Charts loaded and calculated successfully")
            }
        }
    }

    func saveToFirestore(person: Person, userID: String, completion: ((Bool) -> Void)? = nil) {
        let db = Firestore.firestore()
        let chartData: [String: Any] = [
            "id": person.id.uuidString,
            "name": person.name,
            "birthDate": Timestamp(date: person.birthDate),
            "birthPlace": person.birthPlace,
            "latitude": person.latitude,
            "longitude": person.longitude,
            "timeZone": person.timeZoneID
        ]

        let docID = person.documentID ?? person.id.uuidString

        db.collection("users").document(userID).collection("charts").document(docID).setData(chartData) { error in
            if let error = error {
                print("❌ Error saving chart: \(error.localizedDescription)")
                completion?(false)
            } else {
                print("✅ Chart saved to Firestore")
                completion?(true)
            }
        }
    }

    func calculateAstrologicalData(for person: Person, using chartCake: ChartCake, completion: @escaping (Person) -> Void) {
        DispatchQueue.global().async {
            var updatedPerson = person

            // Use existing chartCake — DO NOT rebuild it here
            updatedPerson.strongestPlanetSign = chartCake.strongestPlanetSign.keyName
            updatedPerson.sunSign = chartCake.natal.sun.sign.keyName
            updatedPerson.moonSign = chartCake.natal.moon.sign.keyName
            updatedPerson.ascendantSign = chartCake.ascendant.sign.keyName
            updatedPerson.strongestPlanet = chartCake.strongestPlanetSN.keyName
            updatedPerson.planetScores = chartCake.planetScoresSN.mapValues { Double($0) }
            updatedPerson.signScores = chartCake.signScoresSN.mapKeys { $0 }
            updatedPerson.houseScores = chartCake.houseScoresSN
            updatedPerson.harmonyDiscordScores = chartCake.planetHarmonyDiscord.mapValues {
                (harmony: $0.harmony, discord: $0.discord, net: $0.netHarmony)
            }

            // ✅ Correctly placed outside of closure
            updatedPerson.aspectScores = chartCake.natal.totalScoresByAspectType()

            print("🧪 CALCULATION DEBUG (with passed chartCake):")
            print("Name: \(updatedPerson.name)")
            print("Strongest Planet: \(updatedPerson.strongestPlanet ?? "-")")
            print("Sun: \(updatedPerson.sunSign ?? "-")")
            print("Moon: \(updatedPerson.moonSign ?? "-")")
            print("Ascendant: \(updatedPerson.ascendantSign ?? "-")")

            DispatchQueue.main.async {
                completion(updatedPerson)
            }
        }
    }
}




struct TimeZoneException {
    let location: String
    let startDate: Date
    let endDate: Date
    let timeZoneIdentifier: String
    let offset: String // "+hh:mm" or "-hh:mm"
}
enum TimeZoneResolutionError: Error, LocalizedError {
    case custom(String)
    
    var errorDescription: String? {
        switch self {
        case .custom(let message): return message
        }
    }
}
