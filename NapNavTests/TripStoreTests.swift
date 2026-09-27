import Foundation
import Testing
import UserNotifications
@testable import NapNav

@MainActor
@Suite("Notification delegate")
struct NotificationDelegateTests {
    @Test("custom stop action ถูกส่งต่อบน Main Actor และ cleanup ทริป")
    func stopActionCleansUpTrip() async {
        let location = MockLocationClient()
        let store = TripStore(
            locationClient: location,
            notificationClient: MockNotificationClient()
        )
        let delegate = NotificationDelegate()
        delegate.onTripAction = { [weak store] identifier, tripID in
            store?.handleNotificationAction(identifier, tripID: tripID)
        }

        await store.startTrip()
        delegate.handleActionIdentifier(LocalAlarmDelivery.stopActionIdentifier)

        #expect(store.phase == .cancelled)
        #expect(location.didStop)
    }

    @Test("แตะตัว notification ปกติเปิดแอปโดยไม่เปลี่ยนสถานะทริป")
    func defaultTapDoesNotMutateTrip() async {
        let store = TripStore(
            locationClient: MockLocationClient(),
            notificationClient: MockNotificationClient()
        )
        let delegate = NotificationDelegate()
        delegate.onTripAction = { [weak store] identifier, tripID in
            store?.handleNotificationAction(identifier, tripID: tripID)
        }

        await store.startTrip()
        delegate.handleActionIdentifier(UNNotificationDefaultActionIdentifier)

        #expect(store.phase == .tracking)
    }
}

@MainActor
@Suite("Public stop links")
struct PublicStopLinkTests {
    @Test("Only exact NapNav routes are accepted; unknown and malformed routes are inert")
    func acceptsOnlyKnownStrictRoutes() throws {
        let stopURL = try #require(URL(string: "napnav://stop-trip"))
        let tripURL = try #require(URL(string: "napnav://trip"))
        let quickURL = try #require(URL(string: "napnav://quick-action"))
        let stopAlarmURL = try #require(URL(string: "napnav://stop-alarm"))
        let startHomeURL = try #require(URL(string: "napnav://start-home"))
        #expect(NapNavDeepLink.route(for: stopURL) == .requestStopConfirmation)
        #expect(NapNavDeepLink.route(for: tripURL) == .trip)
        #expect(NapNavDeepLink.route(for: quickURL) == .quickAction)
        #expect(NapNavDeepLink.route(for: stopAlarmURL) == .stopAlarm)
        #expect(NapNavDeepLink.route(for: startHomeURL) == .startHome)

        for rawURL in [
            "https://example.com/stop-trip",
            "napnav:/stop-trip",
            "napnav://other/stop-trip",
            "napnav://stop-trip/extra",
            "napnav://stop-trip?tripID=forged",
            "napnav://stop-trip#confirm",
            "napnav://stop-trip:443",
            "napnav://stop-trip@attacker"
        ] {
            guard let url = URL(string: rawURL) else { continue }
            #expect(NapNavDeepLink.route(for: url) == nil, "Unexpected route accepted: \(rawURL)")
        }

        #expect(URL(string: "napnav://[") == nil)
    }

    @Test("Public stop URL requests confirmation without mutating an active trip")
    func publicStopURLDoesNotStopTripBeforeConfirmation() async throws {
        let location = MockLocationClient()
        let activity = RecordingLiveActivityManager()
        let store = TripStore(
            locationClient: location,
            notificationClient: MockNotificationClient(),
            liveActivityManager: activity
        )
        await store.startTrip()
        let tripID = try #require(store.makeStopConfirmationRequest()?.tripID)
        let url = try #require(URL(string: "napnav://stop-trip"))

        let request = try #require(NapNavDeepLink.stopConfirmationRequest(for: url, store: store))

        #expect(request.tripID == tripID)
        #expect(request.action == .stop)
        #expect(store.phase == .tracking)
        #expect(location.didStop == false)
        #expect(activity.endCount == 0)
        // Leaving the sheet through its cancel/dismiss action never invokes confirmStop.
        #expect(store.makeStopConfirmationRequest()?.tripID == tripID)
    }

    @Test("Confirm stops only the requested trip and duplicate confirmation is inert")
    func confirmingStopIsTripScopedAndIdempotent() async throws {
        let location = MockLocationClient()
        let activity = RecordingLiveActivityManager()
        let store = TripStore(
            locationClient: location,
            notificationClient: MockNotificationClient(),
            liveActivityManager: activity
        )
        await store.startTrip()
        let request = try #require(store.makeStopConfirmationRequest())

        await store.confirmStop(request)
        await store.confirmStop(request)

        #expect(store.phase == .cancelled)
        #expect(location.didStop)
        #expect(activity.endCount == 1)
    }

    @Test("A stop URL with no active trip does not create a request or mutate state")
    func publicStopURLIsSafeWithoutActiveTrip() throws {
        let location = MockLocationClient()
        let activity = RecordingLiveActivityManager()
        let store = TripStore(
            locationClient: location,
            notificationClient: MockNotificationClient(),
            liveActivityManager: activity
        )
        let url = try #require(URL(string: "napnav://stop-trip"))

        #expect(NapNavDeepLink.stopConfirmationRequest(for: url, store: store) == nil)
        #expect(store.phase == .idle)
        #expect(location.didStop == false)
        #expect(activity.endCount == 0)
    }

