import Foundation
import Observation
import SwiftUI
import UIKit

@MainActor
protocol TripClock {
    var now: Date { get }
    func sleep(until deadline: Date) async throws
}

@MainActor
protocol TripBackgroundTaskManaging: AnyObject {
    func beginBackgroundTask(
        withName name: String,
        expirationHandler: @escaping @MainActor @Sendable () -> Void
    ) -> UIBackgroundTaskIdentifier
    func endBackgroundTask(_ identifier: UIBackgroundTaskIdentifier)
}

@MainActor
private struct SystemTripClock: TripClock {
    var now: Date { Date() }

    func sleep(until deadline: Date) async throws {
        let remaining = max(deadline.timeIntervalSinceNow, 0)
        guard remaining > 0 else { return }
        try await Task.sleep(for: .seconds(remaining))
    }
}

@MainActor
private final class UIApplicationBackgroundTaskManager: TripBackgroundTaskManaging {
    func beginBackgroundTask(
        withName name: String,
        expirationHandler: @escaping @MainActor @Sendable () -> Void
    ) -> UIBackgroundTaskIdentifier {
        UIApplication.shared.beginBackgroundTask(withName: name) {
            Task { @MainActor in expirationHandler() }
        }
    }

    func endBackgroundTask(_ identifier: UIBackgroundTaskIdentifier) {
        guard identifier != .invalid else { return }
        UIApplication.shared.endBackgroundTask(identifier)
    }
}

@MainActor
@Observable
final class TripStore {
    enum Screen: Equatable {
        case destination
        case setup
        case tracking
    }

    var screen: Screen = .destination
    var destination: Destination = .asok
    var selectedRadiusMeters = 1_000.0
    var mapDisplayStyle: MapDisplayStyle = .explore
    var phase: TripPhase = .idle
    var arrivalStatus: ArrivalStatus = .outside
    var health: TripHealth = .ready
    var alertCleanupWarning: String?
    var currentDistanceMeters: Double?
    var currentCoordinate: LocationCoordinate?
    var horizontalAccuracyMeters: Double?
    var lastLocationAt: Date?
    var locationStatus: LiveLocationStatus = .idle
    var notificationReady = false
    var prominentAlarmSupported = false
    var prominentAlarmReady = false
    var alarmReadiness: AlarmReadiness = .unknown
    var alertSent = false
    var lastAlertDeliveryResult: AlertDeliveryResult?
    var testNotificationMessage: String?
    var alertPreferences: UserAlertPreferences
    var showsSettings = false
    var showsOnboarding = false
    var launchState: AppLaunchState = .launching(message: AppLocalization.string("กำลังเตรียมแผนที่"))
    var showsStartupView = false
    var isStartingTrip = false
    var recoveryAvailable = true
    var autoStopAt: Date? = nil
    private(set) var pendingRecoverySnapshot: ActiveTripSnapshot?
    private(set) var favorites: [SavedDestination] = []
    private(set) var recents: [SavedDestination] = []

    private let locationClient: any LocationProviding
    private let notificationClient: any NotificationProviding
    private let persistence: any TripPersisting
    private let liveActivityManager: any LiveActivityManaging
    private let clock: any TripClock
    private let backgroundTaskManager: any TripBackgroundTaskManaging
    private var triggerPolicy = TriggerPolicy()
    private var arrivalPolicy = ArrivalPolicy()
    private var alertTriggered = false
    private var alertDeliveryInFlightTripID: UUID?
    private var alertDeliveryRetryCount = 0
    private var nextAlertDeliveryAttemptAt: Date?
    private let alertDeliveryRetryBaseInterval: TimeInterval = 10
    private let alertDeliveryRetryMaximumInterval: TimeInterval = 60
    private var trackingTask: Task<Void, Never>?
    private var autoStopTask: Task<Void, Never>?
    private var autoStopScheduleID: UUID?
    private var autoStopBackgroundTaskID: UIBackgroundTaskIdentifier = .invalid
    private var lastLiveActivityUpdate: (distance: Double, isAlert: Bool, isArrived: Bool, lang: String)?
    private var didPrepareForLaunch = false
    private var lifecycleGeneration: UInt64 = 0
    private var isDiscardingRecoveredTrip = false
    private var initialTripDistance: Double?
    private var activeTripID: UUID?
    private var tripStartedAt: Date?
    private var prominentAlarmIdentifier: UUID?
    private var snoozeAt: Date?

    init(
        locationClient: any LocationProviding = LiveLocationClient(),
        notificationClient: any NotificationProviding = LocalNotificationClient(),
        persistence: any TripPersisting = NoopTripPersistence(),
        liveActivityManager: any LiveActivityManaging = NoopLiveActivityManager(),
        clock: (any TripClock)? = nil,
        backgroundTaskManager: (any TripBackgroundTaskManaging)? = nil
    ) {
        self.locationClient = locationClient
        self.notificationClient = notificationClient
        self.persistence = persistence
        self.liveActivityManager = liveActivityManager
        self.clock = clock ?? SystemTripClock()
        self.backgroundTaskManager = backgroundTaskManager ?? UIApplicationBackgroundTaskManager()
        self.alertPreferences = persistence.loadAlertPreferences()
        self.favorites = persistence.loadFavorites()
        self.recents = persistence.loadRecents()

    }

    func prepareForLaunch() async {
        guard didPrepareForLaunch == false else { return }
        didPrepareForLaunch = true
        lifecycleGeneration &+= 1
        let generation = lifecycleGeneration
        launchState = .launching(message: AppLocalization.string("กำลังเตรียมแผนที่"))
        alertPreferences = persistence.loadAlertPreferences()
        guard await refreshReadiness(forGeneration: generation) else { return }
        applyAlertCancellationResult(notificationClient.reconcilePendingTripAlertCancellations())
        await liveActivityManager.endAllTripActivities()
        guard lifecycleGeneration == generation else { return }

        showsStartupView = false
        let outcome = await performLaunchPreparation()
        guard lifecycleGeneration == generation else { return }

        switch outcome {
        case .ready:
            launchState = .ready
        case .recovery(let destinationName):
            launchState = .awaitingTripRecovery(destinationName: destinationName)
            showsStartupView = true
        case .failed(let message):
            launchState = .failed(message: message)
            showsStartupView = true
        }

        if alertCleanupWarning != nil {
            health = .alertCleanupFailed
        }
    }

