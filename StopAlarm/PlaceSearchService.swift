@preconcurrency import CoreLocation
import Foundation
@preconcurrency import MapKit
import Observation

@MainActor
protocol MapCoordinateResolving: AnyObject {
    func resolveDestination(at coordinate: LocationCoordinate) async -> DestinationResolution
}

@MainActor
@Observable
final class PlaceSearchService: NSObject, @preconcurrency MKLocalSearchCompleterDelegate, MapCoordinateResolving {
    enum ResultsState: Equatable {
        case loading
        case empty
        case failed(String)
        case results
    }

    struct Suggestion: Identifiable {
        let completion: MKLocalSearchCompletion

        var id: String {
            "\(completion.title)|\(completion.subtitle)"
        }

        var title: String { completion.title }
        var subtitle: String { completion.subtitle }
    }

    var suggestions: [Suggestion] = []
    var isLoadingSuggestions = false
    var isResolving = false
    var errorMessage: String?

    var resultsState: ResultsState {
        if suggestions.isEmpty == false { return .results }
        if isLoadingSuggestions { return .loading }
        if let errorMessage { return .failed(errorMessage) }
        return .empty
    }

    @ObservationIgnored
    private let completer: MKLocalSearchCompleter
    @ObservationIgnored
    private var destinationCache: [String: Destination] = [:]
    @ObservationIgnored
    private var destinationTasks: [String: Task<Destination?, Never>] = [:]

    override init() {
        let completer = MKLocalSearchCompleter()
        self.completer = completer
        super.init()
        completer.delegate = self
        completer.resultTypes = [.address, .pointOfInterest]
    }

    func updateQuery(_ query: String) {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        errorMessage = nil

        guard trimmed.isEmpty == false else {
            completer.queryFragment = ""
            suggestions = []
            isLoadingSuggestions = false
            return
        }

        suggestions = []
        isLoadingSuggestions = true
        completer.queryFragment = trimmed
    }

    func updateRegion(_ region: MKCoordinateRegion) {
        completer.region = region
    }

    func destination(for suggestion: Suggestion) async -> Destination? {
        isResolving = true
        errorMessage = nil
        defer { isResolving = false }

        let destination = await cachedDestination(for: suggestion)
        if destination == nil, Task.isCancelled == false {
            errorMessage = AppLocalization.string("ค้นหาสถานที่ไม่สำเร็จ ลองใหม่อีกครั้ง")
        }
        return destination
    }

    /// Resolves a result only to enrich the search row. Failures stay silent so
    /// one unavailable preview never replaces the user's actual search error.
    func previewDestination(for suggestion: Suggestion) async -> Destination? {
        await cachedDestination(for: suggestion)
    }

    private func cachedDestination(for suggestion: Suggestion) async -> Destination? {
        if let cached = destinationCache[suggestion.id] {
            return cached
        }
        if let task = destinationTasks[suggestion.id] {
            return await task.value
        }

        let task = Task { [weak self] in
            try? await self?.searchDestination(for: suggestion)
        }
        destinationTasks[suggestion.id] = task
        let destination = await task.value
        destinationTasks[suggestion.id] = nil
        if let destination {
            destinationCache[suggestion.id] = destination
        }
        return destination
    }

    private func searchDestination(for suggestion: Suggestion) async throws -> Destination? {

        let request = MKLocalSearch.Request(completion: suggestion.completion)
        request.resultTypes = [.address, .pointOfInterest]

        let response = try await MKLocalSearch(request: request).start()
        guard let item = response.mapItems.first else { return nil }
        return destination(from: item)
    }

    func resolveDestination(at coordinate: LocationCoordinate) async -> DestinationResolution {
        isResolving = true
        errorMessage = nil
        defer { isResolving = false }

        let mapCoordinate = CLLocationCoordinate2D(
            latitude: coordinate.latitude,
            longitude: coordinate.longitude
        )
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)