    @Test("Live Activity Finish URL confirms completion after arrival")
    func finishURLCompletesOnlyAfterConfirmation() async throws {
        let activity = RecordingLiveActivityManager()
        let store = TripStore(
            locationClient: MockLocationClient(),
            notificationClient: MockNotificationClient(),
            liveActivityManager: activity
        )
        await store.startTrip()
        store.phase = .arrived
        let url = try #require(URL(string: "napnav://stop-trip"))
        let request = try #require(NapNavDeepLink.stopConfirmationRequest(for: url, store: store))

        #expect(request.action == .finish)
        #expect(store.phase == .arrived)

        await store.confirmStop(request)

        #expect(store.phase == .completed)
        #expect(activity.endCount == 1)
    }

    @Test("Quick action stops alarm immediately when alerting")
    func quickActionStopsAlarmWhenAlerting() async throws {
        let location = MockLocationClient()
        let activity = RecordingLiveActivityManager()
        let store = TripStore(
            locationClient: location,
            notificationClient: MockNotificationClient(),
            liveActivityManager: activity
        )
        await store.startTrip()
        store.phase = .alarm
        #expect(store.phase.isActive)

        await store.handleQuickAction()

        #expect(store.phase == .cancelled)
        #expect(location.didStop)
        #expect(activity.endCount == 1)
    }

    @Test("Quick action starts trip to favorite when idle")
    func quickActionStartsFavoriteWhenIdle() async throws {
        let location = MockLocationClient()
        let activity = RecordingLiveActivityManager()
        let store = TripStore(
            locationClient: location,
            notificationClient: MockNotificationClient(),
            liveActivityManager: activity
        )
        store.saveFavorite(
            title: "บ้าน",
            subtitle: "123 ถ.สุขุมวิท",
            coordinate: LocationCoordinate(latitude: 13.75, longitude: 100.50),
            radiusMeters: 800,
            icon: .house
        )
        #expect(store.phase == .idle)
        #expect(store.favorites.count == 1)

        await store.handleQuickAction()

        #expect(store.destination.name == "บ้าน")
        #expect(store.selectedRadiusMeters == 800)
        #expect(store.phase == .tracking)
    }

    @Test("Stop alarm action silences active trip immediately")
    func stopAlarmActionSilencesActiveTrip() async throws {
        let location = MockLocationClient()
        let activity = RecordingLiveActivityManager()
        let store = TripStore(
            locationClient: location,
            notificationClient: MockNotificationClient(),
            liveActivityManager: activity
        )
        await store.startTrip()
        #expect(store.phase == .tracking)

        store.handleStopAlarm()

        #expect(store.phase == .cancelled)
        #expect(location.didStop)
    }

    @Test("Siri start home trip selects home favorite over other favorites")
    func siriStartHomeSelectsHomeFavorite() async throws {
        let store = TripStore(
            locationClient: MockLocationClient(),
            notificationClient: MockNotificationClient()
        )
        store.saveFavorite(
            title: "ที่ทำงาน",
            subtitle: "ออฟฟิศ",
            coordinate: LocationCoordinate(latitude: 13.72, longitude: 100.52),
            radiusMeters: 500,
            icon: .briefcase
        )
        store.saveFavorite(
            title: "บ้าน",
            subtitle: "คอนโด",
            coordinate: LocationCoordinate(latitude: 13.75, longitude: 100.50),
            radiusMeters: 800,
            icon: .house
        )
        await store.startQuickFavoriteTrip(preferringHome: true)
        #expect(store.destination.name == "บ้าน")
        #expect(store.selectedRadiusMeters == 800)
        #expect(store.phase == .tracking)
    }
}

@MainActor
@Suite("Trip store with live samples")
struct TripStoreTests {
    @Test("เลือกจุดหมายใหม่แล้วใช้จุดหมายนั้นในหน้าตั้งค่า")
    func selectingDestinationUpdatesTripSetup() {
        let store = TripStore(
            locationClient: MockLocationClient(),
            notificationClient: MockNotificationClient()
        )
        let destination = Destination(
            id: "new-place",
            name: "จุดหมายใหม่",
            detail: "กรุงเทพมหานคร",
            coordinate: LocationCoordinate(latitude: 13.75, longitude: 100.5)
        )

        store.selectDestination(destination)
        store.useSelectedDestination()

        #expect(store.destination == destination)
        #expect(store.phase == .preparing)
        #expect(store.screen == .setup)
    }

