import Foundation
import Testing
@testable import NapNav

@MainActor
@Suite("Destination selection")
struct DestinationSelectionTests {
    @Test("Search suggestion state distinguishes loading, empty, and failure")
    func searchResultsStateShowsLoadingAndErrorsInsteadOfFalseEmptyState() {
        let search = PlaceSearchService()
        #expect(search.resultsState == .empty)

        search.isLoadingSuggestions = true
        #expect(search.resultsState == .loading)

        search.isLoadingSuggestions = false
        search.errorMessage = "Suggestions failed"
        #expect(search.resultsState == .failed("Suggestions failed"))
    }

    @Test("ค้นหาเสร็จแล้วยังลากหมุดไปตำแหน่งใหม่ต่อได้")
    func searchedDestinationCanBeAdjustedOnMap() async {
        let searchedCoordinate = LocationCoordinate(latitude: 13.7367, longitude: 100.5604)
        let movedCoordinate = LocationCoordinate(latitude: 13.7390, longitude: 100.5630)
        let searchedDestination = destination("ผลจากการค้นหา", at: searchedCoordinate)
        let movedDestination = destination("ตำแหน่งหลังลากหมุด", at: movedCoordinate)
        let model = DestinationSelectionModel(
            candidate: .asok,
            resolver: ImmediateResolver(
                resolution: DestinationResolution(
                    destination: movedDestination,
                    isFallback: false
                )
            ),
            debounce: .zero
        )

        model.selectSearchDestination(searchedDestination)
        model.cameraDidMove(to: movedCoordinate)

        #expect(model.candidate == searchedDestination)
        #expect(model.latestCenter == movedCoordinate)
        #expect(model.mapPickerState == .moving)

        await model.cameraDidStop(at: movedCoordinate).value

        #expect(model.candidate == movedDestination)
    }

    @Test("กล้องที่เคลื่อนอัปเดตพิกัดล่าสุดโดยยังไม่เปลี่ยน candidate")
    func movingCameraKeepsCandidateUntilResolution() {
        let initial = Destination.asok
        let model = DestinationSelectionModel(
            candidate: initial,
            resolver: ImmediateResolver(),
            debounce: .zero
        )
        let center = LocationCoordinate(latitude: 13.73, longitude: 100.52)

        model.cameraDidMove(to: center)

        #expect(model.latestCenter == center)
        #expect(model.candidate == initial)
        #expect(model.mapPickerState == .moving)
    }

    @Test("ผล reverse geocode เก่าไม่เขียนทับตำแหน่งล่าสุด")
    func staleResolutionCannotOverwriteLatestCandidate() async {
        let resolver = ControlledResolver()
        let model = DestinationSelectionModel(
            candidate: .asok,
            resolver: resolver,
            debounce: .zero
        )
        let first = LocationCoordinate(latitude: 13.70, longitude: 100.50)
        let latest = LocationCoordinate(latitude: 13.80, longitude: 100.60)
        let firstDestination = destination("ผลเก่า", at: first)
        let latestDestination = destination("ผลล่าสุด", at: latest)

        let firstTask = model.cameraDidStop(at: first)
        await resolver.waitForRequestCount(1)

        model.cameraDidMove(to: latest)
        let latestTask = model.cameraDidStop(at: latest)
        await resolver.waitForRequestCount(2)

        resolver.finish(
            at: first,
            with: DestinationResolution(destination: firstDestination, isFallback: false)
        )
        await firstTask.value
        #expect(model.candidate == .asok)

        resolver.finish(
            at: latest,
            with: DestinationResolution(destination: latestDestination, isFallback: false)
        )
        await latestTask.value

        #expect(model.candidate == latestDestination)
        #expect(model.mapPickerState == .ready)
    }

