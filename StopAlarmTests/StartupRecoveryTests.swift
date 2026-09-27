import Foundation
import Testing
import UIKit
@testable import StopAlarm

@MainActor
@Suite("Startup and trip recovery")
struct StartupRecoveryTests {
    @Test("ผลส่ง alert ที่กลับมาหลัง Stop ไม่สร้าง snapshot หรือ Live Activity ต่อ")
    func lateArrivalResultAfterStopDoesNotResurrectTrip() async {
        let persistence = MemoryTripPersistence()
        let notifications = RecoveryNotificationClient(authorizationGranted: true)
        let activity = A2RecoveryLiveActivityManager()
        let store = TripStore(
            locationClient: RecoveryLocationClient(),
            notificationClient: notifications,
            persistence: persistence,
            liveActivityManager: activity
        )
        store.destination = testDestination
        notifications.suspendNextArrival = true

        await store.startTrip()
        let sendTask = Task { @MainActor in await self.sendTriggerSamples(to: store) }
        await notifications.waitForArrivalStart()
        let updatesBeforeStop = activity.updateCount

        store.stopTrip()
        notifications.resolveArrival(with: .notificationScheduled(sound: .audible))
        await sendTask.value

        #expect(store.phase == .cancelled)
        #expect(persistence.snapshot == nil)
        #expect(activity.updateCount == updatesBeforeStop)
        #expect(notifications.cancelledTripIDs.isEmpty == false)
    }

    @Test("External stop link confirms before discarding a cold-launch recovery snapshot")
    func externalStopLinkCanConfirmRecoveredTrip() async throws {
        let snapshot = ActiveTripSnapshot(
            destination: .asok,
            radiusMeters: 500,
            startedAt: Date(),
            phase: .tracking
        )
        let persistence = MemoryTripPersistence(snapshot: snapshot)
        let store = TripStore(
            locationClient: RecoveryLocationClient(),
            notificationClient: RecoveryNotificationClient(authorizationGranted: true),
            persistence: persistence,
            liveActivityManager: A2RecoveryLiveActivityManager()
        )
        await store.prepareForLaunch()
        let url = try #require(URL(string: "napnav://stop-trip"))

        let request = try #require(NapNavDeepLink.stopConfirmationRequest(for: url, store: store))

        #expect(request.tripID == snapshot.id)
        #expect(store.phase == .idle)
        #expect(persistence.snapshot?.id == snapshot.id)

        await store.confirmStop(request)

        #expect(persistence.snapshot == nil)
        #expect(persistence.didClear)
        #expect(store.phase == .idle)
    }

    @Test("ผล alert ทั้ง success และ failure จากทริปเก่าไม่แก้ทริปใหม่")
    func lateArrivalResultsDoNotMutateReplacementTrip() async throws {
        let staleResults: [AlertDeliveryResult] = [
            .alarmScheduled(companionNotificationScheduled: false),
            .deliveryUnavailable(reason: .notificationSchedulingFailed)
        ]

        for staleResult in staleResults {
            let persistence = MemoryTripPersistence()
            let notifications = RecoveryNotificationClient(authorizationGranted: true)
            let activity = A2RecoveryLiveActivityManager()
            let store = TripStore(
                locationClient: RecoveryLocationClient(),
                notificationClient: notifications,
                persistence: persistence,
                liveActivityManager: activity
            )
            store.destination = testDestination
            await store.startTrip()
            let oldTripID = try #require(persistence.snapshot?.id)
            notifications.suspendNextArrival = true

            let sendTask = Task { @MainActor in await self.sendTriggerSamples(to: store) }
            await notifications.waitForArrivalStart()
            store.stopTrip()
            await store.startTrip()
            let replacementSnapshot = try #require(persistence.snapshot)
            #expect(replacementSnapshot.id != oldTripID)
            let updatesBeforeOldResult = activity.updateCount

            notifications.resolveArrival(with: staleResult)
            await sendTask.value

            #expect(store.phase == .tracking)
            #expect(persistence.snapshot?.id == replacementSnapshot.id)
            #expect(persistence.snapshot?.alertTriggered == false)
            #expect(persistence.snapshot?.alertSent == false)
            #expect(store.alertSent == false)
            #expect(store.lastAlertDeliveryResult == nil)
            #expect(activity.updateCount == updatesBeforeOldResult)
            #expect(notifications.cancelledTripIDs.contains(oldTripID))
        }
    }

    @Test("Stop ระหว่าง authorization ยกเลิก start ที่รออยู่")
    func stopDuringStartAuthorizationDoesNotStartTrip() async {
        let persistence = MemoryTripPersistence()
        let notifications = RecoveryNotificationClient(authorizationGranted: true)
        let location = RecoveryLocationClient()
        let store = TripStore(
            locationClient: location,
            notificationClient: notifications,
            persistence: persistence
        )
        notifications.suspendNextAuthorization = true

        let startTask = Task { @MainActor in await store.startTrip() }
        await notifications.waitForAuthorizationStart()
        store.stopTrip()
        notifications.resolveAuthorization(granted: true)
        await startTask.value

        #expect(store.phase == .cancelled)
        #expect(store.screen == .destination)
        #expect(location.didStart == false)
        #expect(persistence.snapshot == nil)
    }

