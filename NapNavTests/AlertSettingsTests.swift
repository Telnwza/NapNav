import Foundation
import Testing
import UserNotifications
@testable import NapNav

@MainActor
@Suite("Alert settings and preferences")
struct AlertSettingsTests {
    @Test("Onboarding permission requests finish after denial without starting a trip")
    func onboardingDenialReturnsToCaller() async {
        let location = MockLocation()
        let notifications = MockAlertDelivery()
        notifications.prominentAlarmSupported = true
        notifications.notificationAuthorizationGranted = false
        notifications.readinessValue = AlarmReadiness(
            permission: .denied,
            alertsEnabled: false,
            soundsEnabled: false,
            lockScreenEnabled: false,
            timeSensitiveSetting: .disabled
        )
        let store = TripStore(
            locationClient: location,
            notificationClient: notifications,
            persistence: NoopTripPersistence()
        )
        let initialPhase = store.phase
        await store.refreshReadiness()

        await store.requestOnboardingPermissions()

        #expect(location.authorizationRequestCount == 1)
        #expect(notifications.notificationAuthorizationRequestCount == 1)
        #expect(notifications.alarmAuthorizationRequestCount == 1)
        #expect(!store.prominentAlarmReady)
        #expect(store.alarmReadiness.permission == .denied)
        #expect(!store.alertDeliveryReady)
        #expect(store.phase == initialPhase)
        #expect(location.startUpdatesCount == 0)
    }

    @Test("Time Sensitive readiness preserves unsupported system state")
    func mapsTimeSensitiveSystemSetting() {
        #expect(LocalAlarmDelivery.timeSensitiveSetting(from: .enabled) == .enabled)
        #expect(LocalAlarmDelivery.timeSensitiveSetting(from: .disabled) == .disabled)
        #expect(LocalAlarmDelivery.timeSensitiveSetting(from: .notSupported) == .notSupported)
    }

    @Test("ค่าเริ่มต้นของการตั้งค่าการเตือนถูกต้อง")
    func defaultPreferencesAreCorrect() {
        let prefs = UserAlertPreferences.default
        #expect(prefs.deliveryMode == .both)
        #expect(prefs.soundMode == .soundAndHaptic)
        #expect(prefs.autoStopDelay == .sixtySeconds)
    }

    @Test("UserDefaultsTripPersistence บันทึกและโหลดการตั้งค่าได้ถูกต้อง")
    func persistenceSavesAndLoadsPreferences() {
        let userDefaultsSuite = "test.napnav.settings.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: userDefaultsSuite)!
        defer { defaults.removePersistentDomain(forName: userDefaultsSuite) }

        let persistence = UserDefaultsTripPersistence(
            defaults: defaults,
            key: "test-trip",
            preferencesKey: "test-preferences"
        )

        var custom = UserAlertPreferences()
        custom.deliveryMode = .alarmKit
        custom.soundMode = .soundAndHaptic
        custom.autoStopDelay = .tenSeconds

        persistence.saveAlertPreferences(custom)
        let loaded = persistence.loadAlertPreferences()

        #expect(loaded.deliveryMode == .alarmKit)
        #expect(loaded.soundMode == .soundAndHaptic)
        #expect(loaded.autoStopDelay == .tenSeconds)
    }

    @Test("TripStore อัปเดตการตั้งค่าและบันทึกลง Persistence")
    func tripStoreUpdatesAndPersistsPreferences() {
        let persistence = NoopTripPersistence()
        let store = TripStore(persistence: persistence)

        #expect(store.alertPreferences.deliveryMode == .both)
        #expect(store.alertPreferences.autoStopDelay == .sixtySeconds)

        var newPrefs = UserAlertPreferences()
        newPrefs.deliveryMode = .notification
        newPrefs.soundMode = .soundAndHaptic
        newPrefs.autoStopDelay = .fortyFiveSeconds

        store.updateAlertPreferences(newPrefs)

        #expect(store.alertPreferences.deliveryMode == .notification)
        #expect(store.alertPreferences.soundMode == .soundAndHaptic)
        #expect(store.alertPreferences.autoStopDelay == .fortyFiveSeconds)
        #expect(persistence.loadAlertPreferences().deliveryMode == .notification)
        #expect(persistence.loadAlertPreferences().soundMode == .soundAndHaptic)
        #expect(persistence.loadAlertPreferences().autoStopDelay == .fortyFiveSeconds)
    }

