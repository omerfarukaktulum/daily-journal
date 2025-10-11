//
//  LocationSearchService.swift
//  Memora
//
//  Location autocomplete using MapKit
//

import Foundation
import MapKit
import Combine

@MainActor
class LocationSearchService: NSObject, ObservableObject {
    @Published var searchQuery: String = ""
    @Published var suggestions: [String] = []
    
    private let completer = MKLocalSearchCompleter()
    private var cancellables = Set<AnyCancellable>()
    
    override init() {
        super.init()
        completer.delegate = self
        completer.resultTypes = [.address, .pointOfInterest]
        
        // Debounce search query to avoid too many requests
        $searchQuery
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] query in
                self?.search(query: query)
            }
            .store(in: &cancellables)
    }
    
    private func search(query: String) {
        if query.isEmpty {
            suggestions = []
            completer.cancel()
        } else {
            completer.queryFragment = query
        }
    }
}

extension LocationSearchService: MKLocalSearchCompleterDelegate {
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        suggestions = completer.results.map { result in
            "\(result.title), \(result.subtitle)"
        }
    }
    
    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        print("Location search error: \(error.localizedDescription)")
        suggestions = []
    }
}

