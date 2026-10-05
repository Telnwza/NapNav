@preconcurrency import CoreLocation
import Foundation
@preconcurrency import UserNotifications
#if canImport(AlarmKit)
import AlarmKit
import SwiftUI
#endif
#if canImport(ActivityKit)
import ActivityKit
#endif

@MainActor
protocol LocationProviding: AnyObject {
    func requestWhenInUseAuthorization()
    func startUpdates() -> AsyncStream<LocationEvent>
    func stopUpdates()
}

@MainActor
final class LiveLocationClient: LocationProviding {
    private let authorizationManager = CLLocationManager()
    private var serviceSession: CLServiceSession?
    private var backgroundSession: CLBackgroundActivitySession?
    private var continuation: AsyncStream<LocationEvent>.Continuation?
    private var updateTask: Task<Void, Never>?
    private var activeSessionID: UUID?

    func requestWhenInUseAuthorization() {
        authorizationManager.requestWhenInUseAuthorization()
    }

    func startUpdates() -> AsyncStream<LocationEvent> {
        stopUpdates()

        let sessionID = UUID()
        activeSessionID = sessionID
        serviceSession = CLServiceSession(authorization: .whenInUse)
        backgroundSession = CLBackgroundActivitySession()

        return AsyncStream { continuation in
            self.continuation = continuation
            continuation.onTermination = { @Sendable [weak self] _ in
                Task { @MainActor in
                    self?.stopUpdates(sessionID: sessionID)
                }
            }

            self.updateTask = Task { [weak self] in
                guard let self else { return }

                do {
                    for try await update in CLLocationUpdate.liveUpdates(.otherNavigation) {
                        guard Task.isCancelled == false else { break }

                        if update.authorizationDeniedGlobally {
                            self.continuation?.yield(.servicesDisabled)
                            break
                        }
                        if update.authorizationDenied {
                            self.continuation?.yield(.authorizationDenied)
                            break
                        }
                        if update.accuracyLimited {
                            self.continuation?.yield(.accuracyLimited)
                        }
                        if update.locationUnavailable {
                            self.continuation?.yield(.unavailable)
                            continue
                        }
                        guard let location = update.location else { continue }

                        let sample = LocationSample(
                            coordinate: LocationCoordinate(
                                latitude: location.coordinate.latitude,
                                longitude: location.coordinate.longitude
                            ),
                            horizontalAccuracy: location.horizontalAccuracy,
                            timestamp: location.timestamp,
                            speed: location.speed >= 0 ? location.speed : nil,
                            course: location.course >= 0 ? location.course : nil
                        )
                        self.continuation?.yield(.sample(sample))
                    }
                } catch is CancellationError {
                    // Expected when the user stops the trip.
                } catch {
                    self.continuation?.yield(.failed(error.localizedDescription))
                }

                self.stopUpdates(sessionID: sessionID)
            }
        }
    }

    func stopUpdates() {
        stopUpdates(sessionID: nil)
    }

    private func stopUpdates(sessionID: UUID?) {
        if let sessionID, activeSessionID != sessionID {
            return
        }
        activeSessionID = nil
        updateTask?.cancel()
        updateTask = nil
        finishStream()
        backgroundSession?.invalidate()
        backgroundSession = nil
        serviceSession = nil
    }

    private func finishStream() {
        let activeContinuation = continuation
        continuation = nil
        activeContinuation?.finish()
    }
}