    @Test("reverse geocode ที่หาชื่อไม่ได้ยังยืนยันพิกัด fallback ได้")
    func fallbackResolutionRemainsUsable() async {
        let coordinate = LocationCoordinate(latitude: 13.72, longitude: 100.53)
        let fallback = destination("จุดที่เลือกบนแผนที่", at: coordinate)
        let resolver = ImmediateResolver(
            resolution: DestinationResolution(destination: fallback, isFallback: true)
        )
        let model = DestinationSelectionModel(
            candidate: .asok,
            resolver: resolver,
            debounce: .zero
        )

        await model.cameraDidStop(at: coordinate).value

        #expect(model.candidate == fallback)
        #expect(model.latestCenter == coordinate)
    }

    private func destination(_ name: String, at coordinate: LocationCoordinate) -> Destination {
        Destination(
            id: name,
            name: name,
            detail: "ทดสอบ",
            coordinate: coordinate
        )
    }


    @Test("บันทึกและลบสถานที่โปรดใน TripStore")
    func saveAndRemoveFavorites() {
        let persistence = InMemoryTripPersistence()
        let store = TripStore(persistence: persistence)
        #expect(store.favorites.isEmpty)

        let coord = LocationCoordinate(latitude: 13.7563, longitude: 100.5018)
        let homeDest = Destination(id: "home", name: "บ้าน", detail: "กรุงเทพฯ", coordinate: coord)

        #expect(store.isFavorite(homeDest) == false)
        #expect(store.favorite(for: homeDest) == nil)

        store.saveFavorite(
            title: "บ้าน",
            subtitle: "กรุงเทพฯ",
            coordinate: coord,
            radiusMeters: 500,
            icon: .house
        )

        #expect(store.favorites.count == 1)
        #expect(store.isFavorite(homeDest) == true)
        #expect(store.favorite(for: homeDest)?.icon == .house)
        #expect(store.favorite(for: homeDest)?.radiusMeters == 500)
        #expect(persistence.favorites.count == 1)

        // Remove favorite
        store.removeFavorite(for: homeDest)
        #expect(store.favorites.isEmpty)
        #expect(store.isFavorite(homeDest) == false)
        #expect(persistence.favorites.isEmpty)
    }

    @Test("บันทึกประวัติการเดินทางล่าสุด เรียงจากล่าสุด และจำกัดไม่เกิน 10 รายการ")
    func recordRecentDestinationsOrderingAndLimit() {
        let persistence = InMemoryTripPersistence()
        let store = TripStore(persistence: persistence)
        #expect(store.recents.isEmpty)

        for i in 1...12 {
            let dest = Destination(
                id: "place-\(i)",
                name: "สถานที่ \(i)",
                detail: "รายละเอียด \(i)",
                coordinate: LocationCoordinate(latitude: Double(i), longitude: Double(i))
            )
            store.recordRecent(destination: dest, radiusMeters: 1_000)
        }

        #expect(store.recents.count == 10)
        #expect(store.recents.first?.title == "สถานที่ 12")
        #expect(store.recents.last?.title == "สถานที่ 3")

        // Clearing recents
        store.clearRecents()
        #expect(store.recents.isEmpty)
        #expect(persistence.recents.isEmpty)
    }

    @Test("เลือกจุดหมายจากที่บันทึกไว้จะอัปเดต Destination และ Radius ใน TripStore")
    func selectSavedDestinationUpdatesStore() {
        let persistence = InMemoryTripPersistence()
        let store = TripStore(persistence: persistence)
        let saved = SavedDestination(
            title: "ที่ทำงาน",
            subtitle: "ตึกสาทร",
            coordinate: LocationCoordinate(latitude: 13.72, longitude: 100.53),
            radiusMeters: 2_000,
            icon: .briefcase,
            isFavorite: true
        )

        store.selectSavedDestination(saved)

        #expect(store.destination.name == "ที่ทำงาน")
        #expect(store.selectedRadiusMeters == 2_000)
        #expect(store.recents.first?.title == "ที่ทำงาน")
    }