    @Test("GPS สองตำแหน่งในเขตส่งการแจ้งเตือนเพียงครั้งเดียว")
    func consecutiveSamplesTriggerOneNotification() async {
        let location = MockLocationClient()
        let notifications = MockNotificationClient()
        let store = TripStore(locationClient: location, notificationClient: notifications)
        store.destination = Destination(
            id: "test",
            name: "จุดหมายทดสอบ",
            detail: "",
            coordinate: LocationCoordinate(latitude: 0, longitude: 0)
        )
        store.selectedRadiusMeters = 1_000

        await store.startTrip()
        await store.processLocationEvent(.sample(sample(latitude: 0.005)))
        await store.processLocationEvent(.sample(sample(latitude: 0.004)))
        await store.processLocationEvent(.sample(sample(latitude: 0.003)))

        #expect(location.didRequestAuthorization)
        #expect(store.alertSent)
        #expect(store.phase == .alarm)
        #expect(store.arrivalStatus == .outside)
        #expect(notifications.arrivalCount == 1)
    }

    @Test("ระยะเตือนหนึ่งกิโลเมตรไม่ถือว่าถึงจนกว่าจะยืนยันในระยะ 20 เมตร")
    func alertRadiusAndArrivalThresholdAreIndependent() async {
        let location = MockLocationClient()
        let notifications = MockNotificationClient()
        let store = TripStore(locationClient: location, notificationClient: notifications)
        store.destination = Destination(
            id: "separate-thresholds",
            name: "จุดหมายทดสอบ",
            detail: "",
            coordinate: LocationCoordinate(latitude: 0, longitude: 0)
        )
        store.selectedRadiusMeters = 1_000

        await store.startTrip()
        await store.processLocationEvent(.sample(sample(latitude: 0.005)))
        await store.processLocationEvent(.sample(sample(latitude: 0.004)))

        #expect(store.phase == .alarm)
        #expect(store.arrivalStatus == .outside)
        #expect(notifications.arrivalCount == 1)

        await store.processLocationEvent(.sample(sample(latitude: 0.00015)))
        #expect(store.phase == .alarm)
        #expect(store.arrivalStatus == .nearby)

        await store.processLocationEvent(.sample(sample(latitude: 0.00014)))
        #expect(store.phase == .arrived)
        #expect(store.arrivalStatus == .arrived)
        #expect(notifications.arrivalCount == 1)
    }

    @Test("ปิด notification หลังเตือนแล้วยังติดตามตำแหน่งจนถึงจุดหมาย")
    func dismissingAlertKeepsTripActiveUntilArrival() async {
        let location = MockLocationClient()
        let activity = RecordingLiveActivityManager()
        let store = TripStore(
            locationClient: location,
            notificationClient: MockNotificationClient(),
            liveActivityManager: activity
        )
        let delegate = NotificationDelegate()
        delegate.onTripAction = { [weak store] identifier, tripID in
            store?.handleNotificationAction(identifier, tripID: tripID)
        }
        store.destination = Destination(
            id: "dismiss-alert",
            name: "จุดหมายทดสอบ",
            detail: "",
            coordinate: LocationCoordinate(latitude: 0, longitude: 0)
        )
        store.selectedRadiusMeters = 1_000

        await store.startTrip()
        await store.processLocationEvent(.sample(sample(latitude: 0.005)))
        await store.processLocationEvent(.sample(sample(latitude: 0.004)))
        #expect(store.phase == .alarm)

        delegate.handleActionIdentifier(UNNotificationDismissActionIdentifier)
        #expect(store.phase == .alarm)
        #expect(location.didStop == false)
        #expect(activity.endCount == 0)

        await store.processLocationEvent(.sample(sample(latitude: 0.00015)))
        await store.processLocationEvent(.sample(sample(latitude: 0.00014)))
        #expect(store.phase == .arrived)
        #expect(location.didStop)
    }

    @Test("accuracy แย่ในระยะ 20 เมตรแสดงว่าอยู่ใกล้แต่ไม่จบทริป")
    func inaccurateNearbyLocationDoesNotCompleteTrip() async {
        let location = MockLocationClient()
        let store = TripStore(
            locationClient: location,
            notificationClient: MockNotificationClient()
        )
        store.destination = Destination(
            id: "uncertain-arrival",
            name: "จุดหมายทดสอบ",
            detail: "",
            coordinate: LocationCoordinate(latitude: 0, longitude: 0)
        )

        await store.startTrip()
        await store.processLocationEvent(.sample(sample(latitude: 0.00010, accuracy: 35)))

        #expect(store.phase != .arrived)
        #expect(store.arrivalStatus == .nearby)
        #expect(store.health == .reducedAccuracy)
    }

    @Test("หยุดทริปแล้วหยุด location stream และล้างตำแหน่ง")
    func stoppingTripStopsLocationWork() async {
        let location = MockLocationClient()
        let store = TripStore(
            locationClient: location,
            notificationClient: MockNotificationClient()
        )

        await store.startTrip()
        await store.processLocationEvent(.sample(sample(latitude: 0.02)))
        store.stopTrip()

        #expect(location.didStop)
        #expect(store.phase == .cancelled)
        #expect(store.locationStatus == .idle)
        #expect(store.currentDistanceMeters == nil)
    }