        if #available(iOS 26.0, *),
           let request = MKReverseGeocodingRequest(location: location) {
            do {
                if let item = try await request.mapItems.first {
                    return DestinationResolution(
                        destination: destination(from: item, coordinate: mapCoordinate),
                        isFallback: false
                    )
                }
            } catch is CancellationError {
                return DestinationResolution(
                    destination: fallbackDestination(at: mapCoordinate),
                    isFallback: true
                )
            } catch {
                // A coordinate is still usable when a place name cannot be resolved.
            }
        } else {
            do {
                if let placemark = try await CLGeocoder().reverseGeocodeLocation(location).first {
                    return DestinationResolution(
                        destination: destination(from: placemark, coordinate: mapCoordinate),
                        isFallback: false
                    )
                }
            } catch is CancellationError {
                return DestinationResolution(
                    destination: fallbackDestination(at: mapCoordinate),
                    isFallback: true
                )
            } catch {
                // A coordinate is still usable when a place name cannot be resolved.
            }
        }

        return DestinationResolution(
            destination: fallbackDestination(at: mapCoordinate),
            isFallback: true
        )
    }

    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        suggestions = completer.results.prefix(6).map(Suggestion.init)
        isLoadingSuggestions = false
        errorMessage = nil
    }

    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        suggestions = []
        isLoadingSuggestions = false
        errorMessage = AppLocalization.string("โหลดคำแนะนำไม่สำเร็จ")
    }

    private func destination(
        from item: MKMapItem,
        coordinate: CLLocationCoordinate2D? = nil
    ) -> Destination {
        let coordinate = coordinate ?? item.placemark.coordinate
        let name = nonEmpty(item.name) ?? AppLocalization.string("จุดที่เลือก")
        let detail = addressDetail(
            name: name,
            parts: [
                item.placemark.thoroughfare,
                item.placemark.subLocality,
                item.placemark.locality,
                item.placemark.administrativeArea
            ],
            coordinate: coordinate
        )

        return Destination(
            id: destinationID(for: coordinate),
            name: name,
            detail: detail,
            coordinate: LocationCoordinate(
                latitude: coordinate.latitude,
                longitude: coordinate.longitude
            )
        )
    }

    private func destination(
        from placemark: CLPlacemark,
        coordinate: CLLocationCoordinate2D
    ) -> Destination {
        let name = nonEmpty(placemark.name) ?? AppLocalization.string("จุดที่ปักหมุด")
        let detail = addressDetail(
            name: name,
            parts: [
                placemark.thoroughfare,
                placemark.subLocality,
                placemark.locality,
                placemark.administrativeArea
            ],
            coordinate: coordinate
        )

        return Destination(
            id: destinationID(for: coordinate),
            name: name,
            detail: detail,
            coordinate: LocationCoordinate(
                latitude: coordinate.latitude,
                longitude: coordinate.longitude
            )
        )
    }

    private func fallbackDestination(at coordinate: CLLocationCoordinate2D) -> Destination {
        Destination(
            id: destinationID(for: coordinate),
            name: AppLocalization.string("จุดที่เลือกบนแผนที่"),
            detail: coordinateText(coordinate),
            coordinate: LocationCoordinate(
                latitude: coordinate.latitude,
                longitude: coordinate.longitude
            )
        )
    }

    private func addressDetail(
        name: String,
        parts: [String?],
        coordinate: CLLocationCoordinate2D
    ) -> String {
        let uniqueParts = parts
            .compactMap(nonEmpty)
            .filter { $0.localizedCaseInsensitiveCompare(name) != .orderedSame }
            .reduce(into: [String]()) { result, part in
                guard result.contains(where: { $0.localizedCaseInsensitiveCompare(part) == .orderedSame }) == false else {
                    return
                }
                result.append(part)
            }

        return uniqueParts.isEmpty ? coordinateText(coordinate) : uniqueParts.joined(separator: " · ")
    }

    private func nonEmpty(_ value: String?) -> String? {
        guard let value else { return nil }
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    private func destinationID(for coordinate: CLLocationCoordinate2D) -> String {
        String(format: "%.6f,%.6f", locale: Locale(identifier: "en_US_POSIX"), coordinate.latitude, coordinate.longitude)
    }

    private func coordinateText(_ coordinate: CLLocationCoordinate2D) -> String {
        String(format: "%.5f, %.5f", locale: Locale(identifier: "en_US_POSIX"), coordinate.latitude, coordinate.longitude)
    }
}