    @Test("policy ครบทุกคู่ Delivery Mode × Sound Mode บน iOS ที่ AlarmKit พร้อม")
    func deliveryAndSoundBehaviorMatrix() {
        let capabilities = AlertDeliveryCapabilities(
            notificationReady: true,
            notificationSoundsEnabled: true,
            alarmKitSupported: true,
            alarmKitAuthorized: true
        )
        let cases: [(AlertDeliveryMode, AlertSoundMode, AlertDeliveryPlan)] = [
            (.notification, .soundAndHaptic, AlertDeliveryPlan(
                paths: [.notification(sound: .audible)], fallbackReason: nil, unavailableReason: nil
            )),
            (.alarmKit, .soundAndHaptic, AlertDeliveryPlan(
                paths: [.alarmKit], fallbackReason: nil, unavailableReason: nil
            )),
            (.both, .soundAndHaptic, AlertDeliveryPlan(
                paths: [.alarmKit, .notification(sound: .silentCompanion)],
                fallbackReason: nil,
                unavailableReason: nil
            ))
        ]

        for (deliveryMode, soundMode, expected) in cases {
            let preferences = UserAlertPreferences(
                deliveryMode: deliveryMode,
                soundMode: soundMode
            )
            let plan = AlertDeliveryPolicy.plan(
                preferences: preferences,
                capabilities: capabilities
            )
            #expect(plan == expected, "Unexpected plan for \(deliveryMode.rawValue) × \(soundMode.rawValue)")
        }
    }

    @Test("iOS 18–25 ใช้ Notification fallback เมื่อเลือก AlarmKit หรือ Both")
    func legacyOSUsesNotificationFallback() {
        let capabilities = AlertDeliveryCapabilities(
            notificationReady: true,
            notificationSoundsEnabled: true,
            alarmKitSupported: false,
            alarmKitAuthorized: false
        )

        for mode in [AlertDeliveryMode.alarmKit, .both] {
            let plan = AlertDeliveryPolicy.plan(
                preferences: UserAlertPreferences(deliveryMode: mode),
                capabilities: capabilities
            )
            #expect(plan.paths == [.notification(sound: .audible)])
            #expect(plan.fallbackReason == .alarmKitUnsupported)
            #expect(plan.isAvailable)
        }
    }

    @Test("AlarmKit ไม่ได้รับอนุญาตแล้ว fallback เป็น Notification อย่างเปิดเผย")
    func alarmKitDeniedUsesVisibleFallback() {
        let plan = AlertDeliveryPolicy.plan(
            preferences: UserAlertPreferences(deliveryMode: .alarmKit),
            capabilities: AlertDeliveryCapabilities(
                notificationReady: true,
                notificationSoundsEnabled: true,
                alarmKitSupported: true,
                alarmKitAuthorized: false
            )
        )

        #expect(plan.paths == [.notification(sound: .audible)])
        #expect(plan.fallbackReason == .alarmKitNotAuthorized)
        #expect(plan.summary.contains(AlertDeliveryFallbackReason.alarmKitNotAuthorized.summary))
    }

    @Test("Both ใช้ Notification เงียบเป็น companion จึงไม่มีเสียงซ้อน")
    func bothUsesSilentCompanion() {
        let plan = AlertDeliveryPolicy.plan(
            preferences: UserAlertPreferences(deliveryMode: .both),
            capabilities: AlertDeliveryCapabilities(
                notificationReady: true,
                notificationSoundsEnabled: true,
                alarmKitSupported: true,
                alarmKitAuthorized: true
            )
        )

        #expect(plan.paths == [.alarmKit, .notification(sound: .silentCompanion)])
        #expect(plan.paths.contains(.notification(sound: .audible)) == false)
    }

    @Test("Both ยังพร้อมผ่าน AlarmKit เมื่อ Notification ปิด และรายงาน fallback")
    func bothUsesAlarmOnlyWhenNotificationIsUnavailable() {
        let plan = AlertDeliveryPolicy.plan(
            preferences: UserAlertPreferences(deliveryMode: .both),
            capabilities: AlertDeliveryCapabilities(
                notificationReady: false,
                notificationSoundsEnabled: false,
                alarmKitSupported: true,
                alarmKitAuthorized: true
            )
        )

        #expect(plan.paths == [.alarmKit])
        #expect(plan.fallbackReason == .notificationUnavailable)
        #expect(plan.isAvailable)
    }