    @Test("ผล snooze จากทริปเก่าไม่เขียนลง snapshot ของทริปใหม่")
    func lateSnoozeResultDoesNotMutateReplacementTrip() async throws {
        let persistence = MemoryTripPersistence()
        let notifications = RecoveryNotificationClient(authorizationGranted: true)
        let store = TripStore(
            locationClient: RecoveryLocationClient(),
            notificationClient: notifications,
            persistence: persistence
        )
        await store.startTrip()
        let oldTripID = try #require(persistence.snapshot?.id)
        notifications.suspendNextSnooze = true

        let snoozeTask = try #require(
            store.handleNotificationAction(LocalAlarmDelivery.snoozeActionIdentifier)
        )
        await notifications.waitForSnoozeStart()
        store.stopTrip()
        await store.startTrip()
        let replacementID = try #require(persistence.snapshot?.id)

        notifications.resolveSnooze()
        await snoozeTask.value

        #expect(replacementID != oldTripID)
        #expect(persistence.snapshot?.id == replacementID)
        #expect(persistence.snapshot?.snoozeAt == nil)
    }

    @Test("Notification action ของทริปเก่าไม่หยุดทริปใหม่")
    func staleNotificationActionCannotStopReplacementTrip() async throws {
        let persistence = MemoryTripPersistence()
        let store = TripStore(
            locationClient: RecoveryLocationClient(),
            notificationClient: RecoveryNotificationClient(authorizationGranted: true),
            persistence: persistence
        )
        await store.startTrip()
        let oldTripID = try #require(persistence.snapshot?.id)
        store.stopTrip()
        await store.startTrip()
        let replacementID = try #require(persistence.snapshot?.id)

        store.handleNotificationAction(
            LocalAlarmDelivery.stopActionIdentifier,
            tripID: oldTripID
        )

        #expect(replacementID != oldTripID)
        #expect(store.phase == .tracking)
        #expect(persistence.snapshot?.id == replacementID)
    }

    @Test("Stop ระหว่าง resume recovery ไม่เริ่ม location ต่อหลัง readiness กลับมา")
    func stopDuringRecoveryReadinessDoesNotRestartTracking() async throws {
        let snapshot = ActiveTripSnapshot(
            destination: .asok,
            radiusMeters: 500,
            startedAt: Date()
        )
        let persistence = MemoryTripPersistence(snapshot: snapshot)
        let notifications = RecoveryNotificationClient(authorizationGranted: true)
        let location = RecoveryLocationClient()
        let store = TripStore(
            locationClient: location,
            notificationClient: notifications,
            persistence: persistence,
            liveActivityManager: A2RecoveryLiveActivityManager()
        )
        await store.prepareForLaunch()
        notifications.suspendNextReadiness = true

        let resumeTask = Task { @MainActor in await store.resumeRecoveredTrip() }
        await notifications.waitForReadinessStart()
        store.stopTrip()
        notifications.resolveReadiness()
        await resumeTask.value

        #expect(store.phase == .cancelled)
        #expect(location.didStart == false)
        #expect(persistence.snapshot == nil)
    }

    @Test("terminal snapshot ไม่ถูกเสนอให้กู้คืนเป็น tracking")
    func terminalSnapshotIsDiscardedOnLaunch() async {
        for terminalPhase in [TripPhase.cancelled, .completed] {
            let persistence = MemoryTripPersistence(
                snapshot: ActiveTripSnapshot(
                    destination: .asok,
                    radiusMeters: 500,
                    startedAt: Date(),
                    phase: terminalPhase
                )
            )
            let store = TripStore(
                locationClient: RecoveryLocationClient(),
                notificationClient: RecoveryNotificationClient(),
                persistence: persistence
            )

            await store.prepareForLaunch()

            #expect(store.launchState == .ready)
            #expect(store.pendingRecoverySnapshot == nil)
            #expect(persistence.snapshot == nil)
        }
    }

    private var testDestination: Destination {
        Destination(
            id: "a2-race-test",
            name: "จุดหมายทดสอบ",
            detail: "",
            coordinate: LocationCoordinate(latitude: 0, longitude: 0)
        )
    }

    private func makeArrivedSnapshot(deadline: Date, now: Date) -> ActiveTripSnapshot {
        ActiveTripSnapshot(
            destination: .asok,
            radiusMeters: 500,
            startedAt: now.addingTimeInterval(-600),
            phase: .arrived,
            alertTriggered: true,
            alertSent: true,
            autoStopAt: deadline
        )
    }

    private func sendTriggerSamples(to store: TripStore) async {
        let start = Date()
        for (offset, latitude) in [(0.0, 0.005), (1.0, 0.004)] {
            let sample = LocationSample(
                coordinate: LocationCoordinate(latitude: latitude, longitude: 0),
                horizontalAccuracy: 10,
                timestamp: start.addingTimeInterval(offset),
                speed: 5,
                course: 0
            )
            await store.processLocationEvent(.sample(sample), at: sample.timestamp)
        }
    }

    @Test("ไม่มี active trip แล้วเข้าหน้าเลือกจุดหมายโดยไม่แสดง loading ค้าง")
    func noSnapshotBecomesReady() async {
        let location = RecoveryLocationClient()
        let store = TripStore(
            locationClient: location,
            notificationClient: RecoveryNotificationClient(),
            persistence: MemoryTripPersistence()
        )

        await store.prepareForLaunch()

        #expect(store.launchState == .ready)
        #expect(store.screen == .destination)
        #expect(store.showsStartupView == false)
        #expect(location.didStart == false)
    }

    @Test("active trip รอผู้ใช้ยืนยันก่อนเริ่ม location และ Live Activity")
    func snapshotWaitsForRecoveryChoice() async {
        let destination = Destination(
            id: "restored",
            name: "ปลายทางเดิม",
            detail: "กรุงเทพฯ",
            coordinate: LocationCoordinate(latitude: 13.75, longitude: 100.50)
        )
        let snapshot = ActiveTripSnapshot(
            destination: destination,
            radiusMeters: 750,
            startedAt: Date(timeIntervalSince1970: 1_800_000_000)
        )
        let persistence = MemoryTripPersistence(snapshot: snapshot)
        let location = RecoveryLocationClient()
        let liveActivity = MockLiveActivityManager()
        let store = TripStore(
            locationClient: location,
            notificationClient: RecoveryNotificationClient(authorizationGranted: true),
            persistence: persistence,
            liveActivityManager: liveActivity
        )

        await store.prepareForLaunch()

        #expect(store.launchState == .awaitingTripRecovery(destinationName: destination.name))
        #expect(store.pendingRecoverySnapshot == snapshot)
        #expect(location.didStart == false)
        #expect(liveActivity.endAllCallCount == 1)
        #expect(liveActivity.startCalls.isEmpty)

        await store.resumeRecoveredTrip()

        #expect(store.launchState == .ready)
        #expect(store.screen == .tracking)
        #expect(store.destination == destination)
        #expect(store.selectedRadiusMeters == 750)
        #expect(location.didStart)
        #expect(location.didRequestAuthorization == false)
        #expect(liveActivity.startCalls.count == 1)
    }

    @Test("ทิ้งทริปที่กู้คืนแล้วล้าง snapshot และไม่เริ่ม tracking")
    func discardingRecoveredTripCleansUpPersistedWork() async {
        let snapshot = ActiveTripSnapshot(
            destination: .asok,
            radiusMeters: 500,
            startedAt: Date()
        )
        let persistence = MemoryTripPersistence(snapshot: snapshot)
        let location = RecoveryLocationClient()
        let liveActivity = MockLiveActivityManager()
        let store = TripStore(
            locationClient: location,
            notificationClient: RecoveryNotificationClient(authorizationGranted: true),
            persistence: persistence,
            liveActivityManager: liveActivity
        )

        await store.prepareForLaunch()
        await store.discardRecoveredTrip()

        #expect(store.launchState == .ready)
        #expect(store.screen == .destination)
        #expect(store.phase == .idle)
        #expect(store.pendingRecoverySnapshot == nil)
        #expect(persistence.snapshot == nil)
        #expect(persistence.didClear)
        #expect(location.didStart == false)
        #expect(location.didStop)
        #expect(liveActivity.startCalls.isEmpty)
        #expect(liveActivity.endAllCallCount == 2)
    }

    @Test("ทิ้งทริปที่กู้คืนแล้วแต่ AlarmKit cancel ล้มเหลว เก็บ ID ให้ลองใหม่")
    func discardRetainsFailedAlarmCancellationForRetry() async {
        let alarmID = UUID()
        let snapshot = ActiveTripSnapshot(
            destination: .asok,
            radiusMeters: 500,
            startedAt: Date(),
            phase: .alarm,
            alertTriggered: true,
            alertSent: true,
            prominentAlarmIdentifier: alarmID
        )
        let persistence = MemoryTripPersistence(snapshot: snapshot)
        let notifications = RecoveryNotificationClient(
            authorizationGranted: true,
            existingAlarmIdentifiers: [alarmID]
        )
        notifications.failedAlarmCancellationIdentifiers = [alarmID]
        let store = TripStore(
            locationClient: RecoveryLocationClient(),
            notificationClient: notifications,
            persistence: persistence,
            liveActivityManager: MockLiveActivityManager()
        )

        await store.prepareForLaunch()
        await store.discardRecoveredTrip()

        #expect(persistence.snapshot == nil)
        #expect(notifications.pendingAlarmCancellationIdentifiers == [alarmID])
        #expect(store.health == .alertCleanupFailed)
        #expect(store.alertCleanupWarning != nil)

        notifications.failedAlarmCancellationIdentifiers.remove(alarmID)
        let result = store.reconcilePendingAlertCancellations()

        #expect(result.hasFailures == false)
        #expect(notifications.pendingAlarmCancellationIdentifiers.isEmpty)
        #expect(store.alertCleanupWarning == nil)
    }

    @Test("อ่าน persistence ไม่ได้แล้วแสดง failure ที่ลองใหม่ได้")
    func persistenceFailureShowsRecoveryState() async {
        let persistence = MemoryTripPersistence(loadError: PersistenceTestError.corrupt)
        let location = RecoveryLocationClient()
        let store = TripStore(
            locationClient: location,
            notificationClient: RecoveryNotificationClient(),
            persistence: persistence
        )

        await store.prepareForLaunch()

        guard case .failed = store.launchState else {
            Issue.record("startup ควรอยู่ใน failed state")
            return
        }
        #expect(store.showsStartupView)
        #expect(location.didStart == false)
    }

    @Test("ผู้ใช้ล้าง snapshot ที่ decode ไม่ได้แล้ว cleanup alert ที่ระบุตัวไม่ได้ทั้งหมด")
    func discardingCorruptSnapshotCancelsAllTripAlerts() async {
        let persistence = MemoryTripPersistence(loadError: PersistenceTestError.corrupt)
        let notifications = RecoveryNotificationClient()
        let store = TripStore(
            locationClient: RecoveryLocationClient(),
            notificationClient: notifications,
            persistence: persistence
        )

        await store.prepareForLaunch()
        persistence.loadError = nil
        await store.discardRecoveredTrip()

        #expect(notifications.didCancelAllTripAlerts)
        #expect(store.launchState == .ready)
        #expect(store.phase == .idle)
    }

    @Test("เริ่มทริปบันทึก snapshot และหยุดทริปล้าง snapshot")
    func startAndStopMaintainPersistence() async {
        let persistence = MemoryTripPersistence()
        let store = TripStore(
            locationClient: RecoveryLocationClient(),
            notificationClient: RecoveryNotificationClient(authorizationGranted: true),
            persistence: persistence
        )

        await store.startTrip()

        #expect(persistence.snapshot?.destination == store.destination)
        #expect(persistence.snapshot?.radiusMeters == store.selectedRadiusMeters)

        store.stopTrip()

        #expect(persistence.snapshot == nil)
        #expect(persistence.didClear)
    }

    @Test("บันทึกทริปไม่ได้แล้วแจ้งว่าไม่พร้อมกู้คืน")
    func saveFailureDisablesRecovery() async {
        let persistence = MemoryTripPersistence(saveError: PersistenceTestError.corrupt)
        let store = TripStore(
            locationClient: RecoveryLocationClient(),
            notificationClient: RecoveryNotificationClient(authorizationGranted: true),
            persistence: persistence
        )

        await store.startTrip()

        #expect(store.screen == .tracking)
        #expect(store.recoveryAvailable == false)
        #expect(store.health == .persistenceUnavailable)
    }

    @Test("snapshot รุ่นเก่ายัง decode ได้โดยใช้ค่า lifecycle ที่ปลอดภัย")
    func legacySnapshotDecodesWithSafeDefaults() throws {
        struct LegacySnapshot: Codable {
            let destination: Destination
            let radiusMeters: Double
            let startedAt: Date
        }

        let startedAt = Date(timeIntervalSince1970: 1_700_000_000)
        let data = try JSONEncoder().encode(
            LegacySnapshot(destination: .asok, radiusMeters: 800, startedAt: startedAt)
        )
        let snapshot = try JSONDecoder().decode(ActiveTripSnapshot.self, from: data)

        #expect(snapshot.destination == .asok)
        #expect(snapshot.radiusMeters == 800)
        #expect(snapshot.startedAt == startedAt)
        #expect(snapshot.phase == .tracking)
        #expect(snapshot.alertTriggered == false)
        #expect(snapshot.alertSent == false)
        #expect(snapshot.prominentAlarmIdentifier == nil)
    }

    @Test("ปิด AlarmKit แล้ว relaunch ยังให้กู้ทริปและติดตามต่อจนถึงจุดหมาย")
    func dismissedPersistedAlarmDoesNotDiscardTrip() async {
        let alarmID = UUID()
        let snapshot = ActiveTripSnapshot(
            destination: testDestination,
            radiusMeters: 500,
            startedAt: Date(),
            phase: .alarm,
            alertTriggered: true,
            alertSent: true,
            prominentAlarmIdentifier: alarmID
        )
        let persistence = MemoryTripPersistence(snapshot: snapshot)
        let notifications = RecoveryNotificationClient(authorizationGranted: true)
        let location = RecoveryLocationClient()
        let store = TripStore(
            locationClient: location,
            notificationClient: notifications,
            persistence: persistence,
            liveActivityManager: MockLiveActivityManager()
        )

        await store.prepareForLaunch()

        #expect(store.pendingRecoverySnapshot?.id == snapshot.id)
        #expect(persistence.snapshot?.id == snapshot.id)
        #expect(notifications.cancelledAlarmIdentifier == nil)
        #expect(location.didStart == false)

        await store.resumeRecoveredTrip()
        #expect(store.phase == .alarm)
        #expect(location.didStart)

        let now = Date()
        for (offset, latitude) in [(0.0, 0.00015), (1.0, 0.00014)] {
            let sample = LocationSample(
                coordinate: LocationCoordinate(latitude: latitude, longitude: 0),
                horizontalAccuracy: 10,
                timestamp: now.addingTimeInterval(offset),
                speed: 5,
                course: 0
            )
            await store.processLocationEvent(.sample(sample), at: sample.timestamp)
        }

        #expect(store.phase == .arrived)
        #expect(notifications.arrivalCount == 0)
    }

    @Test("restore พบ AlarmKit เดิมแล้วไม่สร้าง alarm ซ้ำ")
    func existingPersistedAlarmRestoresWithoutRescheduling() async {
        let alarmID = UUID()
        let snapshot = ActiveTripSnapshot(
            destination: .asok,
            radiusMeters: 500,
            startedAt: Date(),
            phase: .alarm,
            alertTriggered: true,
            alertSent: true,
            prominentAlarmIdentifier: alarmID
        )
        let notifications = RecoveryNotificationClient(
            authorizationGranted: true,
            existingAlarmIdentifiers: [alarmID]
        )
        let activity = MockLiveActivityManager()
        let store = TripStore(
            locationClient: RecoveryLocationClient(),
            notificationClient: notifications,
            persistence: MemoryTripPersistence(snapshot: snapshot),
            liveActivityManager: activity
        )

        await store.prepareForLaunch()
        await store.resumeRecoveredTrip()

        #expect(store.phase == .alarm)
        #expect(notifications.arrivalCount == 0)
        #expect(activity.startCalls.count == 1)
    }

    @Test("restore ช่วง arrived กู้ countdown โดยไม่เปิด GPS ซ้ำ")
    func arrivedSnapshotRestoresAutoStopWithoutTracking() async {
        let clock = TestTripClock(now: Date())
        let backgroundTasks = TestTripBackgroundTaskManager()
        let deadline = clock.now.addingTimeInterval(3_600)
        let snapshot = ActiveTripSnapshot(
            destination: .asok,
            radiusMeters: 500,
            startedAt: Date(),
            phase: .arrived,
            alertTriggered: true,
            alertSent: true,
            autoStopAt: deadline
        )
        let persistence = MemoryTripPersistence(snapshot: snapshot)
        let location = RecoveryLocationClient()
        let activity = MockLiveActivityManager()
        let store = TripStore(
            locationClient: location,
            notificationClient: RecoveryNotificationClient(authorizationGranted: true),
            persistence: persistence,
            liveActivityManager: activity,
            clock: clock,
            backgroundTaskManager: backgroundTasks
        )

        await store.prepareForLaunch()
        await store.resumeRecoveredTrip()
        await clock.waitForSleepRequestCount(atLeast: 1)

        #expect(store.phase == .arrived)
        #expect(store.autoStopAt == deadline)
        #expect(location.didStart == false)
        #expect(activity.startCalls.count == 1)
        #expect(activity.updateCalls.last?.isArrived == true)
        #expect(activity.updateCalls.last?.autoStopAt == deadline)
    }

    @Test("restore arrived ที่เลย deadline แล้วจบทริปและล้าง snapshot ทันที")
    func expiredAutoStopCompletesDuringRestore() async {
        let clock = TestTripClock(now: Date())
        let backgroundTasks = TestTripBackgroundTaskManager()
        let deadline = clock.now.addingTimeInterval(-1)
        let snapshot = ActiveTripSnapshot(
            destination: .asok,
            radiusMeters: 500,
            startedAt: clock.now.addingTimeInterval(-600),
            phase: .arrived,
            alertTriggered: true,
            alertSent: true,
            autoStopAt: deadline
        )
        let persistence = MemoryTripPersistence(snapshot: snapshot)
        let location = RecoveryLocationClient()
        let store = TripStore(
            locationClient: location,
            notificationClient: RecoveryNotificationClient(authorizationGranted: true),
            persistence: persistence,
            clock: clock,
            backgroundTaskManager: backgroundTasks
        )

        await store.prepareForLaunch()
        await store.resumeRecoveredTrip()

        #expect(store.phase == .completed)
        #expect(store.screen == .destination)
        #expect(persistence.snapshot == nil)
        #expect(location.didStart == false)
    }

    @Test("background-task expiration releases its grant but never completes before deadline")
    func autoStopBackgroundExpirationWaitsForDeadline() async {
        let clock = TestTripClock(now: Date())
        let backgroundTasks = TestTripBackgroundTaskManager()
        let activity = A2RecoveryLiveActivityManager()
        let deadline = clock.now.addingTimeInterval(60)
        let persistence = MemoryTripPersistence(snapshot: makeArrivedSnapshot(
            deadline: deadline,
            now: clock.now
        ))
        let store = TripStore(
            locationClient: RecoveryLocationClient(),
            notificationClient: RecoveryNotificationClient(authorizationGranted: true),
            persistence: persistence,
            liveActivityManager: activity,
            clock: clock,
            backgroundTaskManager: backgroundTasks
        )

        await store.prepareForLaunch()
        await store.resumeRecoveredTrip()
        await clock.waitForSleepRequestCount(atLeast: 1)

        await confirmation("Expired background grant is ended") { confirm in
            backgroundTasks.onEnd = { _ in confirm() }
            backgroundTasks.expireLatestTask()
        }
        #expect(store.phase == .arrived)
        #expect(store.autoStopAt == deadline)
        #expect(persistence.snapshot?.phase == .arrived)
        #expect(activity.endCount == 0)

        clock.advance(to: deadline.addingTimeInterval(-1))
        store.reconcileAutoStopDeadline()
        await clock.waitForSleepRequestCount(atLeast: 2)
        #expect(store.phase == .arrived)

        clock.advance(to: deadline)
        await persistence.waitUntilCleared()
        #expect(store.phase == .completed)
        #expect(persistence.snapshot == nil)
        #expect(activity.endCount == 1)
    }

    @Test("Stop cancels the pending Auto-Stop so an old timer cannot finish a new trip")
    func stopCancelsAutoStopBeforeReplacementTrip() async {
        let clock = TestTripClock(now: Date())
        let backgroundTasks = TestTripBackgroundTaskManager()
        let deadline = clock.now.addingTimeInterval(30)
        let persistence = MemoryTripPersistence(snapshot: makeArrivedSnapshot(
            deadline: deadline,
            now: clock.now
        ))
        let store = TripStore(
            locationClient: RecoveryLocationClient(),
            notificationClient: RecoveryNotificationClient(authorizationGranted: true),
            persistence: persistence,
            clock: clock,
            backgroundTaskManager: backgroundTasks
        )

        await store.prepareForLaunch()
        await store.resumeRecoveredTrip()
        await clock.waitForSleepRequestCount(atLeast: 1)
        store.stopTrip()
        await clock.waitUntilIdle()

        await store.startTrip()
        #expect(store.phase == .tracking)
        clock.advance(to: deadline)

        #expect(store.phase == .tracking)
        #expect(backgroundTasks.endedTaskIdentifiers.count == 1)
    }

    @Test("cleanup resource ครบแม้ล้าง persistence ไม่สำเร็จ")
    func cleanupFailureStillStopsRuntimeResources() async {
        let persistence = MemoryTripPersistence(clearError: PersistenceTestError.corrupt)
        let location = RecoveryLocationClient()
        let notifications = RecoveryNotificationClient(authorizationGranted: true)
        let activity = MockLiveActivityManager()
        let store = TripStore(
            locationClient: location,
            notificationClient: notifications,
            persistence: persistence,
            liveActivityManager: activity
        )

        await store.startTrip()
        store.stopTrip()

        #expect(location.didStop)
        #expect(notifications.cancelledDestinationID == store.destination.id)
        #expect(activity.endCallCount == 1)
        #expect(activity.lastEndWasArrived == false)
        #expect(store.phase == .cancelled)
        #expect(store.health == .persistenceUnavailable)
        #expect(store.recoveryAvailable == false)
    }
}