@MainActor
protocol AlarmDelivering: AnyObject {
    func authorizationIsGranted() async -> Bool
    func requestAuthorizationIfNeeded() async -> Bool
    func prominentAlarmsAreSupported() -> Bool
    func prominentAlarmAuthorizationIsGranted() async -> Bool
    func requestProminentAlarmAuthorizationIfAvailable() async -> Bool
    func readiness() async -> AlarmReadiness
    func deliveryCapabilities() async -> AlertDeliveryCapabilities
    func deliveryCapabilities(readiness: AlarmReadiness) async -> AlertDeliveryCapabilities
    func sendArrivalAlert(destination: Destination, distanceMeters: Double) async throws
    func sendArrivalAlert(
        destination: Destination,
        distanceMeters: Double,
        preferences: UserAlertPreferences
    ) async -> AlertDeliveryResult
    func sendArrivalAlert(
        tripID: UUID?,
        destination: Destination,
        distanceMeters: Double,
        preferences: UserAlertPreferences
    ) async -> AlertDeliveryResult
    func sendArrivalAlert(
        tripID: UUID?,
        destination: Destination,
        distanceMeters: Double,
        preferences: UserAlertPreferences,
        capabilities: AlertDeliveryCapabilities?
    ) async -> AlertDeliveryResult
    func scheduleSnoozeAlert(destination: Destination, after delay: TimeInterval) async throws
    func scheduleSnoozeAlert(tripID: UUID?, destination: Destination, after delay: TimeInterval) async throws
    func sendTestAlert() async throws
    func sendTestAlert(after delay: TimeInterval) async throws
    func sendProminentAlarmSpike(destination: Destination, after delay: TimeInterval) async throws
    func currentProminentAlarmIdentifier() -> UUID?
    func prominentAlarmIdentifier(forTripID tripID: UUID) -> UUID?
    func prominentAlarmExists(identifier: UUID) -> Bool
    func cancelTripAlerts(
        destinationID: String,
        tripID: UUID?,
        prominentAlarmIdentifier: UUID?
    ) -> AlertCancellationResult
    func reconcilePendingTripAlertCancellations() -> AlertCancellationResult
    func cancelAllTripAlerts() async -> AlertCancellationResult
}

typealias NotificationProviding = AlarmDelivering

extension AlarmDelivering {
    func readiness() async -> AlarmReadiness {
        let granted = await authorizationIsGranted()
        return AlarmReadiness(
            permission: granted ? .authorized : .unknown,
            alertsEnabled: granted,
            soundsEnabled: granted,
            lockScreenEnabled: granted,
            timeSensitiveSetting: .unknown
        )
    }

    func deliveryCapabilities() async -> AlertDeliveryCapabilities {
        let notificationReadiness = await readiness()
        return await deliveryCapabilities(readiness: notificationReadiness)
    }

    func deliveryCapabilities(readiness: AlarmReadiness) async -> AlertDeliveryCapabilities {
        AlertDeliveryCapabilities(
            notificationReady: readiness.canDeliverVisibleAlert,
            notificationSoundsEnabled: readiness.soundsEnabled,
            alarmKitSupported: prominentAlarmsAreSupported(),
            alarmKitAuthorized: await prominentAlarmAuthorizationIsGranted()
        )
    }

    func sendArrivalAlert(
        destination: Destination,
        distanceMeters: Double,
        preferences: UserAlertPreferences
    ) async -> AlertDeliveryResult {
        do {
            try await sendArrivalAlert(destination: destination, distanceMeters: distanceMeters)
            let readiness = await readiness()
            let sound = AlertDeliveryPolicy.notificationSoundBehavior(
                for: preferences.soundMode,
                soundsEnabled: readiness.soundsEnabled
            )
            return .notificationScheduled(sound: sound)
        } catch {
            return .deliveryUnavailable(reason: .notificationSchedulingFailed)
        }
    }

    func sendArrivalAlert(
        tripID: UUID?,
        destination: Destination,
        distanceMeters: Double,
        preferences: UserAlertPreferences
    ) async -> AlertDeliveryResult {
        await sendArrivalAlert(
            destination: destination,
            distanceMeters: distanceMeters,
            preferences: preferences
        )
    }

    func sendArrivalAlert(
        tripID: UUID?,
        destination: Destination,
        distanceMeters: Double,
        preferences: UserAlertPreferences,
        capabilities: AlertDeliveryCapabilities?
    ) async -> AlertDeliveryResult {
        await sendArrivalAlert(
            tripID: tripID,
            destination: destination,
            distanceMeters: distanceMeters,
            preferences: preferences
        )
    }

    func sendTestAlert() async throws {
        try await sendTestAlert(after: 0)
    }

    func sendTestAlert(after delay: TimeInterval) async throws {
        try await sendTestAlert()
    }

    func prominentAlarmsAreSupported() -> Bool { false }
    func prominentAlarmAuthorizationIsGranted() async -> Bool { false }
    func requestProminentAlarmAuthorizationIfAvailable() async -> Bool { false }
    func scheduleSnoozeAlert(destination: Destination, after delay: TimeInterval) async throws {}
    func scheduleSnoozeAlert(
        tripID: UUID?,
        destination: Destination,
        after delay: TimeInterval
    ) async throws {
        try await scheduleSnoozeAlert(destination: destination, after: delay)
    }
    func sendProminentAlarmSpike(destination: Destination, after delay: TimeInterval) async throws {
        throw AlarmDeliveryError.prominentAlarmUnavailable
    }
    func currentProminentAlarmIdentifier() -> UUID? { nil }
    func prominentAlarmIdentifier(forTripID tripID: UUID) -> UUID? {
        currentProminentAlarmIdentifier()
    }
    func prominentAlarmExists(identifier: UUID) -> Bool { false }
}