    @Test("notification stop action หยุด location และยกเลิก alert ของทริป")
    func stopNotificationActionStopsAndCleansUpTrip() async {
        let location = MockLocationClient()
        let notifications = MockNotificationClient()
        let store = TripStore(
            locationClient: location,
            notificationClient: notifications
        )

        await store.startTrip()
        store.handleNotificationAction(LocalAlarmDelivery.stopActionIdentifier)

        #expect(location.didStop)
        #expect(store.phase == .cancelled)
        #expect(notifications.cancelledDestinationID == store.destination.id)
    }

    @Test("หยุดทริปส่ง AlarmKit identifier ที่ persist ไว้เข้าสู่ cleanup เดียวกัน")
    func stopCancelsPersistedProminentAlarmIdentifier() async {
        let notifications = MockNotificationClient()
        let alarmID = UUID()
        notifications.prominentAlarmIdentifier = alarmID
        notifications.deliveryResult = .alarmScheduled(companionNotificationScheduled: true)
        let liveActivity = RecordingLiveActivityManager()
        let store = TripStore(
            locationClient: MockLocationClient(),
            notificationClient: notifications,
            liveActivityManager: liveActivity
        )
        store.destination = Destination(
            id: "alarm-cleanup",
            name: "จุดหมายทดสอบ",
            detail: "",
            coordinate: LocationCoordinate(latitude: 0, longitude: 0)
        )

        await store.startTrip()
        await store.processLocationEvent(.sample(sample(latitude: 0.005)))
        await store.processLocationEvent(.sample(sample(latitude: 0.004)))
        await store.processLocationEvent(.sample(sample(latitude: 0.003)))
        store.stopTrip()

        #expect(notifications.cancelledProminentAlarmIdentifier == alarmID)
        #expect(notifications.lastCancellationResult.notificationCleanup == .requestsRemoved)
        #expect(notifications.pendingNotificationIdentifiers.isEmpty)
        #expect(notifications.pendingAlarmCancellationIdentifiers.isEmpty)
        #expect(liveActivity.endCount == 1)
    }

    @Test("AlarmKit cancel failure stays observable until reconciliation succeeds")
    func failedAlarmCancellationCanBeRetried() async {
        let notifications = MockNotificationClient()
        let alarmID = UUID()
        notifications.prominentAlarmIdentifier = alarmID
        notifications.deliveryResult = .alarmScheduled(companionNotificationScheduled: false)
        notifications.failedAlarmCancellationIdentifiers = [alarmID]
        let store = TripStore(
            locationClient: MockLocationClient(),
            notificationClient: notifications
        )
        store.destination = Destination(
            id: "alarm-cancel-retry",
            name: "จุดหมายทดสอบ",
            detail: "",
            coordinate: LocationCoordinate(latitude: 0, longitude: 0)
        )

        await store.startTrip()
        await store.processLocationEvent(.sample(sample(latitude: 0.005)))
        await store.processLocationEvent(.sample(sample(latitude: 0.004)))
        await store.processLocationEvent(.sample(sample(latitude: 0.003)))
        store.stopTrip()

        #expect(store.health == .alertCleanupFailed)
        #expect(store.alertCleanupWarning != nil)
        #expect(notifications.pendingAlarmCancellationIdentifiers == [alarmID])

        store.stopTrip()
        #expect(notifications.cancelledProminentAlarmIdentifier == alarmID)
        #expect(notifications.pendingAlarmCancellationIdentifiers == [alarmID])
        #expect(notifications.cancelAttemptCount == 1)

        notifications.failedAlarmCancellationIdentifiers.remove(alarmID)
        let result = store.reconcilePendingAlertCancellations()

        #expect(result.hasFailures == false)
        #expect(notifications.pendingAlarmCancellationIdentifiers.isEmpty)
        #expect(store.alertCleanupWarning == nil)
        #expect(store.health == .ready)
    }

    @Test("launch retries an AlarmKit cancellation that remained pending")
    func launchReconcilesPendingAlarmCancellation() async {
        let notifications = MockNotificationClient()
        let alarmID = UUID()
        notifications.pendingAlarmCancellationIdentifiers = [alarmID]
        notifications.failedAlarmCancellationIdentifiers = [alarmID]
        let store = TripStore(
            locationClient: MockLocationClient(),
            notificationClient: notifications
        )

        await store.prepareForLaunch()

        #expect(store.health == .alertCleanupFailed)
        #expect(store.alertCleanupWarning != nil)
        #expect(notifications.pendingAlarmCancellationIdentifiers == [alarmID])

        notifications.failedAlarmCancellationIdentifiers.remove(alarmID)
        await store.relaunchApp()

        #expect(notifications.pendingAlarmCancellationIdentifiers.isEmpty)
        #expect(store.alertCleanupWarning == nil)
        #expect(store.health == .ready)
    }