    func relaunchApp() async {
        didPrepareForLaunch = false
        showsStartupView = false
        launchState = .launching(message: AppLocalization.string("กำลังเตรียมแผนที่"))
        await prepareForLaunch()
    }

    private enum LaunchOutcome {
        case ready
        case recovery(destinationName: String)
        case failed(message: String)
    }

    private func performLaunchPreparation() async -> LaunchOutcome {
        do {
            if let snapshot = try persistence.loadActiveTrip() {
                guard isRecoverable(snapshot) else {
                    applyAlertCancellationResult(notificationClient.cancelTripAlerts(
                        destinationID: snapshot.destination.id,
                        tripID: snapshot.id,
                        prominentAlarmIdentifier: snapshot.prominentAlarmIdentifier
                    ))
                    try persistence.clearActiveTrip()
                    resetToIdleDestinationState()
                    return .ready
                }
                // The user may stop an AlarmKit alert without ending the trip.
                // Alarm presence must not decide whether an active trip can be restored.
                pendingRecoverySnapshot = snapshot
                return .recovery(destinationName: snapshot.destination.name)
            }
            return .ready
        } catch {
            return .failed(message: AppLocalization.string("อ่านข้อมูลทริปเดิมไม่ได้ ลองใหม่อีกครั้ง"))
        }
    }

    func updateAlertPreferences(_ preferences: UserAlertPreferences) {
        alertPreferences = preferences
        persistence.saveAlertPreferences(preferences)
    }

    func appLanguageDidChange() {
        if isActiveTripPhase(phase) == false, destination.id == Destination.asok.id {
            destination = .asok
        }
        testNotificationMessage = nil
        if phase == .tracking || phase == .arrived {
            lastLiveActivityUpdate = nil
            let distance = currentDistanceMeters ?? 0
            updateLiveActivityIfNeeded(
                distance: distance,
                isAlertTriggered: alertTriggered,
                isArrived: phase == .arrived,
                autoStopAt: autoStopAt
            )
        }
    }

    func refreshReadiness() async {
        var readiness = await notificationClient.readiness()
        if readiness.permission == .authorized && readiness.timeSensitiveSetting == .notSupported {
            _ = await notificationClient.requestAuthorizationIfNeeded()
            readiness = await notificationClient.readiness()
        }
        let capabilities = await notificationClient.deliveryCapabilities()
        applyReadiness(readiness, capabilities: capabilities)
    }

    private func refreshReadiness(forGeneration generation: UInt64) async -> Bool {
        var readiness = await notificationClient.readiness()
        guard lifecycleGeneration == generation else { return false }
        if readiness.permission == .authorized && readiness.timeSensitiveSetting == .notSupported {
            _ = await notificationClient.requestAuthorizationIfNeeded()
            guard lifecycleGeneration == generation else { return false }
            readiness = await notificationClient.readiness()
        }
        let capabilities = await notificationClient.deliveryCapabilities()
        guard lifecycleGeneration == generation else { return false }
        alarmReadiness = readiness
        applyReadiness(readiness, capabilities: capabilities)
        return true
    }

    private func refreshReadiness(forTripID tripID: UUID) async -> Bool {
        let readiness = await notificationClient.readiness()
        guard activeTripID == tripID else { return false }
        let capabilities = await notificationClient.deliveryCapabilities()
        guard activeTripID == tripID else { return false }
        alarmReadiness = readiness
        applyReadiness(readiness, capabilities: capabilities)
        return true
    }

    private func applyReadiness(
        _ readiness: AlarmReadiness,
        capabilities: AlertDeliveryCapabilities
    ) {
        alarmReadiness = readiness
        notificationReady = capabilities.notificationReady
        prominentAlarmSupported = capabilities.alarmKitSupported
        prominentAlarmReady = capabilities.alarmKitAuthorized
    }

    func retryLaunch() async {
        pendingRecoverySnapshot = nil
        didPrepareForLaunch = false
        await prepareForLaunch()
    }

    func requestLocationPermission() {
        locationClient.requestWhenInUseAuthorization()
    }

    @discardableResult
    func requestNotificationPermission() async -> Bool {
        let granted = await notificationClient.requestAuthorizationIfNeeded()
        _ = await refreshReadiness()
        return granted
    }

    @discardableResult
    func requestAlarmKitPermission() async -> Bool {
        let granted = await notificationClient.requestProminentAlarmAuthorizationIfAvailable()
        _ = await refreshReadiness()
        return granted
    }

    func requestOnboardingPermissions() async {
        locationClient.requestWhenInUseAuthorization()
        _ = await notificationClient.requestAuthorizationIfNeeded()
        if prominentAlarmSupported || shouldRequestProminentAlarmAuthorization {
            _ = await notificationClient.requestProminentAlarmAuthorizationIfAvailable()
        }
        _ = await refreshReadiness()
    }