enum AlarmDeliveryError: Error {
    case prominentAlarmUnavailable
    case prominentAlarmDenied
    case prominentAlarmCancellationFailed
    case deliveryUnavailable(AlertDeliveryUnavailableReason)
}

@MainActor
protocol ProminentAlarmControlling: AnyObject {
    var isSupported: Bool { get }
    func alarmIdentifiers() throws -> Set<UUID>
    func cancelAlarm(identifier: UUID) throws
}

@MainActor
private final class SystemProminentAlarmController: ProminentAlarmControlling {
    var isSupported: Bool {
#if canImport(AlarmKit)
        if #available(iOS 26.0, *) { return true }
#endif
        return false
    }

    func alarmIdentifiers() throws -> Set<UUID> {
#if canImport(AlarmKit)
        guard #available(iOS 26.0, *) else { throw AlarmDeliveryError.prominentAlarmUnavailable }
        return Set(try AlarmManager.shared.alarms.map(\.id))
#else
        throw AlarmDeliveryError.prominentAlarmUnavailable
#endif
    }

    func cancelAlarm(identifier: UUID) throws {
#if canImport(AlarmKit)
        guard #available(iOS 26.0, *) else { throw AlarmDeliveryError.prominentAlarmUnavailable }
        try AlarmManager.shared.cancel(id: identifier)
#else
        throw AlarmDeliveryError.prominentAlarmUnavailable
#endif
    }
}

@MainActor
final class LocalAlarmDelivery: AlarmDelivering {
    static let tripCategoryIdentifier = "NAPNAV_TRIP_ALARM"
    static let stopActionIdentifier = "NAPNAV_STOP_TRIP"
    static let snoozeActionIdentifier = "NAPNAV_SNOOZE_TRIP"

    private static let pendingAlarmCancellationsKey = "napnav.pending-alarm-cancellations.v1"
    private static let fullAlarmReconciliationRequiredKey = "napnav.full-alarm-reconciliation-required.v1"
    private let center: UNUserNotificationCenter
    private let defaults: UserDefaults
    private let pendingAlarmCancellationsKey: String
    private let fullAlarmReconciliationRequiredKey: String
    private let alarmController: any ProminentAlarmControlling
    private var prominentAlarmID: UUID?
    private var pendingAlarmCancellationIDs: Set<UUID>
    private var fullAlarmReconciliationRequired: Bool

    init(
        center: UNUserNotificationCenter = .current(),
        defaults: UserDefaults = .standard,
        pendingAlarmCancellationsKey: String = LocalAlarmDelivery.pendingAlarmCancellationsKey,
        fullAlarmReconciliationRequiredKey: String = LocalAlarmDelivery.fullAlarmReconciliationRequiredKey,
        alarmController: any ProminentAlarmControlling = SystemProminentAlarmController()
    ) {
        self.center = center
        self.defaults = defaults
        self.pendingAlarmCancellationsKey = pendingAlarmCancellationsKey
        self.fullAlarmReconciliationRequiredKey = fullAlarmReconciliationRequiredKey
        self.alarmController = alarmController
        self.pendingAlarmCancellationIDs = Set(
            (defaults.stringArray(forKey: pendingAlarmCancellationsKey) ?? [])
                .compactMap(UUID.init(uuidString:))
        )
        self.fullAlarmReconciliationRequired = defaults.bool(forKey: fullAlarmReconciliationRequiredKey)
    }

    var pendingAlarmCancellationIdentifiers: Set<UUID> {
        pendingAlarmCancellationIDs
    }

    static func notificationCategory(language: AppLanguage) -> UNNotificationCategory {
        let stop = UNNotificationAction(
            identifier: stopActionIdentifier,
            title: AppLocalization.string("หยุดทริป", language: language),
            options: [.destructive]
        )
        let snooze = UNNotificationAction(
            identifier: snoozeActionIdentifier,
            title: AppLocalization.string("เตือนอีกครั้งใน 5 นาที", language: language),
            options: []
        )
        return UNNotificationCategory(
            identifier: tripCategoryIdentifier,
            actions: [snooze, stop],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )
    }