private enum PersistenceTestError: Error {
    case corrupt
}

@MainActor
private final class MemoryTripPersistence: TripPersisting {
    var snapshot: ActiveTripSnapshot?
    var loadError: (any Error)?
    var saveError: (any Error)?
    var clearError: (any Error)?
    private(set) var didClear = false
    private var clearWaiter: CheckedContinuation<Void, Never>?

    init(
        snapshot: ActiveTripSnapshot? = nil,
        loadError: (any Error)? = nil,
        saveError: (any Error)? = nil,
        clearError: (any Error)? = nil
    ) {
        self.snapshot = snapshot
        self.loadError = loadError
        self.saveError = saveError
        self.clearError = clearError
    }

    func loadActiveTrip() throws -> ActiveTripSnapshot? {
        if let loadError { throw loadError }
        return snapshot
    }

    func saveActiveTrip(_ snapshot: ActiveTripSnapshot) throws {
        if let saveError { throw saveError }
        self.snapshot = snapshot
    }

    func clearActiveTrip() throws {
        if let clearError { throw clearError }
        snapshot = nil
        didClear = true
        clearWaiter?.resume()
        clearWaiter = nil
    }

    func waitUntilCleared() async {
        guard didClear == false else { return }
        await withCheckedContinuation { clearWaiter = $0 }
    }
}