    @Test("AlarmKit cancellation failure persists across LocalAlarmDelivery recreation")
    func pendingAlarmCancellationSurvivesRelaunch() {
        let suiteName = "napnav-alarm-cancellation-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let alarmID = UUID()
        let controller = MockProminentAlarmController()
        controller.existingAlarmIdentifiers = [alarmID]
        controller.failedAlarmIdentifiers = [alarmID]
        let firstClient = LocalAlarmDelivery(
            defaults: defaults,
            pendingAlarmCancellationsKey: "pending-cancellations",
            alarmController: controller
        )

        let failedResult = firstClient.cancelTripAlerts(
            destinationID: "relaunch-cancel",
            tripID: alarmID,
            prominentAlarmIdentifier: alarmID
        )

        #expect(failedResult.notificationCleanup == .requestsRemoved)
        #expect(failedResult.hasFailures)
        #expect(firstClient.pendingAlarmCancellationIdentifiers == [alarmID])
        #expect(defaults.stringArray(forKey: "pending-cancellations") == [alarmID.uuidString])

        controller.failedAlarmIdentifiers.remove(alarmID)
        let relaunchedClient = LocalAlarmDelivery(
            defaults: defaults,
            pendingAlarmCancellationsKey: "pending-cancellations",
            alarmController: controller
        )
        let retryResult = relaunchedClient.reconcilePendingTripAlertCancellations()

        #expect(retryResult.alarmKitOutcomes == [.cancelled(alarmID)])
        #expect(relaunchedClient.pendingAlarmCancellationIdentifiers.isEmpty)
        #expect(defaults.stringArray(forKey: "pending-cancellations") == [])
        #expect(controller.existingAlarmIdentifiers.isEmpty)
    }

    @Test("cancelAll persists a full-reconciliation retry when AlarmKit enumeration fails")
    func cancelAllRetriesAfterAlarmEnumerationFailure() async {
        let suiteName = "napnav-alarm-enumeration-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let controller = MockProminentAlarmController()
        controller.shouldFailEnumeration = true
        let firstClient = LocalAlarmDelivery(
            defaults: defaults,
            pendingAlarmCancellationsKey: "pending-cancellations",
            fullAlarmReconciliationRequiredKey: "full-reconcile-required",
            alarmController: controller
        )

        let failedResult = await firstClient.cancelAllTripAlerts()

        #expect(failedResult.hasFailures)
        #expect(failedResult.alarmKitEnumerationFailure != nil)
        #expect(defaults.bool(forKey: "full-reconcile-required"))

        let alarmID = UUID()
        controller.shouldFailEnumeration = false
        controller.existingAlarmIdentifiers = [alarmID]
        let relaunchedClient = LocalAlarmDelivery(
            defaults: defaults,
            pendingAlarmCancellationsKey: "pending-cancellations",
            fullAlarmReconciliationRequiredKey: "full-reconcile-required",
            alarmController: controller
        )
        let retryResult = relaunchedClient.reconcilePendingTripAlertCancellations()

        #expect(retryResult.alarmKitEnumerationCompleted)
        #expect(retryResult.alarmKitOutcomes.contains(.cancelled(alarmID)))
        #expect(defaults.bool(forKey: "full-reconcile-required") == false)
        #expect(relaunchedClient.pendingAlarmCancellationIdentifiers.isEmpty)
        #expect(controller.existingAlarmIdentifiers.isEmpty)
    }

    @Test("unsupported AlarmKit does not treat a notification trip ID as a pending alarm")
    func unsupportedAlarmKitDoesNotQueueNotificationTripID() {
        let suiteName = "napnav-alarm-unsupported-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let controller = MockProminentAlarmController()
        controller.isSupported = false
        let client = LocalAlarmDelivery(
            defaults: defaults,
            pendingAlarmCancellationsKey: "pending-cancellations",
            alarmController: controller
        )
        let tripID = UUID()

        let result = client.cancelTripAlerts(
            destinationID: "notification-only",
            tripID: tripID,
            prominentAlarmIdentifier: nil
        )

        #expect(result.notificationCleanup == .requestsRemoved)
        #expect(result.alarmKitOutcomes.isEmpty)
        #expect(result.hasFailures == false)
        #expect(client.pendingAlarmCancellationIdentifiers.isEmpty)
    }

    @Test("explicit unsupported AlarmKit ID remains queued for a later supported runtime")
    func explicitUnsupportedAlarmIDRemainsRecoverable() {
        let suiteName = "napnav-alarm-upgrade-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let alarmID = UUID()
        let controller = MockProminentAlarmController()
        controller.isSupported = false
        let firstClient = LocalAlarmDelivery(
            defaults: defaults,
            pendingAlarmCancellationsKey: "pending-cancellations",
            alarmController: controller
        )
        let failedResult = firstClient.cancelTripAlerts(
            destinationID: "previously-supported-alarm",
            tripID: nil,
            prominentAlarmIdentifier: alarmID
        )

        #expect(failedResult.alarmKitOutcomes == [.unsupported(alarmID)])
        #expect(defaults.stringArray(forKey: "pending-cancellations") == [alarmID.uuidString])

        controller.isSupported = true
        controller.existingAlarmIdentifiers = [alarmID]
        let relaunchedClient = LocalAlarmDelivery(
            defaults: defaults,
            pendingAlarmCancellationsKey: "pending-cancellations",
            alarmController: controller
        )
        let retryResult = relaunchedClient.reconcilePendingTripAlertCancellations()

        #expect(retryResult.alarmKitOutcomes == [.cancelled(alarmID)])
        #expect(relaunchedClient.pendingAlarmCancellationIdentifiers.isEmpty)
        #expect(controller.existingAlarmIdentifiers.isEmpty)
    }