    @Test("อัปเดตและเปลี่ยนชื่อสถานที่โปรด (Custom Name & Edit Favorite)")
    func updateAndRenameFavorite() {
        let persistence = InMemoryTripPersistence()
        let store = TripStore(persistence: persistence)

        let coord = LocationCoordinate(latitude: 13.7563, longitude: 100.5018)
        store.saveFavorite(
            title: "ที่ทำงานเดิม",
            subtitle: "ตึก A",
            coordinate: coord,
            radiusMeters: 500,
            icon: .briefcase
        )

        guard let fav = store.favorites.first else {
            Issue.record("Favorite should exist")
            return
        }

        #expect(fav.title == "ที่ทำงานเดิม")
        #expect(fav.icon == .briefcase)
        #expect(fav.radiusMeters == 500)

        // Custom rename & update
        store.updateFavorite(
            id: fav.id,
            title: "ออฟฟิศใหม่",
            icon: .star,
            radiusMeters: 1_000
        )

        let updated = store.favorites.first
        #expect(updated?.title == "ออฟฟิศใหม่")
        #expect(updated?.icon == .star)
        #expect(updated?.radiusMeters == 1_000)
        #expect(persistence.favorites.first?.title == "ออฟฟิศใหม่")
    }

    @Test("ลบรายการประวัติล่าสุด (removeRecent) สำเร็จ")
    func removeRecentItem() {
        let persistence = InMemoryTripPersistence()
        let store = TripStore(persistence: persistence)
        let dest1 = Destination(id: "siam-paragon", name: "สยามพารากอน", detail: "ห้างสรรพสินค้า", coordinate: LocationCoordinate(latitude: 13.746, longitude: 100.534))
        let dest2 = Destination(id: "central-world", name: "เซ็นทรัลเวิลด์", detail: "ห้างสรรพสินค้า", coordinate: LocationCoordinate(latitude: 13.747, longitude: 100.539))

        store.recordRecent(destination: dest1, radiusMeters: 500)
        store.recordRecent(destination: dest2, radiusMeters: 1000)
        #expect(store.recents.count == 2)

        guard let itemToRemove = store.recents.first(where: { $0.title == "สยามพารากอน" }) else {
            Issue.record("Expected recent item")
            return
        }

        store.removeRecent(id: itemToRemove.id)
        #expect(store.recents.count == 1)
        #expect(store.recents.first?.title == "เซ็นทรัลเวิลด์")
        #expect(persistence.recents.count == 1)
    }

    @Test("เพิ่มรายการประวัติไปยังสถานที่โปรด (addRecentToFavorites) สำเร็จ")
    func addRecentToFavoritesSuccess() {
        let persistence = InMemoryTripPersistence()
        let store = TripStore(persistence: persistence)
        let dest = Destination(id: "iconsiam", name: "ไอคอนสยาม", detail: "ริมแม่น้ำเจ้าพระยา", coordinate: LocationCoordinate(latitude: 13.726, longitude: 100.510))

        store.recordRecent(destination: dest, radiusMeters: 1500)
        guard let recent = store.recents.first else {
            Issue.record("Expected recent item")
            return
        }

        #expect(store.favorites.isEmpty)
        store.addRecentToFavorites(recent)

        #expect(store.favorites.count == 1)
        let fav = store.favorites.first
        #expect(fav?.title == "ไอคอนสยาม")
        #expect(fav?.radiusMeters == 1500)
        #expect(fav?.isFavorite == true)
        #expect(persistence.favorites.count == 1)
    }