    @Test("ปิดเสียง Notification แล้ว policy รายงาน muted by system")
    func disabledNotificationSoundIsReported() {
        let plan = AlertDeliveryPolicy.plan(
            preferences: UserAlertPreferences(deliveryMode: .notification),
            capabilities: AlertDeliveryCapabilities(
                notificationReady: true,
                notificationSoundsEnabled: false,
                alarmKitSupported: false,
                alarmKitAuthorized: false
            )
        )

        #expect(plan.paths == [.notification(sound: .mutedBySystem)])
        #expect(plan.summary.contains(NotificationSoundBehavior.mutedBySystem.summary))
    }

    @Test("ทุก delivery/sound mode unavailable เมื่อไม่มี Notification และ AlarmKit")
    func everyPreferenceIsUnavailableWithoutAnyDeliveryPath() {
        let capabilities = AlertDeliveryCapabilities(
            notificationReady: false,
            notificationSoundsEnabled: false,
            alarmKitSupported: false,
            alarmKitAuthorized: false
        )
        let cases: [(AlertDeliveryMode, AlertSoundMode, AlertDeliveryUnavailableReason)] = [
            (.notification, .soundAndHaptic, .notificationUnavailable),
            (.alarmKit, .soundAndHaptic, .noAvailablePath),
            (.both, .soundAndHaptic, .noAvailablePath)
        ]

        for (deliveryMode, soundMode, expectedReason) in cases {
            let plan = AlertDeliveryPolicy.plan(
                preferences: UserAlertPreferences(deliveryMode: deliveryMode, soundMode: soundMode),
                capabilities: capabilities
            )
            #expect(plan.paths.isEmpty, "Unexpected path for \(deliveryMode.rawValue) × \(soundMode.rawValue)")
            #expect(plan.isAvailable == false, "Unexpected availability for \(deliveryMode.rawValue) × \(soundMode.rawValue)")
            #expect(plan.unavailableReason == expectedReason)
        }
    }

    @Test("fallback ไป Notification ที่ระบบปิดเสียงต้องบอกผู้ใช้ว่าเสียงถูกปิด")
    func mutedNotificationFallbackExplainsSystemMutedSound() {
        let result = AlertDeliveryResult.fallbackUsed(
            from: .alarmKit,
            to: .notification(sound: .mutedBySystem),
            reason: .alarmSchedulingFailed
        )

        #expect(result.summary.contains(AlertDeliveryFallbackReason.alarmSchedulingFailed.summary))
        #expect(result.summary.contains(NotificationSoundBehavior.mutedBySystem.summary))
    }

    @Test("Trip Alarm ไม่เริ่มและเปิด Alert Settings เมื่อไม่มี alert path")
    func startTripIsBlockedWhenNoAlertPathIsAvailable() async {
        let location = MockLocation()
        let notifications = MockAlertDelivery()
        notifications.readinessValue = AlarmReadiness(
            permission: .denied,
            alertsEnabled: false,
            soundsEnabled: false,
            lockScreenEnabled: false,
            timeSensitiveSetting: .disabled
        )
        let activity = MockLiveActivityManager()
        let store = TripStore(
            locationClient: location,
            notificationClient: notifications,
            persistence: NoopTripPersistence(),
            liveActivityManager: activity
        )
        store.useSelectedDestination()

        await store.startTrip()

        #expect(store.phase == .preparing)
        #expect(store.screen == .setup)
        #expect(store.health == .notificationUnavailable)
        #expect(store.alertDeliveryReady == false)
        #expect(store.showsSettings)
        #expect(store.locationStatus == .idle)
        #expect(location.authorizationRequestCount == 0)
        #expect(location.startUpdatesCount == 0)
        #expect(activity.startCount == 0)
        #expect(notifications.arrivalCount == 0)
        #expect(store.isStartingTrip == false)

        notifications.readinessValue = AlarmReadiness(
            permission: .authorized,
            alertsEnabled: true,
            soundsEnabled: true,
            lockScreenEnabled: true,
            timeSensitiveSetting: .enabled
        )
        store.showsSettings = false
        await store.startTrip()

        #expect(store.phase == .tracking)
        #expect(store.health == .ready)
        #expect(location.authorizationRequestCount == 1)
        #expect(location.startUpdatesCount == 1)
        #expect(activity.startCount == 1)
        store.stopTrip()
    }