    @Test("notification snooze action ตั้งเตือนใหม่หนึ่งครั้งโดยไม่ยิง proximity ซ้ำ")
    func snoozeNotificationActionSchedulesOneReminder() async {
        let notifications = MockNotificationClient()
        let store = TripStore(
            locationClient: MockLocationClient(),
            notificationClient: notifications
        )

        await store.startTrip()

        let snoozeTask = store.handleNotificationAction(LocalAlarmDelivery.snoozeActionIdentifier)
        await snoozeTask?.value

        #expect(notifications.snoozeCount == 1)
        #expect(store.phase == .tracking)
    }

    @Test("authorization อย่างเดียวไม่พอ ถ้า alert ถูกปิดต้องถือว่ายังไม่พร้อม")
    func disabledAlertsAreNotReady() async {
        let notifications = MockNotificationClient()
        notifications.currentReadiness = AlarmReadiness(
            permission: .authorized,
            alertsEnabled: false,
            soundsEnabled: true,
            lockScreenEnabled: true,
            timeSensitiveSetting: .enabled
        )
        let store = TripStore(
            locationClient: MockLocationClient(),
            notificationClient: notifications
        )

        await store.startTrip()

        #expect(store.notificationReady == false)
        #expect(store.health == .notificationUnavailable)
    }

    @Test("AlarmKit ที่พร้อมใช้ทดแทน notification ปกติที่ปิดอยู่ได้")
    func prominentAlarmKeepsAlertDeliveryReady() async {
        let notifications = MockNotificationClient()
        notifications.currentReadiness = AlarmReadiness(
            permission: .denied,
            alertsEnabled: false,
            soundsEnabled: false,
            lockScreenEnabled: false,
            timeSensitiveSetting: .disabled
        )
        notifications.prominentAlarmGranted = true
        notifications.prominentAlarmSupported = true
        let location = MockLocationClient()
        let store = TripStore(
            locationClient: location,
            notificationClient: notifications
        )
        var preferences = store.alertPreferences
        preferences.deliveryMode = .alarmKit
        store.updateAlertPreferences(preferences)

        await store.startTrip()

        #expect(store.notificationReady == false)
        #expect(store.prominentAlarmReady)
        #expect(store.health == .ready)
        #expect(store.phase == .tracking)
        #expect(store.showsSettings == false)
        #expect(location.didRequestAuthorization)
        #expect(notifications.didRequestProminentAlarmAuthorization)
        store.stopTrip()
    }

    @Test("Notification ไม่เปิด AlarmKit permission prompt โดยผู้ใช้ไม่ได้เลือก")
    func notificationDoesNotRequestProminentAlarmAuthorization() async {
        let notifications = MockNotificationClient()
        notifications.prominentAlarmSupported = true
        notifications.prominentAlarmGranted = false
        let store = TripStore(
            locationClient: MockLocationClient(),
            notificationClient: notifications
        )

        await store.startTrip()

        #expect(notifications.didRequestProminentAlarmAuthorization == false)
        #expect(store.alertDeliveryPlan.paths == [.notification(sound: .audible)])
    }

    @Test("autoStopDelay = .immediately จบทริปทันทีเมื่อถึงจุดหมาย")
    func autoStopImmediatelyCompletesTrip() async {
        let location = MockLocationClient()
        let persistence = NoopTripPersistence()
        var prefs = UserAlertPreferences()
        prefs.autoStopDelay = .immediately
        persistence.saveAlertPreferences(prefs)

        let store = TripStore(
            locationClient: location,
            notificationClient: MockNotificationClient(),
            persistence: persistence
        )
        store.destination = Destination(
            id: "auto-stop-immediate",
            name: "จุดหมายทดสอบ",
            detail: "",
            coordinate: LocationCoordinate(latitude: 0, longitude: 0)
        )
        store.selectedRadiusMeters = 1_000

        await store.startTrip()

        // เข้า alarm phase ก่อน
        await store.processLocationEvent(.sample(sample(latitude: 0.005)))
        await store.processLocationEvent(.sample(sample(latitude: 0.004)))

        // ส่งตำแหน่งเข้าใกล้ (nearby) แล้วยืนยัน arrived
        await store.processLocationEvent(.sample(sample(latitude: 0.00015)))

        await store.processLocationEvent(.sample(sample(latitude: 0.00014)))

        #expect(store.phase == .completed)
        #expect(location.didStop)
        #expect(store.screen == .destination)
    }