    func resumeRecoveredTrip() async {
        guard let snapshot = pendingRecoverySnapshot else { return }
        pendingRecoverySnapshot = nil
        guard isRecoverable(snapshot) else {
            do {
                try persistence.clearActiveTrip()
                recoveryAvailable = true
            } catch {
                recoveryAvailable = false
                health = .persistenceUnavailable
            }
            launchState = .ready
            showsStartupView = false
            return
        }
        lifecycleGeneration &+= 1
        let generation = lifecycleGeneration
        launchState = .recoveringTrip(message: AppLocalization.string("กำลังกู้คืนทริป"))
        showsStartupView = true

        guard restore(snapshot) else { return }
        guard await refreshReadiness(forGeneration: generation),
              lifecycleGeneration == generation,
              activeTripID == snapshot.id else { return }
        health = alertDeliveryReady ? .ready : .notificationUnavailable

        if snapshot.phase == .arrived {
            if snapshot.autoStopAt != nil {
                reconcileAutoStopDeadline()
            } else {
                completeTrip()
            }
        } else {
            beginTracking()
        }

        launchState = .ready
        showsStartupView = false
    }

    func discardRecoveredTrip() async {
        guard isDiscardingRecoveredTrip == false else { return }
        isDiscardingRecoveredTrip = true
        defer { isDiscardingRecoveredTrip = false }
        lifecycleGeneration &+= 1
        let generation = lifecycleGeneration
        let recoveredSnapshot = pendingRecoverySnapshot
        pendingRecoverySnapshot = nil
        trackingTask?.cancel()
        trackingTask = nil
        cancelScheduledAutoStop()
        locationClient.stopUpdates()
        if let recoveredSnapshot {
            applyAlertCancellationResult(notificationClient.cancelTripAlerts(
                destinationID: recoveredSnapshot.destination.id,
                tripID: recoveredSnapshot.id,
                prominentAlarmIdentifier: recoveredSnapshot.prominentAlarmIdentifier
            ))
        } else {
            let result = await notificationClient.cancelAllTripAlerts()
            applyAlertCancellationResult(result)
            guard lifecycleGeneration == generation else { return }
        }
        await liveActivityManager.endAllTripActivities()
        guard lifecycleGeneration == generation else { return }

        do {
            try persistence.clearActiveTrip()
            recoveryAvailable = true
            resetToIdleDestinationState()
            launchState = .ready
            showsStartupView = false
        } catch {
            recoveryAvailable = false
            health = .persistenceUnavailable
            launchState = .failed(message: AppLocalization.string("ล้างข้อมูลทริปเดิมไม่ได้ ลองใหม่อีกครั้ง"))
            showsStartupView = true
        }
    }

    func useSelectedDestination() {
        phase = .preparing
        screen = .setup
    }

    func selectDestination(_ destination: Destination) {
        guard trackingTask == nil else { return }
        self.destination = destination
        phase = .idle
        screen = .destination
    }

    func startTrip() async {
        guard trackingTask == nil,
              isStartingTrip == false,
              isDiscardingRecoveredTrip == false else { return }
        lifecycleGeneration &+= 1
        let generation = lifecycleGeneration
        isStartingTrip = true
        defer { isStartingTrip = false }

        _ = await notificationClient.requestAuthorizationIfNeeded()
        guard lifecycleGeneration == generation else { return }
        if shouldRequestProminentAlarmAuthorization {
            _ = await notificationClient.requestProminentAlarmAuthorizationIfAvailable()
            guard lifecycleGeneration == generation else { return }
        }
        guard await refreshReadiness(forGeneration: generation) else { return }

        guard alertDeliveryReady else {
            health = .notificationUnavailable
            showsSettings = true
            return
        }

        health = .ready
        showsSettings = false
        recordRecent(destination: destination, radiusMeters: selectedRadiusMeters)
        locationStatus = .requestingPermission
        locationClient.requestWhenInUseAuthorization()
        triggerPolicy.reset()
        arrivalPolicy.reset()
        arrivalStatus = .outside
        alertTriggered = false
        alertSent = false
        lastAlertDeliveryResult = nil
        resetAlertDeliveryRetryState()
        cancelScheduledAutoStop()
        autoStopAt = nil
        snoozeAt = nil
        activeTripID = UUID()
        tripStartedAt = Date()
        prominentAlarmIdentifier = nil
        lastLiveActivityUpdate = nil
        phase = .tracking
        screen = .tracking
        persistActiveTrip()
        let initialDistance = currentDistanceMeters ?? (selectedRadiusMeters * 2.0)
        initialTripDistance = currentDistanceMeters
        liveActivityManager.startTripActivity(
            destination: destination,
            initialDistance: initialDistance,
            alertRadius: selectedRadiusMeters
        )
        beginTracking()
    }

    func stopTrip() {
        finishTrip(finalPhase: .cancelled, wasArrived: false)
    }

    func makeStopConfirmationRequest() -> TripStopConfirmationRequest? {
        if let activeTripID, isActiveTripPhase(phase) {
            return TripStopConfirmationRequest(
                tripID: activeTripID,
                destinationName: destination.name,
                action: stopConfirmationAction(for: phase)
            )
        }

        guard let snapshot = pendingRecoverySnapshot,
              isRecoverable(snapshot) else { return nil }
        return TripStopConfirmationRequest(
            tripID: snapshot.id,
            destinationName: snapshot.destination.name,
            action: stopConfirmationAction(for: snapshot.phase)
        )
    }

    func confirmStop(_ request: TripStopConfirmationRequest) async {
        if activeTripID == request.tripID {
            guard isActiveTripPhase(phase) else { return }
            switch request.action {
            case .stop:
                stopTrip()
            case .finish:
                guard phase == .arrived else { return }
                completeTrip()
            }
            return
        }

        guard let snapshot = pendingRecoverySnapshot,
              snapshot.id == request.tripID,
              stopConfirmationAction(for: snapshot.phase) == request.action else { return }
        await discardRecoveredTrip()
    }

    @discardableResult
    func reconcilePendingAlertCancellations() -> AlertCancellationResult {
        let result = notificationClient.reconcilePendingTripAlertCancellations()
        applyAlertCancellationResult(result)
        return result
    }

    func completeTrip() {
        finishTrip(finalPhase: .completed, wasArrived: true)
    }