@MainActor
private final class RecoveryLocationClient: LocationProviding {
    private var continuation: AsyncStream<LocationEvent>.Continuation?
    private(set) var didRequestAuthorization = false
    private(set) var didStart = false
    private(set) var didStop = false

    func requestWhenInUseAuthorization() {
        didRequestAuthorization = true
    }

    func startUpdates() -> AsyncStream<LocationEvent> {
        didStart = true
        return AsyncStream { continuation in
            self.continuation = continuation
        }
    }

    func stopUpdates() {
        didStop = true
        continuation?.finish()
        continuation = nil
    }
}

@MainActor
private final class RecoveryNotificationClient: NotificationProviding {
    var authorizationGranted: Bool
    var existingAlarmIdentifiers: Set<UUID>
    var pendingAlarmCancellationIdentifiers: Set<UUID> = []
    var failedAlarmCancellationIdentifiers: Set<UUID> = []
    private(set) var cancelledDestinationID: String?
    private(set) var cancelledAlarmIdentifier: UUID?
    private(set) var arrivalCount = 0
    private(set) var didCancelAllTripAlerts = false
    private(set) var cancelledTripIDs: [UUID] = []
    var suspendNextAuthorization = false
    var suspendNextReadiness = false
    var suspendNextArrival = false
    var suspendNextSnooze = false
    private var authorizationStarted = false
    private var readinessStarted = false
    private var arrivalStarted = false
    private var snoozeStarted = false
    private var authorizationContinuation: CheckedContinuation<Bool, Never>?
    private var readinessContinuation: CheckedContinuation<AlarmReadiness, Never>?
    private var arrivalContinuation: CheckedContinuation<AlertDeliveryResult, Never>?
    private var snoozeContinuation: CheckedContinuation<Void, Never>?
    private var authorizationStartWaiter: CheckedContinuation<Void, Never>?
    private var readinessStartWaiter: CheckedContinuation<Void, Never>?
    private var arrivalStartWaiter: CheckedContinuation<Void, Never>?
    private var snoozeStartWaiter: CheckedContinuation<Void, Never>?

