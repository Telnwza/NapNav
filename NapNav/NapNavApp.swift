import Foundation
import SwiftUI
import UserNotifications

@main
struct NapNavApp: App {
    @State private var store: TripStore
    @AppStorage(AppLocalization.preferenceKey) private var appLanguageRawValue = AppLanguage.system.rawValue

    private var appLanguage: AppLanguage {
        AppLanguage(rawValue: appLanguageRawValue) ?? .system
    }

    init() {
        let store = TripStore(
            persistence: UserDefaultsTripPersistence(),
            liveActivityManager: LiveActivityClient()
        )
        _store = State(
            initialValue: store
        )
        LocalAlarmDelivery.registerCategories()
        UNUserNotificationCenter.current().delegate = NotificationDelegate.shared
        NotificationDelegate.shared.onTripAction = { [weak store] identifier, tripID in
            store?.handleNotificationAction(identifier, tripID: tripID)
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView(store: store)
                .tint(AppTheme.primary)
                .id(appLanguageRawValue)
                .environment(\.locale, appLanguage.locale)
        }
    }
}

enum NapNavDeepLink: Equatable {
    case trip
    case requestStopConfirmation
    case quickAction
    case stopAlarm
    case startHome

    static func route(for url: URL) -> Self? {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              components.scheme?.lowercased() == "napnav",
              components.user == nil,
              components.password == nil,
              components.port == nil,
              components.percentEncodedPath.isEmpty,
              components.percentEncodedQuery == nil,
              components.percentEncodedFragment == nil else { return nil }

        switch components.host?.lowercased() {
        case "trip": return .trip
        case "stop-trip": return .requestStopConfirmation
        case "quick-action": return .quickAction
        case "stop-alarm": return .stopAlarm
        case "start-home": return .startHome
        default: return nil
        }
    }

    @MainActor
    static func stopConfirmationRequest(
        for url: URL,
        store: TripStore
    ) -> TripStopConfirmationRequest? {
        guard route(for: url) == .requestStopConfirmation else { return nil }
        return store.makeStopConfirmationRequest()
    }
}