    func reconcileAutoStopDeadline() {
        guard phase == .arrived else { return }
        guard let deadline = autoStopAt else {
            completeTrip()
            return
        }

        guard clock.now < deadline else {
            completeTrip()
            return
        }
        scheduleAutoStop(until: deadline)
    }

    func sendTestNotification(after delay: TimeInterval = 0) async {
        testNotificationMessage = nil
        let granted = await notificationClient.requestAuthorizationIfNeeded()
        alarmReadiness = await notificationClient.readiness()
        notificationReady = alarmReadiness.canDeliverVisibleAlert

        guard granted, notificationReady else {
            health = .notificationUnavailable
            testNotificationMessage = AppLocalization.string("ยังไม่ได้อนุญาตการแจ้งเตือน")
            return
        }

        do {
            try await notificationClient.sendTestAlert(after: delay)
            testNotificationMessage = delay > 0
                ? AppLocalization.format(
                    "ตั้งเวลาแจ้งเตือนในอีก %d วินาที (ล็อกหน้าจอรอได้เลย)",
                    Int(delay)
                )
                : AppLocalization.string("ส่งการแจ้งเตือนทดสอบแล้ว")
        } catch {
            testNotificationMessage = AppLocalization.string("ส่งการแจ้งเตือนไม่สำเร็จ")
        }
    }

    func sendTestApproachingNotification() async {
        testNotificationMessage = nil
        await prepareAlertDeliveryForCurrentPreferences()

        guard alertDeliveryPlan.isAvailable else {
            health = .notificationUnavailable
            testNotificationMessage = alertDeliveryPlan.summary
            return
        }

        let result = await notificationClient.sendArrivalAlert(
            destination: destination,
            distanceMeters: 500,
            preferences: alertPreferences
        )
        lastAlertDeliveryResult = result
        testNotificationMessage = result.didDeliver
            ? AppLocalization.format("ส่งการเตือนใกล้ถึง (500 ม.) แล้ว — %@", result.summary)
            : result.summary
    }

    func sendTestArrivalNotification() async {
        testNotificationMessage = nil
        await prepareAlertDeliveryForCurrentPreferences()

        guard alertDeliveryPlan.isAvailable else {
            health = .notificationUnavailable
            testNotificationMessage = alertDeliveryPlan.summary
            return
        }

        let result = await notificationClient.sendArrivalAlert(
            destination: destination,
            distanceMeters: 20,
            preferences: alertPreferences
        )
        lastAlertDeliveryResult = result
        testNotificationMessage = result.didDeliver
            ? AppLocalization.format("ส่งการเตือนถึงจุดหมาย (20 ม.) แล้ว — %@", result.summary)
            : result.summary
    }

    func startTripActivitySimulation(phase: TripPhase) {
        let initialDist = 3_000.0
        liveActivityManager.startTripActivity(
            destination: destination,
            initialDistance: initialDist,
            alertRadius: selectedRadiusMeters
        )

        switch phase {
        case .tracking:
            liveActivityManager.updateTripActivity(
                remainingDistance: 2_900,
                isAlertTriggered: false,
                isArrived: false,
                autoStopAt: nil
            )
            testNotificationMessage = AppLocalization.string("จำลอง Live Activity: กำลังเดินทาง")
        case .approaching:
            liveActivityManager.updateTripActivity(
                remainingDistance: 450,
                isAlertTriggered: true,
                isArrived: false,
                autoStopAt: nil
            )
            testNotificationMessage = AppLocalization.string("จำลอง Live Activity: ใกล้ถึง")
        case .arrived:
            let stopDate = Date().addingTimeInterval(alertPreferences.autoStopDelay.timeInterval)
            liveActivityManager.updateTripActivity(
                remainingDistance: 0,
                isAlertTriggered: true,
                isArrived: true,
                autoStopAt: stopDate
            )
            testNotificationMessage = AppLocalization.format(
                "จำลอง Live Activity: ถึงแล้ว (นับถอยหลัง %@)",
                alertPreferences.autoStopDelay.shortTitle
            )
        default:
            break
        }
    }

    func stopTripActivitySimulation() {
        liveActivityManager.endTripActivity(wasArrived: false)
        testNotificationMessage = AppLocalization.string("ปิด Live Activity จำลองแล้ว")
    }

    func sendProminentAlarmSpike() async {
        testNotificationMessage = nil

        do {
            try await notificationClient.sendProminentAlarmSpike(
                destination: destination,
                after: 5
            )
            testNotificationMessage = AppLocalization.string("ตั้ง Alarm ทดลองแล้ว จะดังในประมาณ 5 วินาที")
        } catch AlarmDeliveryError.prominentAlarmDenied {
            testNotificationMessage = AppLocalization.string("ยังไม่ได้อนุญาต Alarm ให้ NapNav")
        } catch {
            testNotificationMessage = AppLocalization.string("เครื่องนี้ยังใช้ Alarm แบบเด่นชัดไม่ได้")
        }
    }

    @discardableResult
    func handleNotificationAction(
        _ identifier: String,
        tripID actionTripID: UUID? = nil
    ) -> Task<Void, Never>? {
        guard let tripID = activeTripID,
              isActiveTripPhase(phase),
              actionTripID == nil || actionTripID == tripID else { return nil }
        let actionDestination = destination

        switch identifier {
        case LocalAlarmDelivery.stopActionIdentifier:
            stopTrip()
            return nil
        case LocalAlarmDelivery.snoozeActionIdentifier:
            phase = .tracking
            return Task { [weak self] in
                guard let self else { return }
                do {
                    try await self.notificationClient.scheduleSnoozeAlert(
                        tripID: tripID,
                        destination: actionDestination,
                        after: 5 * 60
                    )
                    guard self.activeTripID == tripID else {
                        self.applyAlertCancellationResult(self.notificationClient.cancelTripAlerts(
                            destinationID: actionDestination.id,
                            tripID: tripID,
                            prominentAlarmIdentifier: nil
                        ))
                        return
                    }
                    self.snoozeAt = Date().addingTimeInterval(5 * 60)
                    self.persistActiveTrip()
                } catch {
                    if self.activeTripID == tripID {
                        self.health = .notificationUnavailable
                    }
                }
            }
        default:
            return nil
        }
    }