    init(
        authorizationGranted: Bool = false,
        existingAlarmIdentifiers: Set<UUID> = []
    ) {
        self.authorizationGranted = authorizationGranted
        self.existingAlarmIdentifiers = existingAlarmIdentifiers
    }

    func authorizationIsGranted() async -> Bool {
        authorizationGranted
    }

    func requestAuthorizationIfNeeded() async -> Bool {
        guard suspendNextAuthorization else { return authorizationGranted }
        suspendNextAuthorization = false
        return await withCheckedContinuation { continuation in
            authorizationContinuation = continuation
            authorizationStarted = true
            authorizationStartWaiter?.resume()
            authorizationStartWaiter = nil
        }
    }

    func readiness() async -> AlarmReadiness {
        if suspendNextReadiness {
            suspendNextReadiness = false
            return await withCheckedContinuation { continuation in
                readinessContinuation = continuation
                readinessStarted = true
                readinessStartWaiter?.resume()
                readinessStartWaiter = nil
            }
        }
        return AlarmReadiness(
            permission: authorizationGranted ? .authorized : .denied,
            alertsEnabled: authorizationGranted,
            soundsEnabled: authorizationGranted,
            lockScreenEnabled: authorizationGranted,
            timeSensitiveSetting: authorizationGranted ? .enabled : .disabled
        )
    }

