import MapKit
import CoreLocation
import SwiftEphemeris

struct BirthDataEntryView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var personStore: PersonStore
    
    @State private var name: String = ""
    @State private var birthDate = Date()
    @State private var birthPlace: String = ""
    @State private var showingPlacePicker = false
    @State private var latitude: Double = 0.0
    @State private var longitude: Double = 0.0
    
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
                        self.addPerson()

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
        let calendar = Calendar(identifier: .gregorian)
        let localComponents = calendar.dateComponents(in: TimeZone.current, from: date)
        
        var components = DateComponents()
        components.year = localComponents.year
        components.month = localComponents.month
        components.day = localComponents.day
        components.hour = localComponents.hour
        components.minute = localComponents.minute
        components.second = localComponents.second
        components.timeZone = timeZone
        
        return calendar.date(from: components) ?? date
    }

    private func geocodeLocation() {
        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(birthPlace) { placemarks, error in
            DispatchQueue.main.async {
                isLoading = false
                
                if let error = error {
                    errorMessage = "Could not find the location: \(error.localizedDescription)"
                    showingError = true
                    return
                }
                
                guard let placemark = placemarks?.first,
                      let location = placemark.location else {
                    errorMessage = "Invalid location"
                    showingError = true
                    return
                }
                
                latitude = location.coordinate.latitude
                longitude = location.coordinate.longitude
                
                addPerson()
            }
        }
    }
    
    private func addPerson() {
        let newPerson = Person(
            name: name,
            birthDate: birthDate,
            birthPlace: birthPlace,
            latitude: latitude,
            longitude: longitude
        )
        
        // Calculate astrological data for the person
        personStore.calculateAstrologicalData(for: newPerson) { updatedPerson in
            DispatchQueue.main.async {
                personStore.people.append(updatedPerson)
                isLoading = false
                presentationMode.wrappedValue.dismiss()
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
    let name: String
    let birthDate: Date
    let birthPlace: String
    let latitude: Double
    let longitude: Double
    
    // Astrological data
    var sunSign: String?
    var moonSign: String?
    var ascendantSign: String?
    var strongestPlanet: String?
    var planetScores: [CelestialObject: Double]?
    var signScores: [Zodiac: Double]?
    var houseScores: [Int: Double]?
    var harmonyDiscordScores: [CelestialObject: (harmony: Double, discord: Double, net: Double)]?
    var signHarmonyDiscordScores: [Zodiac: (harmony: Double, discord: Double, net: Double)]?
    init(name: String, birthDate: Date, birthPlace: String, latitude: Double, longitude: Double) {
        self.name = name
        self.birthDate = birthDate
        self.birthPlace = birthPlace
        self.latitude = latitude
        self.longitude = longitude
    }
}

class PersonStore: ObservableObject {
    @Published var people: [Person] = []
    
    init() {
   
    }
    
   
    
    func calculateAstrologicalData(for person: Person, completion: @escaping (Person) -> Void) {
        DispatchQueue.global().async {
            let chartCake = ChartCake(
                birthDate: person.birthDate,
                latitude: person.latitude,
                longitude: person.longitude,
                name: person.name,
                sexString: "Male", // you might want to add sex input in your BirthDataEntryView
                categoryString: "Friend", // adjust based on user input
                roddenRating: "AA",
                birthPlace: person.birthPlace
            )

            var updatedPerson = person
            updatedPerson.sunSign = chartCake.natal.sun.sign.keyName
            updatedPerson.moonSign = chartCake.natal.moon.sign.keyName
            updatedPerson.ascendantSign = chartCake.ascendant.sign.keyName
            updatedPerson.strongestPlanet = chartCake.strongestPlanet.keyName
            updatedPerson.planetScores = chartCake.planetScores.mapValues { Double($0) }
            updatedPerson.signScores = chartCake.signScores.mapKeys { $0 }
            updatedPerson.houseScores = chartCake.houseScores
            updatedPerson.harmonyDiscordScores = chartCake.planetHarmonyDiscord.mapValues {
                (harmony: $0.harmony, discord: $0.discord, net: $0.netHarmony)
            }

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