    @Test("fallback failure ไม่ถูกนับว่า alert ส่งสำเร็จ")
    func unavailableDeliveryDoesNotMarkAlertAsSent() async {
        let notifications = MockAlertDelivery()
        notifications.deliveryResult = .deliveryUnavailable(reason: .notificationSchedulingFailed)
        let store = TripStore(
            locationClient: MockLocation(),
            notificationClient: notifications,
            persistence: NoopTripPersistence()
        )
        store.destination = Destination(
            id: "delivery-failure",
            name: "จุดหมายทดสอบ",
            detail: "",
            coordinate: LocationCoordinate(latitude: 0, longitude: 0)
        )
        store.selectedRadiusMeters = 1_000

        await store.startTrip()
        await store.processLocationEvent(.sample(sample(latitude: 0.005)))
        await store.processLocationEvent(.sample(sample(latitude: 0.004)))

        #expect(store.alertSent == false)
        #expect(store.health == .notificationUnavailable)
        #expect(store.lastAlertDeliveryResult == .deliveryUnavailable(reason: .notificationSchedulingFailed))
    }

    @Test("ส่งไม่สำเร็จลองใหม่หลัง cooldown แล้วบันทึกเมื่อส่งสำเร็จ")
    func failedDeliveryRetriesAfterCooldown() async {
        let notifications = MockAlertDelivery()
        notifications.deliveryResults = [
            .deliveryUnavailable(reason: .notificationSchedulingFailed),
            .deliveryUnavailable(reason: .notificationSchedulingFailed),
            .deliveryUnavailable(reason: .notificationSchedulingFailed),
            .deliveryUnavailable(reason: .notificationSchedulingFailed),
            .deliveryUnavailable(reason: .notificationSchedulingFailed),
            .notificationScheduled(sound: .audible)
        ]
        let store = makeTrackingStore(notifications: notifications)
        let start = Date()
        await store.startTrip()

        await sendInsideSamples(to: store, startingAt: start)
        #expect(notifications.arrivalCount == 1)
        #expect(store.alertSent == false)

        let cooldownChecks: [(Date, Int)] = [
            (start.addingTimeInterval(10), 1),
            (start.addingTimeInterval(11), 2),
            (start.addingTimeInterval(30), 2),
            (start.addingTimeInterval(31), 3),
            (start.addingTimeInterval(70), 3),
            (start.addingTimeInterval(71), 4),
            (start.addingTimeInterval(130), 4),
            (start.addingTimeInterval(131), 5),
            (start.addingTimeInterval(190), 5),
            (start.addingTimeInterval(191), 6)
        ]

        for (sampleAt, expectedAttemptCount) in cooldownChecks {
            await store.processLocationEvent(
                .sample(sample(latitude: 0.004, timestamp: sampleAt)),
                at: sampleAt
            )
            #expect(notifications.arrivalCount == expectedAttemptCount)
            #expect(store.alertSent == (expectedAttemptCount == 6))
        }

        #expect(store.alertSent)
        #expect(store.lastAlertDeliveryResult == .notificationScheduled(sound: .audible))
    }

    @Test("ส่งสำเร็จแล้วตัวอย่างในเขตที่ตามมาไม่ส่ง alert ซ้ำในทริปเดิม")
    func successfulDeliveryIsOnePerTrip() async {
        let notifications = MockAlertDelivery()
        let store = makeTrackingStore(notifications: notifications)
        let start = Date()
        await store.startTrip()
        await sendInsideSamples(to: store, startingAt: start)

        #expect(store.alertSent)
        #expect(notifications.arrivalCount == 1)

        for offset in [2.0, 3.0] {
            let sampleAt = start.addingTimeInterval(offset)
            await store.processLocationEvent(
                .sample(sample(latitude: 0.004, timestamp: sampleAt)),
                at: sampleAt
            )
        }

        #expect(store.alertSent)
        #expect(notifications.arrivalCount == 1)
    }