    func processLocationEvent(_ event: LocationEvent, at now: Date = Date()) async {
        guard let tripID = activeTripID, isActiveTripPhase(phase) else { return }
        await processLocationEvent(event, tripID: tripID, at: now)
    }

    private func processLocationEvent(
        _ event: LocationEvent,
        tripID: UUID,
        at now: Date
    ) async {
        guard activeTripID == tripID, isActiveTripPhase(phase) else { return }
        switch event {
        case .sample(let sample):
            await handle(sample, tripID: tripID, now: now)
        case .accuracyLimited:
            locationStatus = .accuracyLimited
            health = .reducedAccuracy
        case .unavailable:
            locationStatus = .unavailable
            health = .locationUnavailable
        case .authorizationDenied:
            locationStatus = .denied
            health = .locationUnavailable
        case .servicesDisabled:
            locationStatus = .servicesDisabled
            health = .locationUnavailable
        case .failed(let message):
            locationStatus = .failed(message)
            health = .locationUnavailable
        }
    }

    private func handle(_ sample: LocationSample, tripID: UUID, now: Date) async {
        guard activeTripID == tripID, isActiveTripPhase(phase) else { return }
        let triggerDecision = triggerPolicy.evaluate(
            sample,
            destination: destination,
            radiusMeters: selectedRadiusMeters,
            now: now
        )
        let arrivalDecision = arrivalPolicy.evaluate(
            sample,
            destination: destination,
            now: now
        )

        switch triggerDecision {
        case .rejected(.stale):
            health = .staleLocation
            return
        case .rejected:
            health = .reducedAccuracy
            if case .nearbyUncertain(let distance) = arrivalDecision {
                publish(sample, distance: distance)
                locationStatus = .accuracyLimited
            }
            apply(arrivalDecision)
            return
        case .uncertain(let distance):
            publish(sample, distance: distance)
            locationStatus = .accuracyLimited
            health = .reducedAccuracy
        case .outside(let distance):
            publish(sample, distance: distance)
            if locationStatus != .accuracyLimited {
                locationStatus = .receiving
                health = alertDeliveryReady ? .ready : .notificationUnavailable
            }
            if alertTriggered == false {
                phase = .tracking
            }
        case .approaching(let distance):
            publish(sample, distance: distance)
            if locationStatus != .accuracyLimited {
                locationStatus = .receiving
                health = alertDeliveryReady ? .ready : .notificationUnavailable
            }
            if alertTriggered == false {
                phase = .approaching
            } else if alertSent == false {
                await attemptAlertDelivery(distanceMeters: distance, tripID: tripID, at: now)
            }
        case .trigger(let distance):
            publish(sample, distance: distance)
            if locationStatus != .accuracyLimited {
                locationStatus = .receiving
            }
            alertTriggered = true
            phase = .alarm
            await attemptAlertDelivery(distanceMeters: distance, tripID: tripID, at: now)
        }

        guard activeTripID == tripID, isActiveTripPhase(phase) else { return }
        apply(arrivalDecision)

        if let distance = currentDistanceMeters {
            updateLiveActivityIfNeeded(
                distance: distance,
                isAlertTriggered: alertTriggered,
                isArrived: (arrivalStatus == .arrived || phase == .arrived)
            )
        }
    }

    private func attemptAlertDelivery(distanceMeters: Double, tripID: UUID, at now: Date) async {
        guard activeTripID == tripID,
              alertTriggered,
              alertSent == false,
              alertDeliveryInFlightTripID != tripID else { return }
        if let nextAlertDeliveryAttemptAt, now < nextAlertDeliveryAttemptAt { return }

        alertDeliveryInFlightTripID = tripID
        defer {
            if alertDeliveryInFlightTripID == tripID {
                alertDeliveryInFlightTripID = nil
            }
        }

        // Refresh readiness only at the initial trigger and when a retry is due.
        guard await refreshReadiness(forTripID: tripID),
              activeTripID == tripID,
              alertTriggered,
              alertSent == false else { return }

        guard alertDeliveryReady else {
            recordUnavailableDelivery(
                reason: alertDeliveryPlan.unavailableReason ?? .noAvailablePath,
                at: now
            )
            return
        }

        let result = await notificationClient.sendArrivalAlert(
            tripID: tripID,
            destination: destination,
            distanceMeters: distanceMeters,
            preferences: alertPreferences
        )
        guard activeTripID == tripID, alertTriggered, alertSent == false else {
            applyAlertCancellationResult(notificationClient.cancelTripAlerts(
                destinationID: destination.id,
                tripID: tripID,
                prominentAlarmIdentifier: result.usesProminentAlarm ? tripID : nil
            ))
            return
        }
        lastAlertDeliveryResult = result
        alertSent = result.didDeliver
        prominentAlarmIdentifier = result.usesProminentAlarm
            ? notificationClient.prominentAlarmIdentifier(forTripID: tripID)
            : nil

        if alertSent {
            health = .ready
            resetAlertDeliveryRetryState()
        } else {
            health = .notificationUnavailable
            scheduleNextAlertDeliveryAttempt(after: now)
        }
        persistActiveTrip()
    }

    private func recordUnavailableDelivery(
        reason: AlertDeliveryUnavailableReason,
        at now: Date
    ) {
        lastAlertDeliveryResult = .deliveryUnavailable(reason: reason)
        health = .notificationUnavailable
        scheduleNextAlertDeliveryAttempt(after: now)
        persistActiveTrip()
    }