    @Test("autoStopDelay = .fiveSeconds คง arrived ไว้ก่อน แล้วจบอัตโนมัติ")
    func autoStopAfterDelayCompletesTrip() async {
        let location = MockLocationClient()
        let persistence = NoopTripPersistence()
        let clock = TestTripClock(now: Date())
        let backgroundTasks = TestTripBackgroundTaskManager()
        let activity = RecordingLiveActivityManager()
        var prefs = UserAlertPreferences()
        prefs.autoStopDelay = .fiveSeconds
        persistence.saveAlertPreferences(prefs)

        let store = TripStore(
            locationClient: location,
            notificationClient: MockNotificationClient(),
            persistence: persistence,
            liveActivityManager: activity,
            clock: clock,
            backgroundTaskManager: backgroundTasks
        )
        store.destination = Destination(
            id: "auto-stop-delay",
            name: "จุดหมายทดสอบ",
            detail: "",
            coordinate: LocationCoordinate(latitude: 0, longitude: 0)
        )
        store.selectedRadiusMeters = 1_000

        await store.startTrip()

        // เข้า alarm phase
        await store.processLocationEvent(.sample(sample(latitude: 0.005)))
        await store.processLocationEvent(.sample(sample(latitude: 0.004)))

        // ส่งตำแหน่งเข้าใกล้ (nearby) แล้วยืนยัน arrived
        await store.processLocationEvent(.sample(sample(latitude: 0.00015)))

        await store.processLocationEvent(.sample(sample(latitude: 0.00014)))

        // ทันทีหลัง arrived GPS ต้องหยุด แต่ยังไม่จบทริป
        #expect(store.phase == .arrived)
        #expect(location.didStop)
        let deadline = clock.now.addingTimeInterval(5)
        await clock.waitForSleepRequestCount(atLeast: 1)
        clock.advance(to: deadline.addingTimeInterval(-1))
        #expect(store.phase == .arrived)
        #expect(activity.endCount == 0)

        clock.advance(to: deadline)
        await activity.waitForEndCount(atLeast: 1)

        #expect(store.phase == .completed)
        #expect(store.screen == .destination)
        #expect(activity.endCount == 1)
    }

    private func sample(latitude: Double, accuracy: Double = 10) -> LocationSample {
        LocationSample(
            coordinate: LocationCoordinate(latitude: latitude, longitude: 0),
            horizontalAccuracy: accuracy,
            timestamp: Date(),
            speed: 10,
            course: 0
        )
    }
}

@MainActor
private final class MockLocationClient: LocationProviding {
    private var continuation: AsyncStream<LocationEvent>.Continuation?
    var didRequestAuthorization = false
    var didStop = false

    func requestWhenInUseAuthorization() {
        didRequestAuthorization = true
    }

    func startUpdates() -> AsyncStream<LocationEvent> {
        AsyncStream { continuation in
            self.continuation = continuation
        }
    }

    func stopUpdates() {
        didStop = true
        continuation?.finish()
        continuation = nil
    }

    func send(_ event: LocationEvent) {
        continuation?.yield(event)
    }
}

@MainActor
private final class MockNotificationClient: NotificationProviding {
    var arrivalCount = 0
    var snoozeCount = 0
    var onArrival: (() -> Void)?
    var onSnooze: (() -> Void)?
    var cancelledDestinationID: String?
    var cancelledProminentAlarmIdentifier: UUID?
    var pendingNotificationIdentifiers: Set<String> = []
    var lastCancellationResult = AlertCancellationResult()
    var cancelAttemptCount = 0
    var pendingAlarmCancellationIdentifiers: Set<UUID> = []
    var failedAlarmCancellationIdentifiers: Set<UUID> = []
    var prominentAlarmIdentifier: UUID?
    var prominentAlarmGranted = false
    var prominentAlarmSupported = false
    var didRequestProminentAlarmAuthorization = false
    var deliveryResult: AlertDeliveryResult = .notificationScheduled(sound: .audible)
    var currentReadiness = AlarmReadiness(
        permission: .authorized,
        alertsEnabled: true,
        soundsEnabled: true,
        lockScreenEnabled: true,
        timeSensitiveSetting: .enabled
    )

    func authorizationIsGranted() async -> Bool {
        true
    }

    func requestAuthorizationIfNeeded() async -> Bool {
        true
    }

    func readiness() async -> AlarmReadiness {
        currentReadiness
    }

    func prominentAlarmAuthorizationIsGranted() async -> Bool {
        prominentAlarmGranted
    }

    func prominentAlarmsAreSupported() -> Bool {
        prominentAlarmSupported
    }

    func requestProminentAlarmAuthorizationIfAvailable() async -> Bool {
        didRequestProminentAlarmAuthorization = true
        return prominentAlarmGranted
    }

    func sendArrivalAlert(destination: Destination, distanceMeters: Double) async throws {
        arrivalCount += 1
        onArrival?()
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
        arrivalCount += 1
        onArrival?()
        if let tripID,
           case .alarmScheduled(companionNotificationScheduled: true) = deliveryResult {
            pendingNotificationIdentifiers.insert("arrival-\(tripID.uuidString)")
        }
        return deliveryResult
    }

    func currentProminentAlarmIdentifier() -> UUID? {
        prominentAlarmIdentifier
    }

    func prominentAlarmExists(identifier: UUID) -> Bool {
        prominentAlarmIdentifier == identifier
    }