    @Test("หยุดทริปแล้ว location sample ที่ตามมาไม่เริ่ม retry ใหม่")
    func stoppedTripDoesNotRetryFailedDelivery() async {
        let notifications = MockAlertDelivery()
        notifications.deliveryResult = .deliveryUnavailable(reason: .notificationSchedulingFailed)
        let store = makeTrackingStore(notifications: notifications)
        let start = Date()
        await store.startTrip()
        await sendInsideSamples(to: store, startingAt: start)

        #expect(notifications.arrivalCount == 1)
        store.stopTrip()

        let sampleAt = start.addingTimeInterval(20)
        await store.processLocationEvent(
            .sample(sample(latitude: 0.004, timestamp: sampleAt)),
            at: sampleAt
        )

        #expect(store.phase == .cancelled)
        #expect(notifications.arrivalCount == 1)
    }

    @Test("เมื่อ readiness กลับมาระหว่างอยู่ในเขต สามารถส่ง alert ได้")
    func restoredReadinessRetriesWhileInside() async {
        let notifications = MockAlertDelivery()
        let store = makeTrackingStore(notifications: notifications)
        let start = Date()
        await store.startTrip()

        #expect(store.phase == .tracking)
        notifications.readinessValue = .init(
            permission: .denied,
            alertsEnabled: false,
            soundsEnabled: false,
            lockScreenEnabled: false,
            timeSensitiveSetting: .disabled
        )
        await sendInsideSamples(to: store, startingAt: start)

        #expect(notifications.arrivalCount == 0)
        #expect(store.alertSent == false)
        #expect(store.lastAlertDeliveryResult == .deliveryUnavailable(reason: .noAvailablePath))

        notifications.readinessValue = .init(
            permission: .authorized,
            alertsEnabled: true,
            soundsEnabled: true,
            lockScreenEnabled: true,
            timeSensitiveSetting: .enabled
        )
        let retryAt = start.addingTimeInterval(11)
        await store.processLocationEvent(
            .sample(sample(latitude: 0.004, timestamp: retryAt)),
            at: retryAt
        )
        await store.processLocationEvent(
            .sample(sample(latitude: 0.004, timestamp: retryAt.addingTimeInterval(1))),
            at: retryAt.addingTimeInterval(1)
        )

        #expect(notifications.arrivalCount == 1)
        #expect(store.alertSent)
    }

    @Test("sample เพิ่มระหว่าง send ค้างอยู่ไม่สร้าง delivery ซ้ำ")
    func concurrentInsideSamplesShareOneInFlightDelivery() async {
        let notifications = MockAlertDelivery()
        notifications.suspendNextArrival = true
        let store = makeTrackingStore(notifications: notifications)
        let start = Date()
        await store.startTrip()
        await store.processLocationEvent(
            .sample(sample(latitude: 0.005, timestamp: start)),
            at: start
        )

        let sendTask = Task {
            await store.processLocationEvent(
                .sample(sample(latitude: 0.004, timestamp: start.addingTimeInterval(1))),
                at: start.addingTimeInterval(1)
            )
        }
        await notifications.waitForArrivalStart()
        let nextSampleAt = start.addingTimeInterval(2)
        await store.processLocationEvent(
            .sample(sample(latitude: 0.004, timestamp: nextSampleAt)),
            at: nextSampleAt
        )

        #expect(notifications.arrivalCount == 1)
        notifications.completePendingArrival(with: .notificationScheduled(sound: .audible))
        await sendTask.value

        #expect(store.alertSent)
        #expect(notifications.arrivalCount == 1)
    }

    @Test("location sample ที่ stale หรือ inaccurate ไม่เป็นเหตุให้ retry")
    func rejectedSamplesDoNotRetryFailedDelivery() async {
        let notifications = MockAlertDelivery()
        notifications.deliveryResult = .deliveryUnavailable(reason: .notificationSchedulingFailed)
        let store = makeTrackingStore(notifications: notifications)
        let start = Date()
        await store.startTrip()
        await sendInsideSamples(to: store, startingAt: start)

        let cooldownPassed = start.addingTimeInterval(12)
        await store.processLocationEvent(
            .sample(sample(
                latitude: 0.004,
                timestamp: cooldownPassed,
                accuracy: 150
            )),
            at: cooldownPassed
        )
        let staleAt = cooldownPassed.addingTimeInterval(1)
        await store.processLocationEvent(
            .sample(sample(
                latitude: 0.004,
                timestamp: staleAt.addingTimeInterval(-16)
            )),
            at: staleAt
        )

        #expect(notifications.arrivalCount == 1)
        #expect(store.alertSent == false)
    }