    @Test("destinationForConfirmation ใช้พิกัดล่าสุดเสมอเมื่อลากหมุด ไม่เด้งกลับไปพิกัดเดิม")
    func destinationForConfirmationKeepsLatestCenterWhenMoved() async {
        let initialCoord = LocationCoordinate(latitude: 13.746, longitude: 100.534)
        let initialDest = Destination(id: "siam-paragon", name: "สยามพารากอน", detail: "ห้าง", coordinate: initialCoord)
        let resolver = ControlledResolver()
        let model = DestinationSelectionModel(
            candidate: initialDest,
            resolver: resolver,
            debounce: .zero
        )

        // Before any movement, confirmation matches initial destination
        #expect(model.destinationForConfirmation().coordinate == initialCoord)
        #expect(model.destinationForConfirmation().name == "สยามพารากอน")

        // User starts dragging pin to a new coordinate
        let newCoord = LocationCoordinate(latitude: 13.800, longitude: 100.600)
        model.cameraDidMove(to: newCoord)

        // Confirmation immediately reflects newCoord (as fallback destination), never the old coordinate!
        let inFlightConfirm = model.destinationForConfirmation()
        #expect(inFlightConfirm.coordinate == newCoord)
        #expect(inFlightConfirm.name != "สยามพารากอน")

        // Map stops moving -> state becomes .resolving immediately
        let stopTask = model.cameraDidStop(at: newCoord)
        #expect(model.mapPickerState == .resolving)

        // Finish resolution
        let resolvedDest = Destination(id: "lat-phrao", name: "ห้าแยกลาดพร้าว", detail: "แยกลาดพร้าว", coordinate: newCoord)
        resolver.finish(at: newCoord, with: DestinationResolution(destination: resolvedDest, isFallback: false))
        await stopTask.value

        #expect(model.mapPickerState == .ready)
        let finalConfirm = model.destinationForConfirmation()
        #expect(finalConfirm.coordinate == newCoord)
        #expect(finalConfirm.name == "ห้าแยกลาดพร้าว")
    }

    @Test("LocationCoordinate distance calculation works accurately")
    func locationCoordinateDistanceCalculation() {
        let asok = LocationCoordinate(latitude: 13.7367, longitude: 100.5604)
        let phromPhong = LocationCoordinate(latitude: 13.7303, longitude: 100.5698)
        let dist = asok.distance(from: phromPhong)
        // Distance between Asok and Phrom Phong BTS is approximately 1.2-1.3 km
        #expect(dist > 1000 && dist < 1500)
        #expect(asok.distance(from: asok) == 0)
    }
}

@MainActor
final class InMemoryTripPersistence: TripPersisting {
    var snapshot: ActiveTripSnapshot?
    var preferences: UserAlertPreferences = .default
    var favorites: [SavedDestination] = []
    var recents: [SavedDestination] = []

    func loadActiveTrip() throws -> ActiveTripSnapshot? { snapshot }
    func saveActiveTrip(_ snapshot: ActiveTripSnapshot) throws { self.snapshot = snapshot }
    func clearActiveTrip() throws { snapshot = nil }
    func loadAlertPreferences() -> UserAlertPreferences { preferences }
    func saveAlertPreferences(_ preferences: UserAlertPreferences) { self.preferences = preferences }
    func loadFavorites() -> [SavedDestination] { favorites }
    func saveFavorites(_ favorites: [SavedDestination]) { self.favorites = favorites }
    func loadRecents() -> [SavedDestination] { recents }
    func saveRecents(_ recents: [SavedDestination]) { self.recents = recents }
}
@MainActor
private final class ImmediateResolver: MapCoordinateResolving {
    let resolution: DestinationResolution

    init(
        resolution: DestinationResolution = DestinationResolution(
            destination: .asok,
            isFallback: false
        )
    ) {
        self.resolution = resolution
    }

    func resolveDestination(at coordinate: LocationCoordinate) async -> DestinationResolution {
        resolution
    }
}

@MainActor
private final class ControlledResolver: MapCoordinateResolving {
    private var continuations: [LocationCoordinate: CheckedContinuation<DestinationResolution, Never>] = [:]
    private var requestWaiters: [(count: Int, continuation: CheckedContinuation<Void, Never>)] = []
    private(set) var requestCount = 0

    func resolveDestination(at coordinate: LocationCoordinate) async -> DestinationResolution {
        requestCount += 1
        let readyWaiters = requestWaiters.filter { $0.count <= requestCount }
        requestWaiters.removeAll { $0.count <= requestCount }
        readyWaiters.forEach { $0.continuation.resume() }
        return await withCheckedContinuation { continuation in
            continuations[coordinate] = continuation
        }
    }

    func waitForRequestCount(_ expectedCount: Int) async {
        guard requestCount < expectedCount else { return }
        await withCheckedContinuation { continuation in
            requestWaiters.append((expectedCount, continuation))
        }
    }

    func finish(at coordinate: LocationCoordinate, with resolution: DestinationResolution) {
        continuations.removeValue(forKey: coordinate)?.resume(returning: resolution)
    }

}