    func waitForAuthorizationStart() async {
        guard authorizationStarted == false else { return }
        await withCheckedContinuation { authorizationStartWaiter = $0 }
    }

    func resolveAuthorization(granted: Bool) {
        authorizationGranted = granted
        let continuation = authorizationContinuation
        authorizationContinuation = nil
        continuation?.resume(returning: granted)
    }

    func waitForReadinessStart() async {
        guard readinessStarted == false else { return }
        await withCheckedContinuation { readinessStartWaiter = $0 }
    }

    func resolveReadiness() {
        let continuation = readinessContinuation
        readinessContinuation = nil
        continuation?.resume(returning: AlarmReadiness(
            permission: .authorized,
            alertsEnabled: true,
            soundsEnabled: true,
            lockScreenEnabled: true,
            timeSensitiveSetting: .enabled
        ))
    }

    func waitForArrivalStart() async {
        guard arrivalStarted == false else { return }
        await withCheckedContinuation { arrivalStartWaiter = $0 }
    }

    func resolveArrival(with result: AlertDeliveryResult) {
        let continuation = arrivalContinuation
        arrivalContinuation = nil
        continuation?.resume(returning: result)
    }

    func waitForSnoozeStart() async {
        guard snoozeStarted == false else { return }
        await withCheckedContinuation { snoozeStartWaiter = $0 }
    }