    func sendTestAlert() async throws {}
    func sendProminentAlarmSpike(destination: Destination, after delay: TimeInterval) async throws {}

    func scheduleSnoozeAlert(destination: Destination, after delay: TimeInterval) async throws {
        snoozeCount += 1
        onSnooze?()
    }

    func cancelTripAlerts(
        destinationID: String,
        tripID: UUID?,
        prominentAlarmIdentifier: UUID?
    ) -> AlertCancellationResult {
        cancelAttemptCount += 1
        cancelledDestinationID = destinationID
        cancelledProminentAlarmIdentifier = prominentAlarmIdentifier
        if let tripID {
            pendingNotificationIdentifiers.remove("arrival-\(tripID.uuidString)")
            pendingNotificationIdentifiers.remove("snooze-\(tripID.uuidString)")
        }
        pendingNotificationIdentifiers.remove("arrival-\(destinationID)")
        pendingNotificationIdentifiers.remove("snooze-\(destinationID)")
        guard let alarmID = prominentAlarmIdentifier ?? tripID ?? self.prominentAlarmIdentifier else {
            let result = AlertCancellationResult(notificationCleanup: .requestsRemoved)
            lastCancellationResult = result
            return result
        }
        if failedAlarmCancellationIdentifiers.contains(alarmID) {
            pendingAlarmCancellationIdentifiers.insert(alarmID)
            let result = AlertCancellationResult(
                notificationCleanup: .requestsRemoved,
                alarmKitOutcomes: [.failed(alarmID, reason: "test cancellation failure")]
            )
            lastCancellationResult = result
            return result
        }
        pendingAlarmCancellationIdentifiers.remove(alarmID)
        let result = AlertCancellationResult(
            notificationCleanup: .requestsRemoved,
            alarmKitOutcomes: [.cancelled(alarmID)]
        )
        lastCancellationResult = result
        return result
    }

    func reconcilePendingTripAlertCancellations() -> AlertCancellationResult {
        let alarmIDs = Array(pendingAlarmCancellationIdentifiers)
        let outcomes = alarmIDs.map { alarmID in
            if failedAlarmCancellationIdentifiers.contains(alarmID) {
                return AlarmKitCancellationOutcome.failed(
                    alarmID,
                    reason: "test cancellation failure"
                )
            }
            pendingAlarmCancellationIdentifiers.remove(alarmID)
            return .cancelled(alarmID)
        }
        return AlertCancellationResult(alarmKitOutcomes: outcomes)
    }

    func cancelAllTripAlerts() async -> AlertCancellationResult {
        pendingNotificationIdentifiers.removeAll()
        let alarmIDs = Array(pendingAlarmCancellationIdentifiers)
        let outcomes = alarmIDs.map { alarmID in
            if failedAlarmCancellationIdentifiers.contains(alarmID) {
                return AlarmKitCancellationOutcome.failed(
                    alarmID,
                    reason: "test cancellation failure"
                )
            }
            pendingAlarmCancellationIdentifiers.remove(alarmID)
            return .cancelled(alarmID)
        }
        return AlertCancellationResult(
            notificationCleanup: .requestsRemoved,
            alarmKitOutcomes: outcomes
        )
    }
}

@MainActor
private final class MockProminentAlarmController: ProminentAlarmControlling {
    var isSupported = true
    var existingAlarmIdentifiers: Set<UUID> = []
    var failedAlarmIdentifiers: Set<UUID> = []
    var shouldFailEnumeration = false

    func alarmIdentifiers() throws -> Set<UUID> {
        if shouldFailEnumeration { throw TestAlarmCancellationError.enumerationFailed }
        return existingAlarmIdentifiers
    }

    func cancelAlarm(identifier: UUID) throws {
        if failedAlarmIdentifiers.contains(identifier) {
            throw TestAlarmCancellationError.failed
        }
        existingAlarmIdentifiers.remove(identifier)
    }
}

@MainActor
private final class RecordingLiveActivityManager: LiveActivityManaging {
    private(set) var endCount = 0
    private var endWaiters: [(Int, CheckedContinuation<Void, Never>)] = []

    func startTripActivity(destination: Destination, initialDistance: Double, alertRadius: Double) {}
    func updateTripActivity(
        remainingDistance: Double,
        isAlertTriggered: Bool,
        isArrived: Bool,
        autoStopAt: Date?
    ) {}
    func updateTripActivity(
        remainingDistance: Double,
        initialDistance: Double?,
        languageCode: String?,
        isAlertTriggered: Bool,
        isArrived: Bool,
        autoStopAt: Date?
    ) {}
    func endTripActivity(wasArrived: Bool) {
        endCount += 1
        let ready = endWaiters.filter { endCount >= $0.0 }
        endWaiters.removeAll { endCount >= $0.0 }
        ready.forEach { $0.1.resume() }
    }
    func endAllTripActivities() async {}

    func waitForEndCount(atLeast target: Int) async {
        guard endCount < target else { return }
        await withCheckedContinuation { endWaiters.append((target, $0)) }
    }
}

private enum TestAlarmCancellationError: Error {
    case failed
    case enumerationFailed
}