    private func scheduleNextAlertDeliveryAttempt(after now: Date) {
        // Exponential backoff (10, 20, 40 s), capped at 60 s; retries remain
        // live at that bounded rate until delivery succeeds or the trip ends.
        let multiplier = pow(2, Double(alertDeliveryRetryCount))
        let delay = min(alertDeliveryRetryBaseInterval * multiplier, alertDeliveryRetryMaximumInterval)
        alertDeliveryRetryCount += 1
        nextAlertDeliveryAttemptAt = now.addingTimeInterval(delay)
    }

    private func resetAlertDeliveryRetryState() {
        alertDeliveryInFlightTripID = nil
        alertDeliveryRetryCount = 0
        nextAlertDeliveryAttemptAt = nil
    }

    private func apply(_ decision: ArrivalDecision) {
        guard phase != .arrived else { return }

        switch decision {
        case .rejected:
            arrivalStatus = .outside
        case .outside:
            if phase != .arrived {
                arrivalStatus = .outside
            }
        case .nearbyUncertain:
            arrivalStatus = .nearby
            health = .reducedAccuracy
        case .confirming:
            arrivalStatus = .nearby
        case .arrived:
            arrivalStatus = .arrived
            phase = .arrived
            handleArrival()
        }
    }

    private func handleArrival() {
        // Stop active GPS updates immediately to conserve battery
        trackingTask?.cancel()
        trackingTask = nil
        locationClient.stopUpdates()

        let delay = alertPreferences.autoStopDelay
        let autoStopDate: Date? = delay == .immediately ? nil : clock.now.addingTimeInterval(delay.timeInterval)
        self.autoStopAt = autoStopDate
        persistActiveTrip()

        // Force update Live Activity with arrived state and autoStopAt
        lastLiveActivityUpdate = nil
        liveActivityManager.updateTripActivity(
            remainingDistance: 0,
            initialDistance: initialTripDistance,
            languageCode: AppLocalization.selectedLanguage.resolvedIdentifier,
            isAlertTriggered: true,
            isArrived: true,
            autoStopAt: autoStopDate
        )

        if delay == .immediately {
            completeTrip()
        } else if let autoStopDate {
            scheduleAutoStop(until: autoStopDate)
        }
    }

    /// อัปเดต Live Activity เฉพาะเมื่อค่าเปลี่ยนอย่างมีนัย (ลด Task สปอน + battery)
    private func updateLiveActivityIfNeeded(
        distance: Double,
        isAlertTriggered: Bool,
        isArrived: Bool,
        autoStopAt: Date? = nil
    ) {
        let currentLang = AppLocalization.selectedLanguage.resolvedIdentifier
        if let last = lastLiveActivityUpdate {
            let distanceUnchanged = abs(last.distance - distance) < 20
            let flagsUnchanged = last.isAlert == isAlertTriggered && last.isArrived == isArrived
            let langUnchanged = last.lang == currentLang
            if distanceUnchanged && flagsUnchanged && langUnchanged && autoStopAt == nil { return }
        }
        lastLiveActivityUpdate = (distance, isAlertTriggered, isArrived, currentLang)
        liveActivityManager.updateTripActivity(
            remainingDistance: distance,
            initialDistance: initialTripDistance,
            languageCode: currentLang,
            isAlertTriggered: isAlertTriggered,
            isArrived: isArrived,
            autoStopAt: autoStopAt
        )
    }

    private func publish(_ sample: LocationSample, distance: Double) {
        currentDistanceMeters = distance
        currentCoordinate = sample.coordinate
        horizontalAccuracyMeters = sample.horizontalAccuracy
        lastLocationAt = sample.timestamp

        if initialTripDistance == nil {
            initialTripDistance = distance
        } else if let initDist = initialTripDistance, distance > initDist {
            initialTripDistance = distance
        }
    }

    var alertDeliveryCapabilities: AlertDeliveryCapabilities {
        AlertDeliveryCapabilities(
            notificationReady: notificationReady,
            notificationSoundsEnabled: alarmReadiness.soundsEnabled,
            alarmKitSupported: prominentAlarmSupported,
            alarmKitAuthorized: prominentAlarmReady
        )
    }

    var alertDeliveryPlan: AlertDeliveryPlan {
        AlertDeliveryPolicy.plan(
            preferences: alertPreferences,
            capabilities: alertDeliveryCapabilities
        )
    }

    var availableDeliveryModes: [AlertDeliveryMode] {
        prominentAlarmSupported
            ? AlertDeliveryMode.allCases
            : [.notification]
    }

    var alertDeliveryReady: Bool {
        alertDeliveryPlan.isAvailable
    }

    private var shouldRequestProminentAlarmAuthorization: Bool {
        alertPreferences.soundMode == .soundAndHaptic
            && (alertPreferences.deliveryMode == .alarmKit || alertPreferences.deliveryMode == .both)
    }

    private func prepareAlertDeliveryForCurrentPreferences() async {
        _ = await notificationClient.requestAuthorizationIfNeeded()
        if shouldRequestProminentAlarmAuthorization {
            _ = await notificationClient.requestProminentAlarmAuthorizationIfAvailable()
        }
        await refreshReadiness()
    }

    private func beginTracking() {
        guard trackingTask == nil,
              let tripID = activeTripID,
              isActiveTripPhase(phase) else { return }
        let events = locationClient.startUpdates()
        trackingTask = Task { [weak self] in
            for await event in events {
                guard Task.isCancelled == false else { break }
                await self?.processLocationEvent(event, tripID: tripID, at: Date())
            }
        }
    }