    @Test("การออกนอกเขตและกลับเข้าเขตไม่ส่ง alert ซ้ำหลังส่งสำเร็จ")
    func leavingAndReenteringDoesNotRedeliverAfterSuccess() async {
        let notifications = MockAlertDelivery()
        let store = makeTrackingStore(notifications: notifications)
        let start = Date()
        await store.startTrip()
        await sendInsideSamples(to: store, startingAt: start)
        #expect(store.alertSent)
        #expect(notifications.arrivalCount == 1)

        let outsideAt = start.addingTimeInterval(2)
        await store.processLocationEvent(
            .sample(sample(latitude: 0.02, timestamp: outsideAt)),
            at: outsideAt
        )
        let reenteredAt = start.addingTimeInterval(3)
        await store.processLocationEvent(
            .sample(sample(latitude: 0.004, timestamp: reenteredAt)),
            at: reenteredAt
        )

        #expect(notifications.arrivalCount == 1)
        #expect(store.alertSent)
    }

    @Test("เครื่องที่ไม่รองรับ AlarmKit ซ่อนโหมด AlarmKit และ Both")
    func unsupportedModesAreHidden() async {
        let notifications = MockAlertDelivery()
        notifications.prominentAlarmSupported = false
        let store = TripStore(
            locationClient: MockLocation(),
            notificationClient: notifications,
            persistence: NoopTripPersistence()
        )

        await store.refreshReadiness()

        #expect(store.availableDeliveryModes == [.notification])
    }

    @Test("TripStore ส่งการแจ้งเตือนพร้อม preferences เมื่อเข้าเงื่อนไข trigger")
    func tripStorePassesPreferencesToAlertDelivery() async {
        let location = MockLocation()
        let notifications = MockAlertDelivery()
        let persistence = NoopTripPersistence()
        let store = TripStore(
            locationClient: location,
            notificationClient: notifications,
            persistence: persistence
        )

        var customPrefs = UserAlertPreferences()
        customPrefs.deliveryMode = .notification
        customPrefs.soundMode = .soundAndHaptic
        store.updateAlertPreferences(customPrefs)

        store.destination = Destination(
            id: "test-dest",
            name: "จุดหมายทดสอบ",
            detail: "",
            coordinate: LocationCoordinate(latitude: 0, longitude: 0)
        )
        store.selectedRadiusMeters = 1_000

        await store.startTrip()
        await store.processLocationEvent(.sample(sample(latitude: 0.005)))
        await store.processLocationEvent(.sample(sample(latitude: 0.004)))

        #expect(notifications.arrivalCount == 1)
        #expect(notifications.lastPreferences?.deliveryMode == .notification)
        #expect(notifications.lastPreferences?.soundMode == .soundAndHaptic)
    }