    static func registerCategories(language: AppLanguage = AppLocalization.selectedLanguage) {
        UNUserNotificationCenter.current().setNotificationCategories([
            notificationCategory(language: language)
        ])
    }

    static func timeSensitiveSetting(from setting: UNNotificationSetting) -> NotificationSettingState {
        switch setting {
        case .enabled: .enabled
        case .disabled: .disabled
        case .notSupported: .notSupported
        @unknown default: .unknown
        }
    }

    func authorizationIsGranted() async -> Bool {
        await readiness().canDeliverVisibleAlert
    }

    func requestAuthorizationIfNeeded() async -> Bool {
        let settings = await center.notificationSettings()

        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            return await readiness().canDeliverVisibleAlert
        case .notDetermined:
            do {
                _ = try await center.requestAuthorization(options: [.alert, .sound, .badge])
                return await readiness().canDeliverVisibleAlert
            } catch {
                return false
            }
        case .denied:
            return false
        @unknown default:
            return false
        }
    }

    func readiness() async -> AlarmReadiness {
        let settings = await center.notificationSettings()
        let permission: NotificationPermissionState

        switch settings.authorizationStatus {
        case .notDetermined:
            permission = .notDetermined
        case .denied:
            permission = .denied
        case .authorized, .provisional, .ephemeral:
            permission = .authorized
        @unknown default:
            permission = .unknown
        }

        return AlarmReadiness(
            permission: permission,
            alertsEnabled: settings.alertSetting == .enabled,
            soundsEnabled: settings.soundSetting == .enabled,
            lockScreenEnabled: settings.lockScreenSetting == .enabled,
            timeSensitiveSetting: Self.timeSensitiveSetting(from: settings.timeSensitiveSetting)
        )
    }

    func prominentAlarmAuthorizationIsGranted() async -> Bool {
#if canImport(AlarmKit)
        guard #available(iOS 26.0, *) else { return false }
        return AlarmManager.shared.authorizationState == .authorized
#else
        return false
#endif
    }

    func prominentAlarmsAreSupported() -> Bool {
        alarmController.isSupported
    }

    func deliveryCapabilities() async -> AlertDeliveryCapabilities {
        let notificationReadiness = await readiness()
        return AlertDeliveryCapabilities(
            notificationReady: notificationReadiness.canDeliverVisibleAlert,
            notificationSoundsEnabled: notificationReadiness.soundsEnabled,
            alarmKitSupported: prominentAlarmsAreSupported(),
            alarmKitAuthorized: await prominentAlarmAuthorizationIsGranted()
        )
    }

    func requestProminentAlarmAuthorizationIfAvailable() async -> Bool {
#if canImport(AlarmKit)
        guard #available(iOS 26.0, *) else { return false }

        switch AlarmManager.shared.authorizationState {
        case .authorized:
            return true
        case .denied:
            return false
        case .notDetermined:
            do {
                return try await AlarmManager.shared.requestAuthorization() == .authorized
            } catch {
                return false
            }
        @unknown default:
            return false
        }
#else
        return false
#endif
    }

    func sendArrivalAlert(destination: Destination, distanceMeters: Double) async throws {
        let result = await sendArrivalAlert(
            destination: destination,
            distanceMeters: distanceMeters,
            preferences: .default
        )
        if case .deliveryUnavailable(let reason) = result {
            throw AlarmDeliveryError.deliveryUnavailable(reason)
        }
    }

    func sendArrivalAlert(
        destination: Destination,
        distanceMeters: Double,
        preferences: UserAlertPreferences
    ) async -> AlertDeliveryResult {
        await sendArrivalAlert(
            tripID: nil,
            destination: destination,
            distanceMeters: distanceMeters,
            preferences: preferences
        )
    }

    func sendArrivalAlert(
        tripID: UUID?,
        destination: Destination,
        distanceMeters: Double,
        preferences: UserAlertPreferences
    ) async -> AlertDeliveryResult {
        await sendArrivalAlert(
            tripID: tripID,
            destination: destination,
            distanceMeters: distanceMeters,
            preferences: preferences,
            capabilities: nil
        )
    }

    func sendArrivalAlert(
        tripID: UUID?,
        destination: Destination,
        distanceMeters: Double,
        preferences: UserAlertPreferences,
        capabilities: AlertDeliveryCapabilities?
    ) async -> AlertDeliveryResult {
        let capabilities = if let capabilities {
            capabilities
        } else {
            await deliveryCapabilities()
        }
        let plan = AlertDeliveryPolicy.plan(
            preferences: preferences,
            capabilities: capabilities
        )

        guard plan.isAvailable else {
            return .deliveryUnavailable(reason: plan.unavailableReason ?? .noAvailablePath)
        }

        let wantsAlarmKit = plan.paths.contains(.alarmKit)
        let notificationPath = plan.paths.first { path in
            if case .notification = path { return true }
            return false
        }

        if wantsAlarmKit {
#if canImport(AlarmKit)
            if #available(iOS 26.0, *) {
                do {
                    try await scheduleProminentAlarm(
                        destination: destination,
                        after: 1,
                        identifier: tripID
                    )

                    if case .notification(let sound)? = notificationPath {
                        do {
                            try await sendStandardNotification(
                                destination: destination,
                                distanceMeters: distanceMeters,
                                sound: sound,
                                tripID: tripID
                            )
                            return .alarmScheduled(companionNotificationScheduled: true)
                        } catch {
                            return .alarmScheduled(companionNotificationScheduled: false)
                        }
                    }

                    if let fallbackReason = plan.fallbackReason {
                        return .fallbackUsed(
                            from: preferences.deliveryMode,
                            to: .alarmKit,
                            reason: fallbackReason
                        )
                    }
                    return .alarmScheduled(companionNotificationScheduled: false)
                } catch {
                    return await fallbackAfterAlarmFailure(
                        destination: destination,
                        distanceMeters: distanceMeters,
                        preferences: preferences,
                        capabilities: capabilities,
                        tripID: tripID
                    )
                }
            }
#endif
            return await fallbackAfterAlarmFailure(
                destination: destination,
                distanceMeters: distanceMeters,
                preferences: preferences,
                capabilities: capabilities,
                tripID: tripID
            )
        }

        guard case .notification(let sound)? = notificationPath else {
            return .deliveryUnavailable(reason: plan.unavailableReason ?? .noAvailablePath)
        }

        do {
            try await sendStandardNotification(
                destination: destination,
                distanceMeters: distanceMeters,
                sound: sound,
                tripID: tripID
            )
            if let fallbackReason = plan.fallbackReason {
                return .fallbackUsed(
                    from: preferences.deliveryMode,
                    to: .notification(sound: sound),
                    reason: fallbackReason
                )
            }
            return .notificationScheduled(sound: sound)
        } catch {
            return .deliveryUnavailable(reason: .notificationSchedulingFailed)
        }
    }

    private func fallbackAfterAlarmFailure(
        destination: Destination,
        distanceMeters: Double,
        preferences: UserAlertPreferences,
        capabilities: AlertDeliveryCapabilities,
        tripID: UUID?
    ) async -> AlertDeliveryResult {
        guard capabilities.notificationReady else {
            return .deliveryUnavailable(reason: .alarmSchedulingFailed)
        }

        let sound = AlertDeliveryPolicy.notificationSoundBehavior(
            for: preferences.soundMode,
            soundsEnabled: capabilities.notificationSoundsEnabled
        )
        do {
            try await sendStandardNotification(
                destination: destination,
                distanceMeters: distanceMeters,
                sound: sound,
                tripID: tripID
            )
            return .fallbackUsed(
                from: preferences.deliveryMode,
                to: .notification(sound: sound),
                reason: .alarmSchedulingFailed
            )
        } catch {
            return .deliveryUnavailable(reason: .notificationSchedulingFailed)
        }
    }

    private func sendStandardNotification(
        destination: Destination,
        distanceMeters: Double,
        sound: NotificationSoundBehavior = .audible,
        tripID: UUID? = nil
    ) async throws {
        let content = UNMutableNotificationContent()
        content.title = AppLocalization.format("ใกล้ถึง%@แล้ว", destination.name)
        content.body = AppLocalization.format(
            "เหลือระยะประมาณ %@ เตรียมตัวลงได้เลย",
            formattedDistance(distanceMeters)
        )
        if sound.includesSound {
            content.sound = .default
        } else {
            content.sound = nil
        }
        content.interruptionLevel = .timeSensitive
        content.categoryIdentifier = Self.tripCategoryIdentifier
        content.threadIdentifier = "stop-alarm-trip"
        var userInfo: [AnyHashable: Any] = ["destinationID": destination.id]
        if let tripID {
            userInfo["tripID"] = tripID.uuidString
        }
        content.userInfo = userInfo

        let request = UNNotificationRequest(
            identifier: tripID.map { "arrival-\($0.uuidString)" } ?? "arrival-\(destination.id)",
            content: content,
            trigger: nil
        )
        try await center.add(request)
    }

    func scheduleSnoozeAlert(destination: Destination, after delay: TimeInterval) async throws {
        try await scheduleSnoozeAlert(tripID: nil, destination: destination, after: delay)
    }

    func scheduleSnoozeAlert(
        tripID: UUID?,
        destination: Destination,
        after delay: TimeInterval
    ) async throws {
        let content = UNMutableNotificationContent()
        content.title = AppLocalization.string("NapNav เตือนอีกครั้ง")
        content.body = AppLocalization.format("ตรวจระยะที่เหลือถึง %@", destination.name)
        content.sound = .default
        content.interruptionLevel = .timeSensitive
        content.categoryIdentifier = Self.tripCategoryIdentifier
        content.threadIdentifier = "stop-alarm-trip"
        var userInfo: [AnyHashable: Any] = ["destinationID": destination.id]
        if let tripID {
            userInfo["tripID"] = tripID.uuidString
        }
        content.userInfo = userInfo

        let request = UNNotificationRequest(
            identifier: tripID.map { "snooze-\($0.uuidString)" } ?? "snooze-\(destination.id)",
            content: content,
            trigger: UNTimeIntervalNotificationTrigger(
                timeInterval: max(delay, 1),
                repeats: false
            )
        )
        try await center.add(request)
    }

    func sendTestAlert() async throws {
        try await sendTestAlert(after: 0)
    }

    func sendTestAlert(after delay: TimeInterval) async throws {
        let content = UNMutableNotificationContent()
        content.title = AppLocalization.string("ทดสอบ NapNav")
        content.body = delay > 0
            ? AppLocalization.format(
                "ทดสอบการแจ้งเตือนแบบหน่วงเวลา (%d วินาที)",
                Int(delay)
            )
            : AppLocalization.string("ได้รับการแจ้งเตือนทดสอบแล้ว")
        content.sound = .default
        content.interruptionLevel = .timeSensitive

        let trigger: UNNotificationTrigger? = delay > 0
            ? UNTimeIntervalNotificationTrigger(timeInterval: max(delay, 1), repeats: false)
            : nil

        let request = UNNotificationRequest(
            identifier: "stop-alarm-test-\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )
        try await center.add(request)
    }

    func sendProminentAlarmSpike(destination: Destination, after delay: TimeInterval) async throws {
#if canImport(AlarmKit)
        guard #available(iOS 26.0, *) else {
            throw AlarmDeliveryError.prominentAlarmUnavailable
        }

        let authorization = try await AlarmManager.shared.requestAuthorization()
        guard authorization == .authorized else {
            throw AlarmDeliveryError.prominentAlarmDenied
        }

        try await scheduleProminentAlarm(destination: destination, after: delay)
#else
        throw AlarmDeliveryError.prominentAlarmUnavailable
#endif
    }

    func currentProminentAlarmIdentifier() -> UUID? {
        prominentAlarmID
    }

    func prominentAlarmIdentifier(forTripID tripID: UUID) -> UUID? {
        tripID
    }

    func prominentAlarmExists(identifier: UUID) -> Bool {
        guard alarmController.isSupported else { return false }
        return (try? alarmController.alarmIdentifiers().contains(identifier)) ?? false
    }

    func cancelTripAlerts(
        destinationID: String,
        tripID: UUID?,
        prominentAlarmIdentifier: UUID?
    ) -> AlertCancellationResult {
        let identifiers = tripID.map {
            [
                "arrival-\($0.uuidString)",
                "snooze-\($0.uuidString)",
                "arrival-\(destinationID)",
                "snooze-\(destinationID)"
            ]
        } ?? ["arrival-\(destinationID)", "snooze-\(destinationID)"]
        center.removePendingNotificationRequests(withIdentifiers: identifiers)
        center.removeDeliveredNotifications(withIdentifiers: identifiers)

        let alarmID = prominentAlarmIdentifier
            ?? prominentAlarmID
            ?? (alarmController.isSupported ? tripID : nil)
        let outcomes = alarmID.map { [cancelProminentAlarm(identifier: $0)] } ?? []
        return AlertCancellationResult(
            notificationCleanup: .requestsRemoved,
            alarmKitOutcomes: outcomes
        )
    }

    func reconcilePendingTripAlertCancellations() -> AlertCancellationResult {
        var enumerationFailure: String?
        var enumerationCompleted = false
        if fullAlarmReconciliationRequired {
            if alarmController.isSupported {
                do {
                    pendingAlarmCancellationIDs.formUnion(try alarmController.alarmIdentifiers())
                    persistPendingAlarmCancellations()
                    setFullAlarmReconciliationRequired(false)
                    enumerationCompleted = true
                } catch {
                    enumerationFailure = String(describing: error)
                }
            } else {
                enumerationFailure = String(describing: AlarmDeliveryError.prominentAlarmUnavailable)
            }
        }

        let outcomes = pendingAlarmCancellationIDs
            .sorted { $0.uuidString < $1.uuidString }
            .map { cancelProminentAlarm(identifier: $0) }
        return AlertCancellationResult(
            alarmKitOutcomes: outcomes,
            alarmKitEnumerationFailure: enumerationFailure,
            alarmKitEnumerationCompleted: enumerationCompleted
        )
    }

    func cancelAllTripAlerts() async -> AlertCancellationResult {
        let pending = await center.pendingNotificationRequests()
        let delivered = await center.deliveredNotifications()
        let pendingIdentifiers = pending.compactMap { request in
            request.content.categoryIdentifier == Self.tripCategoryIdentifier
                ? request.identifier
                : nil
        }
        let deliveredIdentifiers = delivered.compactMap { notification in
            notification.request.content.categoryIdentifier == Self.tripCategoryIdentifier
                ? notification.request.identifier
                : nil
        }
        let identifiers = Set(pendingIdentifiers + deliveredIdentifiers)
        center.removePendingNotificationRequests(withIdentifiers: Array(identifiers))
        center.removeDeliveredNotifications(withIdentifiers: Array(identifiers))

        var outcomes: [AlarmKitCancellationOutcome] = []
        var enumerationFailure: String?
        var enumerationCompleted = false
        if alarmController.isSupported {
            do {
                let systemAlarmIDs = try alarmController.alarmIdentifiers()
                pendingAlarmCancellationIDs.formUnion(systemAlarmIDs)
                persistPendingAlarmCancellations()
                setFullAlarmReconciliationRequired(false)
                enumerationCompleted = true
                let alarmIDs = systemAlarmIDs.union(pendingAlarmCancellationIDs)
                for alarmID in alarmIDs.sorted(by: { $0.uuidString < $1.uuidString }) {
                    outcomes.append(cancelProminentAlarm(identifier: alarmID))
                }
            } catch {
                enumerationFailure = String(describing: error)
                setFullAlarmReconciliationRequired(true)
                outcomes.append(contentsOf: pendingAlarmCancellationIDs.map {
                    .failed($0, reason: String(describing: error))
                })
            }
        } else {
            outcomes = pendingAlarmCancellationIDs.map { .unsupported($0) }
            if fullAlarmReconciliationRequired {
                enumerationFailure = String(describing: AlarmDeliveryError.prominentAlarmUnavailable)
            }
        }

        return AlertCancellationResult(
            notificationCleanup: .requestsRemoved,
            alarmKitOutcomes: outcomes,
            alarmKitEnumerationFailure: enumerationFailure,
            alarmKitEnumerationCompleted: enumerationCompleted
        )
    }

    private func cancelProminentAlarm(identifier: UUID) -> AlarmKitCancellationOutcome {
        pendingAlarmCancellationIDs.insert(identifier)
        persistPendingAlarmCancellations()

        guard alarmController.isSupported else {
            return .unsupported(identifier)
        }

        do {
            let existingIDs = try alarmController.alarmIdentifiers()
            guard existingIDs.contains(identifier) else {
                resolvePendingAlarmCancellation(identifier)
                return .alreadyAbsent(identifier)
            }

            try alarmController.cancelAlarm(identifier: identifier)
            resolvePendingAlarmCancellation(identifier)
            return .cancelled(identifier)
        } catch {
            return .failed(identifier, reason: String(describing: error))
        }
    }

    private func resolvePendingAlarmCancellation(_ identifier: UUID) {
        pendingAlarmCancellationIDs.remove(identifier)
        persistPendingAlarmCancellations()
        if prominentAlarmID == identifier {
            prominentAlarmID = nil
        }
    }

    private func persistPendingAlarmCancellations() {
        defaults.set(
            pendingAlarmCancellationIDs.map(\.uuidString).sorted(),
            forKey: pendingAlarmCancellationsKey
        )
    }

    private func setFullAlarmReconciliationRequired(_ isRequired: Bool) {
        fullAlarmReconciliationRequired = isRequired
        defaults.set(isRequired, forKey: fullAlarmReconciliationRequiredKey)
    }

    private func formattedDistance(_ meters: Double) -> String {
        if meters < 1_000 {
            return AppLocalization.format("%d เมตร", Int(meters.rounded()))
        }
        return AppLocalization.format("%.1f กิโลเมตร", meters / 1_000)
    }