    func resolveSnooze() {
        let continuation = snoozeContinuation
        snoozeContinuation = nil
        continuation?.resume()
    }

    func prominentAlarmExists(identifier: UUID) -> Bool {
        existingAlarmIdentifiers.contains(identifier)
    }

    func cancelTripAlerts(
        destinationID: String,
        tripID: UUID?,
        prominentAlarmIdentifier: UUID?
    ) -> AlertCancellationResult {
        cancelledDestinationID = destinationID
        if let tripID {
            cancelledTripIDs.append(tripID)
        }
        cancelledAlarmIdentifier = prominentAlarmIdentifier
        guard let alarmID = prominentAlarmIdentifier ?? tripID else {
            return AlertCancellationResult(notificationCleanup: .requestsRemoved)
        }
        if failedAlarmCancellationIdentifiers.contains(alarmID) {
            pendingAlarmCancellationIdentifiers.insert(alarmID)
            return AlertCancellationResult(
                notificationCleanup: .requestsRemoved,
                alarmKitOutcomes: [.failed(alarmID, reason: "test cancellation failure")]
            )
        }
        pendingAlarmCancellationIdentifiers.remove(alarmID)
        existingAlarmIdentifiers.remove(alarmID)
        return AlertCancellationResult(
            notificationCleanup: .requestsRemoved,
            alarmKitOutcomes: [.cancelled(alarmID)]
        )
    }

    func reconcilePendingTripAlertCancellations() -> AlertCancellationResult {
        let outcomes = Array(pendingAlarmCancellationIdentifiers).map { alarmID in
            if failedAlarmCancellationIdentifiers.contains(alarmID) {
                return AlarmKitCancellationOutcome.failed(
                    alarmID,
                    reason: "test cancellation failure"
                )
            }
            pendingAlarmCancellationIdentifiers.remove(alarmID)
            existingAlarmIdentifiers.remove(alarmID)
            return .cancelled(alarmID)
        }
        return AlertCancellationResult(alarmKitOutcomes: outcomes)
    }