    private func persistActiveTrip() {
        guard let id = activeTripID,
              let startedAt = tripStartedAt,
              isActiveTripPhase(phase) else { return }
        let snapshot = ActiveTripSnapshot(
            id: id,
            destination: destination,
            radiusMeters: selectedRadiusMeters,
            startedAt: startedAt,
            phase: phase,
            alertTriggered: alertTriggered,
            alertSent: alertSent,
            prominentAlarmIdentifier: prominentAlarmIdentifier,
            autoStopAt: autoStopAt,
            snoozeAt: snoozeAt
        )
        do {
            try persistence.saveActiveTrip(snapshot)
            recoveryAvailable = true
        } catch {
            recoveryAvailable = false
            health = .persistenceUnavailable
        }
    }

    private func resetToIdleDestinationState() {
        cancelScheduledAutoStop()
        phase = .idle
        arrivalStatus = .outside
        locationStatus = .idle
        currentDistanceMeters = nil
        currentCoordinate = nil
        horizontalAccuracyMeters = nil
        lastLocationAt = nil
        alertTriggered = false
        alertSent = false
        resetAlertDeliveryRetryState()
        initialTripDistance = nil
        lastLiveActivityUpdate = nil
        autoStopAt = nil
        snoozeAt = nil
        activeTripID = nil
        tripStartedAt = nil
        prominentAlarmIdentifier = nil
        screen = .destination
    }

    private func restore(_ snapshot: ActiveTripSnapshot) -> Bool {
        guard isRecoverable(snapshot) else { return false }
        destination = snapshot.destination
        selectedRadiusMeters = snapshot.radiusMeters
        triggerPolicy.reset()
        arrivalPolicy.reset()
        arrivalStatus = snapshot.phase == .arrived ? .arrived : .outside
        alertTriggered = snapshot.alertTriggered
        alertSent = snapshot.alertSent
        resetAlertDeliveryRetryState()
        phase = snapshot.phase
        locationStatus = snapshot.phase == .arrived ? .idle : .requestingPermission
        screen = .tracking
        activeTripID = snapshot.id
        tripStartedAt = snapshot.startedAt
        prominentAlarmIdentifier = snapshot.prominentAlarmIdentifier
        autoStopAt = snapshot.autoStopAt
        snoozeAt = snapshot.snoozeAt
        initialTripDistance = nil
        lastLiveActivityUpdate = nil
        liveActivityManager.startTripActivity(
            destination: snapshot.destination,
            initialDistance: snapshot.radiusMeters * 2.0,
            alertRadius: snapshot.radiusMeters
        )
        if snapshot.phase == .arrived {
            liveActivityManager.updateTripActivity(
                remainingDistance: 0,
                initialDistance: snapshot.radiusMeters * 2.0,
                languageCode: AppLocalization.selectedLanguage.resolvedIdentifier,
                isAlertTriggered: snapshot.alertTriggered,
                isArrived: true,
                autoStopAt: snapshot.autoStopAt
            )
        }
        return true
    }

    private func isRecoverable(_ snapshot: ActiveTripSnapshot) -> Bool {
        isActiveTripPhase(snapshot.phase)
            && snapshot.radiusMeters.isFinite
            && snapshot.radiusMeters > 0
    }

    private func isActiveTripPhase(_ phase: TripPhase) -> Bool {
        switch phase {
        case .tracking, .approaching, .alarm, .arrived:
            true
        case .idle, .preparing, .completed, .cancelled:
            false
        }
    }

    private func stopConfirmationAction(for phase: TripPhase) -> TripStopConfirmationRequest.Action {
        phase == .arrived ? .finish : .stop
    }

    private func scheduleAutoStop(until deadline: Date) {
        cancelScheduledAutoStop()
        guard phase == .arrived,
              autoStopAt == deadline,
              let tripID = activeTripID else { return }

        let generation = lifecycleGeneration
        let scheduleID = UUID()
        autoStopScheduleID = scheduleID
        let clock = self.clock
        autoStopBackgroundTaskID = backgroundTaskManager.beginBackgroundTask(
            withName: "NapNav.autoStop"
        ) { [weak self] in
            self?.autoStopBackgroundTaskDidExpire(scheduleID: scheduleID)
        }

        autoStopTask = Task { @MainActor [weak self, clock] in
            do {
                while clock.now < deadline {
                    try await clock.sleep(until: deadline)
                    guard Task.isCancelled == false else { return }
                }
            } catch {
                guard Task.isCancelled == false else { return }
                self?.endAutoStopBackgroundTask(scheduleID: scheduleID)
                return
            }

            guard let self,
                  Task.isCancelled == false,
                  self.autoStopScheduleID == scheduleID,
                  self.lifecycleGeneration == generation,
                  self.activeTripID == tripID,
                  self.phase == .arrived,
                  self.autoStopAt == deadline else { return }
            self.completeTrip()
        }
    }

    private func autoStopBackgroundTaskDidExpire(scheduleID: UUID) {
        endAutoStopBackgroundTask(scheduleID: scheduleID)
    }

    private func endAutoStopBackgroundTask(scheduleID: UUID) {
        guard autoStopScheduleID == scheduleID,
              autoStopBackgroundTaskID != .invalid else { return }
        let taskID = autoStopBackgroundTaskID
        autoStopBackgroundTaskID = .invalid
        backgroundTaskManager.endBackgroundTask(taskID)
    }

    private func cancelScheduledAutoStop() {
        autoStopScheduleID = nil
        autoStopTask?.cancel()
        autoStopTask = nil
        if autoStopBackgroundTaskID != .invalid {
            let taskID = autoStopBackgroundTaskID
            autoStopBackgroundTaskID = .invalid
            backgroundTaskManager.endBackgroundTask(taskID)
        }
    }

