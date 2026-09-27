import Foundation

@MainActor
protocol TripPersisting: AnyObject {
    func loadActiveTrip() throws -> ActiveTripSnapshot?
    func saveActiveTrip(_ snapshot: ActiveTripSnapshot) throws
    func clearActiveTrip() throws
    func loadAlertPreferences() -> UserAlertPreferences
    func saveAlertPreferences(_ preferences: UserAlertPreferences)
    func loadFavorites() -> [SavedDestination]
    func saveFavorites(_ favorites: [SavedDestination])
    func loadRecents() -> [SavedDestination]
    func saveRecents(_ recents: [SavedDestination])
}

extension TripPersisting {
    func loadAlertPreferences() -> UserAlertPreferences { .default }
    func saveAlertPreferences(_ preferences: UserAlertPreferences) {}
    func loadFavorites() -> [SavedDestination] { [] }
    func saveFavorites(_ favorites: [SavedDestination]) {}
    func loadRecents() -> [SavedDestination] { [] }
    func saveRecents(_ recents: [SavedDestination]) {}
}

@MainActor
final class UserDefaultsTripPersistence: TripPersisting {
    private let defaults: UserDefaults
    private let key: String
    private let preferencesKey: String
    private let favoritesKey: String
    private let recentsKey: String

    init(
        defaults: UserDefaults = .standard,
        key: String = "napnav.active-trip.v1",
        preferencesKey: String = "napnav.alert-preferences.v1",
        favoritesKey: String = "napnav.favorites.v1",
        recentsKey: String = "napnav.recents.v1"
    ) {
        self.defaults = defaults
        self.key = key
        self.preferencesKey = preferencesKey
        self.favoritesKey = favoritesKey
        self.recentsKey = recentsKey
    }

    func loadActiveTrip() throws -> ActiveTripSnapshot? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try JSONDecoder().decode(ActiveTripSnapshot.self, from: data)
    }

    func saveActiveTrip(_ snapshot: ActiveTripSnapshot) throws {
        let data = try JSONEncoder().encode(snapshot)
        defaults.set(data, forKey: key)
    }

    func clearActiveTrip() throws {
        defaults.removeObject(forKey: key)
    }

    func loadAlertPreferences() -> UserAlertPreferences {
        guard let data = defaults.data(forKey: preferencesKey),
              let preferences = try? JSONDecoder().decode(UserAlertPreferences.self, from: data) else {
            return .default
        }
        return preferences
    }

    func saveAlertPreferences(_ preferences: UserAlertPreferences) {
        guard let data = try? JSONEncoder().encode(preferences) else { return }
        defaults.set(data, forKey: preferencesKey)
    }

    func loadFavorites() -> [SavedDestination] {
        guard let data = defaults.data(forKey: favoritesKey),
              let list = try? JSONDecoder().decode([SavedDestination].self, from: data) else {
            return []
        }
        return list
    }

    func saveFavorites(_ favorites: [SavedDestination]) {
        guard let data = try? JSONEncoder().encode(favorites) else { return }
        defaults.set(data, forKey: favoritesKey)
    }

    func loadRecents() -> [SavedDestination] {
        guard let data = defaults.data(forKey: recentsKey),
              let list = try? JSONDecoder().decode([SavedDestination].self, from: data) else {
            return []
        }
        return list
    }

    func saveRecents(_ recents: [SavedDestination]) {
        guard let data = try? JSONEncoder().encode(recents) else { return }
        defaults.set(data, forKey: recentsKey)
    }
}


@MainActor
final class NoopTripPersistence: TripPersisting {
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