    func cancelAllTripAlerts() async -> AlertCancellationResult {
        didCancelAllTripAlerts = true
        let alarmIDs = existingAlarmIdentifiers.union(pendingAlarmCancellationIdentifiers)
        let outcomes = alarmIDs.map { alarmID in
            if failedAlarmCancellationIdentifiers.contains(alarmID) {
                pendingAlarmCancellationIdentifiers.insert(alarmID)
                return AlarmKitCancellationOutcome.failed(
                    alarmID,
                    reason: "test cancellation failure"
                )
            }
            pendingAlarmCancellationIdentifiers.remove(alarmID)
            existingAlarmIdentifiers.remove(alarmID)
            return .cancelled(alarmID)
        }
        return AlertCancellationResult(
            notificationCleanup: .requestsRemoved,
            alarmKitOutcomes: outcomes
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
        await deliverArrival()
    }

    func sendArrivalAlert(
        tripID: UUID?,
        destination: Destination,
        distanceMeters: Double,
        preferences: UserAlertPreferences
    ) async -> AlertDeliveryResult {
        await deliverArrival()
    }

    private func deliverArrival() async -> AlertDeliveryResult {
        arrivalCount += 1
        guard suspendNextArrival else { return .notificationScheduled(sound: .audible) }
        suspendNextArrival = false
        return await withCheckedContinuation { continuation in
            arrivalContinuation = continuation
            arrivalStarted = true
            arrivalStartWaiter?.resume()
            arrivalStartWaiter = nil
        }
    }

    func scheduleSnoozeAlert(destination: Destination, after delay: TimeInterval) async throws {
        guard suspendNextSnooze else { return }
        suspendNextSnooze = false
        await withCheckedContinuation { continuation in
            snoozeContinuation = continuation
            snoozeStarted = true
            snoozeStartWaiter?.resume()
            snoozeStartWaiter = nil
        }
    }

    func scheduleSnoozeAlert(
        tripID: UUID?,
        destination: Destination,
        after delay: TimeInterval
    ) async throws {
        try await scheduleSnoozeAlert(destination: destination, after: delay)
    }
    func sendTestAlert() async throws {}
}

@MainActor
private final class A2RecoveryLiveActivityManager: LiveActivityManaging {
    private(set) var startCount = 0
    private(set) var updateCount = 0
    private(set) var endCount = 0
    private(set) var endAllCallCount = 0

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
    }

    func endTripActivity(wasArrived: Bool) {
        endCount += 1
    }

    func endAllTripActivities() async {
        endAllCallCount += 1
    }
}

@MainActor
final class TestTripClock: TripClock {
    private struct Waiter {
        let deadline: Date
        let continuation: CheckedContinuation<Void, any Error>
    }

    private var waiters: [UUID: Waiter] = [:]
    private var sleepRequestObservers: [(Int, CheckedContinuation<Void, Never>)] = []
    private var idleObservers: [CheckedContinuation<Void, Never>] = []
    private(set) var sleepRequestCount = 0
    var now: Date

    init(now: Date) {
        self.now = now
    }

    func sleep(until deadline: Date) async throws {
        guard deadline > now else { return }
        let id = UUID()
        try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, any Error>) in
                guard Task.isCancelled == false else {
                    continuation.resume(throwing: CancellationError())
                    return
                }
                waiters[id] = Waiter(deadline: deadline, continuation: continuation)
                sleepRequestCount += 1
                resumeSleepRequestObservers()
            }
        } onCancel: {
            Task { @MainActor [weak self] in
                self?.cancelWaiter(id)
            }
        }
    }

    func advance(to date: Date) {
        now = date
        let dueIDs = waiters.compactMap { id, waiter in
            waiter.deadline <= now ? id : nil
        }
        for id in dueIDs {
            waiters.removeValue(forKey: id)?.continuation.resume()
        }
        resumeIdleObserversIfNeeded()
    }

    func waitForSleepRequestCount(atLeast target: Int) async {
        guard sleepRequestCount < target else { return }
        await withCheckedContinuation { continuation in
            sleepRequestObservers.append((target, continuation))
        }
    }

    func waitUntilIdle() async {
        guard waiters.isEmpty == false else { return }
        await withCheckedContinuation { idleObservers.append($0) }
    }

    private func cancelWaiter(_ id: UUID) {
        waiters.removeValue(forKey: id)?.continuation.resume(throwing: CancellationError())
        resumeIdleObserversIfNeeded()
    }

    private func resumeSleepRequestObservers() {
        let ready = sleepRequestObservers.filter { sleepRequestCount >= $0.0 }
        sleepRequestObservers.removeAll { sleepRequestCount >= $0.0 }
        ready.forEach { $0.1.resume() }
    }

    private func resumeIdleObserversIfNeeded() {
        guard waiters.isEmpty else { return }
        let observers = idleObservers
        idleObservers.removeAll()
        observers.forEach { $0.resume() }
    }
}

@MainActor
final class TestTripBackgroundTaskManager: TripBackgroundTaskManaging {
    private var nextIdentifier = 1
    private var latestExpirationHandler: (@MainActor @Sendable () -> Void)?
    private(set) var endedTaskIdentifiers: [UIBackgroundTaskIdentifier] = []
    var onEnd: (@MainActor @Sendable (UIBackgroundTaskIdentifier) -> Void)?

    func beginBackgroundTask(
        withName name: String,
        expirationHandler: @escaping @MainActor @Sendable () -> Void
    ) -> UIBackgroundTaskIdentifier {
        latestExpirationHandler = expirationHandler
        defer { nextIdentifier += 1 }
        return UIBackgroundTaskIdentifier(rawValue: nextIdentifier)
    }

    func endBackgroundTask(_ identifier: UIBackgroundTaskIdentifier) {
        endedTaskIdentifiers.append(identifier)
        onEnd?(identifier)
    }

    func expireLatestTask() {
        latestExpirationHandler?()
    }
}