#if canImport(AlarmKit)
    @available(iOS 26.0, *)
    private func scheduleProminentAlarm(
        destination: Destination,
        after delay: TimeInterval,
        identifier: UUID? = nil
    ) async throws {
        if identifier == nil, let prominentAlarmID {
            let outcome = cancelProminentAlarm(identifier: prominentAlarmID)
            guard outcome.isResolved else {
                throw AlarmDeliveryError.prominentAlarmCancellationFailed
            }
        }

        let alert: AlarmPresentation.Alert
        if #available(iOS 26.1, *) {
            alert = AlarmPresentation.Alert(
                title: LocalizedStringResource(
                    "NapNav ใกล้ถึงจุดหมาย",
                    locale: AppLocalization.locale
                )
            )
        } else {
            let stopButton = AlarmButton(
                text: LocalizedStringResource("หยุด", locale: AppLocalization.locale),
                textColor: .white,
                systemImageName: "stop.circle.fill"
            )
            alert = AlarmPresentation.Alert(
                title: LocalizedStringResource(
                    "NapNav ใกล้ถึงจุดหมาย",
                    locale: AppLocalization.locale
                ),
                stopButton: stopButton
            )
        }

        let attributes = AlarmAttributes(
            presentation: AlarmPresentation(alert: alert),
            metadata: NapNavAlarmMetadata(
                destinationID: destination.id,
                destinationName: destination.name
            ),
            tintColor: AppTheme.primary
        )
        let configuration = AlarmManager.AlarmConfiguration.alarm(
            schedule: .fixed(Date().addingTimeInterval(max(delay, 1))),
            attributes: attributes,
            // The system stop control silences this alarm. Ending the trip is a separate user action.
            stopIntent: nil
        )
        let id = identifier ?? UUID()
        prominentAlarmID = id
        do {
            _ = try await AlarmManager.shared.schedule(id: id, configuration: configuration)
        } catch {
            if prominentAlarmID == id {
                prominentAlarmID = nil
            }
            throw error
        }
    }