    @Test("sendTestNotification ส่งการแจ้งเตือนแบบหน่วงเวลาและอัปเดตข้อความ")
    func sendTestNotificationWithDelay() async {
        let notifications = MockAlertDelivery()
        let store = TripStore(
            locationClient: MockLocation(),
            notificationClient: notifications,
            persistence: NoopTripPersistence()
        )

        await store.sendTestNotification(after: 5)
        #expect(notifications.testAlertCount == 1)
        #expect(notifications.lastTestAlertDelay == 5)
        #expect(
            store.testNotificationMessage
                == AppLocalization.format(
                    "ตั้งเวลาแจ้งเตือนในอีก %d วินาที (ล็อกหน้าจอรอได้เลย)",
                    5
                )
        )
    }

    @Test("sendTestApproachingNotification และ sendTestArrivalNotification ส่งการแจ้งเตือนตามระยะ")
    func testSendDeveloperAlerts() async {
        let notifications = MockAlertDelivery()
        let store = TripStore(
            locationClient: MockLocation(),
            notificationClient: notifications,
            persistence: NoopTripPersistence()
        )

        await store.sendTestApproachingNotification()
        #expect(notifications.arrivalCount == 1)
        #expect(
            store.testNotificationMessage?.contains(AppLocalization.format("%d ม.", 500)) == true
        )

        await store.sendTestArrivalNotification()
        #expect(notifications.arrivalCount == 2)
        #expect(
            store.testNotificationMessage?.contains(AppLocalization.format("%d ม.", 20)) == true
        )
    }

    @Test("startTripActivitySimulation และ stopTripActivitySimulation ควบคุม Live Activity ได้ถูกต้อง")
    func testLiveActivitySimulation() {
        let mockActivity = MockLiveActivityManager()
        let store = TripStore(
            locationClient: MockLocation(),
            notificationClient: MockAlertDelivery(),
            persistence: NoopTripPersistence(),
            liveActivityManager: mockActivity
        )

        store.startTripActivitySimulation(phase: .approaching)
        #expect(mockActivity.startCount == 1)
        #expect(mockActivity.updateCount == 1)
        #expect(mockActivity.lastRemainingDistance == 450)
        #expect(mockActivity.lastIsArrived == false)
        #expect(
            store.testNotificationMessage?.localizedCaseInsensitiveContains(AppLocalization.string("ใกล้ถึง")) == true
        )

        store.startTripActivitySimulation(phase: .arrived)
        #expect(mockActivity.lastRemainingDistance == 0)
        #expect(mockActivity.lastIsArrived == true)
        #expect(mockActivity.lastAutoStopAt != nil)
        #expect(
            store.testNotificationMessage?.localizedCaseInsensitiveContains(AppLocalization.string("ถึงแล้ว")) == true
        )

        store.stopTripActivitySimulation()
        #expect(mockActivity.endCount == 1)
        #expect(
            store.testNotificationMessage?.contains(AppLocalization.string("ปิด Live Activity จำลองแล้ว")) == true
        )
    }

    private func makeTrackingStore(notifications: MockAlertDelivery) -> TripStore {
        let store = TripStore(
            locationClient: MockLocation(),
            notificationClient: notifications,
            persistence: NoopTripPersistence()
        )
        store.destination = Destination(
            id: "retry-test",
            name: "จุดหมายทดสอบ",
            detail: "",
            coordinate: LocationCoordinate(latitude: 0, longitude: 0)
        )
        store.selectedRadiusMeters = 1_000
        return store
    }

    private func sendInsideSamples(to store: TripStore, startingAt start: Date) async {
        await store.processLocationEvent(
            .sample(sample(latitude: 0.005, timestamp: start)),
            at: start
        )
        let triggerAt = start.addingTimeInterval(1)
        await store.processLocationEvent(
            .sample(sample(latitude: 0.004, timestamp: triggerAt)),
            at: triggerAt
        )
    }

    private func sample(
        latitude: Double,
        timestamp: Date = Date(),
        accuracy: Double = 10
    ) -> LocationSample {
        LocationSample(
            coordinate: LocationCoordinate(latitude: latitude, longitude: 0),
            horizontalAccuracy: accuracy,
            timestamp: timestamp,
            speed: 5,
            course: 0
        )
    }
}

@MainActor
private final class MockLocation: LocationProviding {
    private var continuation: AsyncStream<LocationEvent>.Continuation?
    var authorizationRequestCount = 0
    var startUpdatesCount = 0

    func requestWhenInUseAuthorization() {
        authorizationRequestCount += 1
    }

    func startUpdates() -> AsyncStream<LocationEvent> {
        startUpdatesCount += 1
        return AsyncStream { continuation in
            self.continuation = continuation
        }
    }

    func stopUpdates() {
        continuation?.finish()
        continuation = nil
    }

    func send(_ event: LocationEvent) {
        continuation?.yield(event)
    }
}

@MainActor
private final class MockAlertDelivery: NotificationProviding {
    var notificationAuthorizationGranted = true
    var notificationAuthorizationRequestCount = 0
    var alarmAuthorizationRequestCount = 0
    var arrivalCount = 0
    var testAlertCount = 0
    var lastTestAlertDelay: TimeInterval?
    var lastPreferences: UserAlertPreferences?
    var prominentAlarmGranted = false
    var prominentAlarmSupported = false
    var deliveryResult: AlertDeliveryResult = .notificationScheduled(sound: .audible)
    var deliveryResults: [AlertDeliveryResult] = []
    var readinessValue = AlarmReadiness(
        permission: .authorized,
        alertsEnabled: true,
        soundsEnabled: true,
        lockScreenEnabled: true,
        timeSensitiveSetting: .enabled
    )
    var suspendNextArrival = false
    private var pendingArrivalContinuation: CheckedContinuation<AlertDeliveryResult, Never>?
    private var arrivalStartContinuation: CheckedContinuation<Void, Never>?