    private func finishTrip(finalPhase: TripPhase, wasArrived: Bool) {
        let endingTripID = activeTripID
        lifecycleGeneration &+= 1
        cancelScheduledAutoStop()
        trackingTask?.cancel()
        trackingTask = nil
        locationClient.stopUpdates()
        if endingTripID != nil || prominentAlarmIdentifier != nil {
            applyAlertCancellationResult(notificationClient.cancelTripAlerts(
                destinationID: destination.id,
                tripID: endingTripID,
                prominentAlarmIdentifier: prominentAlarmIdentifier
            ))
        }
        liveActivityManager.endTripActivity(wasArrived: wasArrived)

        autoStopAt = nil
        snoozeAt = nil
        prominentAlarmIdentifier = nil
        activeTripID = nil
        tripStartedAt = nil
        initialTripDistance = nil
        lastLiveActivityUpdate = nil
        phase = finalPhase
        if case .recoveringTrip = launchState {
            launchState = .ready
            showsStartupView = false
        }
        arrivalStatus = .outside
        locationStatus = .idle
        currentDistanceMeters = nil
        currentCoordinate = nil
        horizontalAccuracyMeters = nil
        lastLocationAt = nil
        resetAlertDeliveryRetryState()
        screen = .destination

        do {
            try persistence.clearActiveTrip()
            recoveryAvailable = true
        } catch {
            recoveryAvailable = false
            health = .persistenceUnavailable
        }
    }

    private func applyAlertCancellationResult(_ result: AlertCancellationResult) {
        if result.hasFailures {
            alertCleanupWarning = AppLocalization.string(
                "ยกเลิกเสียงเตือนไม่สำเร็จ เสียงอาจยังดังอยู่ NapNav จะลองอีกครั้งเมื่อเปิดแอป"
            )
            health = .alertCleanupFailed
        } else if result.didResolveAlarmCancellation {
            alertCleanupWarning = nil
            if health == .alertCleanupFailed {
                health = .ready
            }
        }
    }

    // MARK: - Favorites & Recents Management

    func isFavorite(_ destination: Destination) -> Bool {
        favorites.contains { fav in
            fav.coordinate == destination.coordinate || fav.title == destination.name
        }
    }

    func favorite(for destination: Destination) -> SavedDestination? {
        favorites.first { fav in
            fav.coordinate == destination.coordinate || fav.title == destination.name
        }
    }

    func saveFavorite(
        title: String,
        subtitle: String,
        coordinate: LocationCoordinate,
        radiusMeters: Double,
        icon: SavedDestinationIcon
    ) {
        var list = favorites
        if let index = list.firstIndex(where: { $0.coordinate == coordinate || $0.title == title }) {
            list[index].title = title
            list[index].subtitle = subtitle
            list[index].radiusMeters = radiusMeters
            list[index].icon = icon
            list[index].isFavorite = true
            list[index].lastUsedAt = clock.now
        } else {
            let newFav = SavedDestination(
                title: title,
                subtitle: subtitle,
                coordinate: coordinate,
                radiusMeters: radiusMeters,
                icon: icon,
                isFavorite: true,
                lastUsedAt: clock.now
            )
            list.append(newFav)
        }
        favorites = list
        persistence.saveFavorites(list)
    }

    func updateFavorite(
        id: UUID,
        title: String,
        icon: SavedDestinationIcon,
        radiusMeters: Double
    ) {
        var list = favorites
        if let index = list.firstIndex(where: { $0.id == id }) {
            list[index].title = title
            list[index].icon = icon
            list[index].radiusMeters = radiusMeters
            list[index].lastUsedAt = clock.now
            favorites = list
            persistence.saveFavorites(list)
        }
    }

    func removeFavorite(id: UUID) {
        var list = favorites
        list.removeAll { $0.id == id }
        favorites = list
        persistence.saveFavorites(list)
    }

    func removeFavorite(for destination: Destination) {
        var list = favorites
        list.removeAll { $0.coordinate == destination.coordinate || $0.title == destination.name }
        favorites = list
        persistence.saveFavorites(list)
    }

    func recordRecent(destination: Destination, radiusMeters: Double) {
        var list = recents
        list.removeAll { $0.coordinate == destination.coordinate || $0.title == destination.name }
        let recent = SavedDestination(
            title: destination.name,
            subtitle: destination.detail,
            coordinate: destination.coordinate,
            radiusMeters: radiusMeters,
            icon: .pin,
            isFavorite: false,
            lastUsedAt: clock.now
        )
        list.insert(recent, at: 0)
        if list.count > 10 {
            list = Array(list.prefix(10))
        }
        recents = list
        persistence.saveRecents(list)
    }

    func removeRecent(id: UUID) {
        var list = recents
        list.removeAll { $0.id == id }
        recents = list
        persistence.saveRecents(list)
    }

    func addRecentToFavorites(_ recent: SavedDestination) {
        saveFavorite(
            title: recent.title,
            subtitle: recent.subtitle,
            coordinate: recent.coordinate,
            radiusMeters: recent.radiusMeters,
            icon: .star
        )
    }

    func clearRecents() {
        recents = []
        persistence.saveRecents([])
    }

    func selectSavedDestination(_ saved: SavedDestination) {
        destination = saved.asDestination
        selectedRadiusMeters = saved.radiusMeters
        recordRecent(destination: destination, radiusMeters: saved.radiusMeters)
    }

    // MARK: - Action Button & Quick Intents

    func handleQuickAction() async {
        if phase.isActive {
            if phase == .alarm || phase == .arrived {
                handleStopAlarm()
            }
        } else {
            await startQuickFavoriteTrip()
        }
    }

    func handleStopAlarm() {
        if phase.isActive {
            stopTrip()
        }
    }

    func startQuickFavoriteTrip(preferringHome: Bool = false) async {
        guard trackingTask == nil, isStartingTrip == false else { return }

        let target: SavedDestination?
        if preferringHome {
            target = favorites.first(where: { $0.icon == .house }) ?? favorites.first
        } else {
            target = favorites.first(where: { $0.icon == .house }) ?? favorites.first
        }

        if let target {
            selectSavedDestination(target)
            screen = .setup
            await startTrip()
        } else {
            screen = .destination
        }
    }
}