#endif
}

typealias LocalNotificationClient = LocalAlarmDelivery

#if canImport(AlarmKit)
@available(iOS 26.0, *)
private struct NapNavAlarmMetadata: AlarmMetadata {
    let destinationID: String
    let destinationName: String
}
#endif

final class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate, @unchecked Sendable {
    static let shared = NotificationDelegate()
    @MainActor
    var onTripAction: (@MainActor @Sendable (String, UUID?) -> Void)?

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        if Thread.isMainThread {
            completionHandler([.banner, .sound])
        } else {
            nonisolated(unsafe) let completion = completionHandler
            DispatchQueue.main.async {
                completion([.banner, .sound])
            }
        }
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let rawTripID = response.notification.request.content.userInfo["tripID"] as? String
        let actionIdentifier = response.actionIdentifier
        let tripID = rawTripID.flatMap(UUID.init(uuidString:))

        if Thread.isMainThread {
            MainActor.assumeIsolated {
                self.handleActionIdentifier(actionIdentifier, tripID: tripID)
            }
            completionHandler()
        } else {
            nonisolated(unsafe) let completion = completionHandler
            DispatchQueue.main.async {
                self.handleActionIdentifier(actionIdentifier, tripID: tripID)
                completion()
            }
        }
    }

    @MainActor
    func handleActionIdentifier(_ identifier: String, tripID: UUID? = nil) {
        switch identifier {
        case LocalAlarmDelivery.stopActionIdentifier,
             LocalAlarmDelivery.snoozeActionIdentifier:
            onTripAction?(identifier, tripID)
        default:
            break
        }
    }
}