    func authorizationIsGranted() async -> Bool { true }
    func requestAuthorizationIfNeeded() async -> Bool {
        notificationAuthorizationRequestCount += 1
        return notificationAuthorizationGranted
    }
    func prominentAlarmsAreSupported() -> Bool { prominentAlarmSupported }
    func prominentAlarmAuthorizationIsGranted() async -> Bool { prominentAlarmGranted }
    func requestProminentAlarmAuthorizationIfAvailable() async -> Bool {
        alarmAuthorizationRequestCount += 1
        return prominentAlarmGranted
    }

    func readiness() async -> AlarmReadiness {
        readinessValue
    }

    func deliveryCapabilities() async -> AlertDeliveryCapabilities {
        AlertDeliveryCapabilities(
            notificationReady: readinessValue.canDeliverVisibleAlert,
            notificationSoundsEnabled: readinessValue.soundsEnabled,
            alarmKitSupported: prominentAlarmSupported,
            alarmKitAuthorized: prominentAlarmGranted
        )
    }

    func sendArrivalAlert(destination: Destination, distanceMeters: Double) async throws {
        arrivalCount += 1
    }

    func sendArrivalAlert(
        destination: Destination,
        distanceMeters: Double,
        preferences: UserAlertPreferences
    ) async -> AlertDeliveryResult {
        arrivalCount += 1
        lastPreferences = preferences
        if suspendNextArrival {
            suspendNextArrival = false
            return await withCheckedContinuation { continuation in
                pendingArrivalContinuation = continuation
                arrivalStartContinuation?.resume()
                arrivalStartContinuation = nil
            }
        }
        if deliveryResults.isEmpty == false {
            return deliveryResults.removeFirst()
        }
        return deliveryResult
    }

    func waitForArrivalStart() async {
        guard arrivalCount == 0 else { return }
        await withCheckedContinuation { continuation in
            arrivalStartContinuation = continuation
        }
    }

    func completePendingArrival(with result: AlertDeliveryResult) {
        pendingArrivalContinuation?.resume(returning: result)
        pendingArrivalContinuation = nil
    }

    func scheduleSnoozeAlert(destination: Destination, after delay: TimeInterval) async throws {}
    func sendTestAlert() async throws {
        testAlertCount += 1
        lastTestAlertDelay = 0
    }
    func sendTestAlert(after delay: TimeInterval) async throws {
        testAlertCount += 1
        lastTestAlertDelay = delay
    }
    func sendProminentAlarmSpike(destination: Destination, after delay: TimeInterval) async throws {}
    func cancelTripAlerts(
        destinationID: String,
        tripID: UUID?,
        prominentAlarmIdentifier: UUID?
    ) -> AlertCancellationResult {
        AlertCancellationResult(notificationCleanup: .requestsRemoved)
    }
    func reconcilePendingTripAlertCancellations() -> AlertCancellationResult {
        AlertCancellationResult()
    }
    func cancelAllTripAlerts() async -> AlertCancellationResult {
        AlertCancellationResult(notificationCleanup: .requestsRemoved)
    }
}

@MainActor
private final class MockLiveActivityManager: LiveActivityManaging {
    var startCount = 0
    var updateCount = 0
    var endCount = 0
    var lastRemainingDistance: Double?
    var lastIsArrived: Bool?
    var lastAutoStopAt: Date?

    func startTripActivity(destination: Destination, initialDistance: Double, alertRadius: Double) {
        startCount += 1
    }

    func updateTripActivity(
        remainingDistance: Double,
        initialDistance: Double? = nil,
        languageCode: String? = nil,
        isAlertTriggered: Bool,
        isArrived: Bool,
        autoStopAt: Date? = nil
    ) {
        updateCount += 1
        lastRemainingDistance = remainingDistance
        lastIsArrived = isArrived
        lastAutoStopAt = autoStopAt
    }

    func endTripActivity(wasArrived: Bool) {
        endCount += 1
    }
}
