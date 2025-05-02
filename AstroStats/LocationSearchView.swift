//
//  LocationSearchView.swift
//  AstroStats
//
//  Created by Errick Williams on 5/1/25.
//


import SwiftUI
import MapKit
import Combine

struct LocationSearchView: View {
    @Environment(\.presentationMode) var presentationMode
    @Binding var selectedLocation: String
    @Binding var latitude: Double
    @Binding var longitude: Double
    
    @State private var searchText = ""
    @State private var searchResults: [MKLocalSearchCompletion] = []
    @StateObject private var searchCompleter = SearchCompleter()
    
    var body: some View {
        NavigationView {
            VStack {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    
                    TextField("Search location...", text: $searchText)
                        .foregroundColor(.primary)
                        .onChange(of: searchText) { newValue in
                            searchCompleter.searchTerm = newValue
                        }
                    
                    if !searchText.isEmpty {
                        Button(action: {
                            searchText = ""
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding(8)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(.systemGray6))
                )
                .padding(.horizontal)
                .padding(.top)
                
                // Results list
                List(searchCompleter.completions, id: \.self) { result in
                    Button(action: {
                        selectPlace(result)
                    }) {
                        VStack(alignment: .leading) {
                            Text(result.title)
                                .font(.headline)
                            Text(result.subtitle)
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                    }
                }
                .listStyle(PlainListStyle())
                
                // Additional custom locations
                if !searchText.isEmpty {
                    Section(header: Text("Custom Locations").padding(.horizontal)) {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(customLocations.filter { 
                                    $0.lowercased().contains(searchText.lowercased()) 
                                }, id: \.self) { location in
                                    Button(action: {
                                        selectedLocation = location
                                        geocodeCustomLocation(location)
                                    }) {
                                        Text(location)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 8)
                                            .background(Color.blue.opacity(0.2))
                                            .cornerRadius(16)
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                        .padding(.vertical, 8)
                    }
                }
            }
            .navigationTitle("Select Birth Place")
            .navigationBarItems(trailing: Button("Cancel") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
    
    // List of custom locations
    let customLocations: [String] = [
        "Frankenberg-Eder, Germany",
        "Kesswill, Switzerland",
        "Zundert, Netherlands",
        "Quezon City, Philippines",
        "Braunau, Austria",
        "Bolotnoje, Russia",
        "Kiskunfelegyhaza, Hungary"
    ]
    
    private func selectPlace(_ result: MKLocalSearchCompletion) {
        let searchRequest = MKLocalSearch.Request(completion: result)
        let search = MKLocalSearch(request: searchRequest)
        
        search.start { response, error in
            guard let mapItem = response?.mapItems.first,
                  let location = mapItem.placemark.location else {
                return
            }
            
            selectedLocation = "\(result.title), \(result.subtitle)"
            latitude = location.coordinate.latitude
            longitude = location.coordinate.longitude
            presentationMode.wrappedValue.dismiss()
        }
    }
    
    private func geocodeCustomLocation(_ location: String) {
        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(location) { placemarks, error in
            guard let placemark = placemarks?.first,
                  let location = placemark.location else {
                return
            }
            
            latitude = location.coordinate.latitude
            longitude = location.coordinate.longitude
            presentationMode.wrappedValue.dismiss()
        }
    }
}

// SearchCompleter class that properly manages the MKLocalSearchCompleter
class SearchCompleter: NSObject, ObservableObject, MKLocalSearchCompleterDelegate {
    @Published var searchTerm: String = "" {
        didSet {
            searchCompleter.queryFragment = searchTerm
        }
    }
    
    @Published var completions: [MKLocalSearchCompletion] = []
    
    private let searchCompleter = MKLocalSearchCompleter()
    
    override init() {
        super.init()
        searchCompleter.delegate = self
        searchCompleter.resultTypes = .address
    }
    
    // Delegate methods
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        // Filter out street addresses for cleaner results
        let streetIndicators = ["St", "Rd", "Ave", "Ct", "Cir", "Pl", "Dr", "Lane", "Blvd", "Drive", "Way", "Street", "Road", "Avenue", "Court", "Ln", "Boulevard", "Drive", "Terrace", "Place", "Path", "Trail", "Tr", "Trl", "Plaza"]
        
        completions = completer.results.filter { suggestion in
            let components = suggestion.title.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
            let combined = "\(suggestion.title) \(suggestion.subtitle)"
            
            if combined.lowercased().contains("aaefsrgetgeg") {
                return false
            } else if components.count == 2 {
                return true
            } else if components.count == 1 {
                let words = components[0].split(separator: " ").map { String($0) }
                return !words.contains(where: { streetIndicators.contains($0) })
            }
            return false
        }
    }
    
    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        print("Search error: \(error.localizedDescription)")
    }
}

// Preview provider
struct LocationSearchView_Previews: PreviewProvider {
    static var previews: some View {
        LocationSearchView(
            selectedLocation: .constant(""),
            latitude: .constant(0.0),
            longitude: .constant(0.0)
        )
    }
}
