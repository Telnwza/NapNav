import Testing
import Foundation
@testable import StopAlarm

@Suite("Live Activity ContentState Tests")
struct LiveActivityContentStateTests {
    @Test("Distance formatting converts to kilometers when >= 1,000 meters")
    func testKilometerFormatting() {
        let state1 = TripActivityAttributes.ContentState(
            remainingDistanceMeters: 1_400,
            alertRadiusMeters: 500,
            initialDistanceMeters: 2_000
        )
        #expect(state1.formattedRemainingDistance == "1.4 km")
        #expect(state1.formattedAlertRadius == "500 m")

        let state2 = TripActivityAttributes.ContentState(
            remainingDistanceMeters: 10_000,
            alertRadiusMeters: 1_000,
            initialDistanceMeters: 15_000
        )
        #expect(state2.formattedRemainingDistance == "10 km")
        #expect(state2.formattedAlertRadius == "1 km")
    }

    @Test("Distance formatting displays meters when < 1,000 meters")
    func testMeterFormatting() {
        let state1 = TripActivityAttributes.ContentState(
            remainingDistanceMeters: 850,
            alertRadiusMeters: 500,
            initialDistanceMeters: 2_000
        )
        #expect(state1.formattedRemainingDistance == "850 m")

        let state2 = TripActivityAttributes.ContentState(
            remainingDistanceMeters: 0,
            alertRadiusMeters: 500,
            initialDistanceMeters: 2_000
        )
        #expect(state2.formattedRemainingDistance == "0 m")
    }

    @Test("Progress fraction calculates accurately and clamps to 0.0...1.0")
    func testProgressFraction() {
        let halfWay = TripActivityAttributes.ContentState(
            remainingDistanceMeters: 1_000,
            alertRadiusMeters: 500,
            initialDistanceMeters: 2_000
        )
        #expect(abs(halfWay.progressFraction - 0.5) < 0.001)

        let start = TripActivityAttributes.ContentState(
            remainingDistanceMeters: 2_000,
            alertRadiusMeters: 500,
            initialDistanceMeters: 2_000
        )
        #expect(start.progressFraction == 0.0)

        let arrived = TripActivityAttributes.ContentState(
            remainingDistanceMeters: 0,
            alertRadiusMeters: 500,
            initialDistanceMeters: 2_000
        )
        #expect(arrived.progressFraction == 1.0)

        let clampedBelow = TripActivityAttributes.ContentState(
            remainingDistanceMeters: 2_500,
            alertRadiusMeters: 500,
            initialDistanceMeters: 2_000
        )
        #expect(clampedBelow.progressFraction == 0.0)

        let clampedAbove = TripActivityAttributes.ContentState(
            remainingDistanceMeters: -100,
            alertRadiusMeters: 500,
            initialDistanceMeters: 2_000
        )
        #expect(clampedAbove.progressFraction == 1.0)
    }

    @Test("Status titles and icons reflect trip progress")
    func testStatusTitlesAndIcons() {
        let traveling = TripActivityAttributes.ContentState(
            remainingDistanceMeters: 2_000,
            alertRadiusMeters: 500,
            initialDistanceMeters: 3_000,
            isAlertTriggered: false,
            isArrived: false
        )
        #expect(traveling.statusTitle == "กำลังเดินทาง")
        #expect(traveling.statusIconName == "mappin.circle.fill")
        #expect(traveling.autoStopAt == nil)

        let alertZone = TripActivityAttributes.ContentState(
            remainingDistanceMeters: 400,
            alertRadiusMeters: 500,
            initialDistanceMeters: 3_000,
            isAlertTriggered: false,
            isArrived: false
        )
        #expect(alertZone.statusTitle == "ใกล้ถึง")
        #expect(alertZone.statusIconName == "bell.badge.fill")

        let triggered = TripActivityAttributes.ContentState(
            remainingDistanceMeters: 800,
            alertRadiusMeters: 500,
            initialDistanceMeters: 3_000,
            isAlertTriggered: true,
            isArrived: false
        )
        #expect(triggered.statusTitle == "ใกล้ถึง")
        #expect(triggered.statusIconName == "bell.badge.fill")

        let stopDate = Date().addingTimeInterval(30)
        let arrived = TripActivityAttributes.ContentState(
            remainingDistanceMeters: 0,
            alertRadiusMeters: 500,
            initialDistanceMeters: 3_000,
            isAlertTriggered: true,
            isArrived: true,
            autoStopAt: stopDate
        )
        #expect(arrived.statusTitle == "ถึงแล้ว")
        #expect(arrived.statusIconName == "checkmark.circle.fill")
        #expect(arrived.autoStopAt == stopDate)
    }

    @Test("Status titles support English and Thai localization")
    func testStatusTitlesLocalization() {
        let traveling = TripActivityAttributes.ContentState(
            remainingDistanceMeters: 2_000,
            alertRadiusMeters: 500,
            initialDistanceMeters: 3_000,
            isAlertTriggered: false,
            isArrived: false
        )
        #expect(traveling.statusTitle(for: .thai) == "กำลังเดินทาง")
        #expect(traveling.statusTitle(for: .english) == "On the Way")

        let approaching = TripActivityAttributes.ContentState(
            remainingDistanceMeters: 400,
            alertRadiusMeters: 500,
            initialDistanceMeters: 3_000,
            isAlertTriggered: true,
            isArrived: false
        )
        #expect(approaching.statusTitle(for: .thai) == "ใกล้ถึง")
        #expect(approaching.statusTitle(for: .english) == "Approaching")

        let arrived = TripActivityAttributes.ContentState(
            remainingDistanceMeters: 0,
            alertRadiusMeters: 500,
            initialDistanceMeters: 3_000,
            isAlertTriggered: true,
            isArrived: true
        )
        #expect(arrived.statusTitle(for: .thai) == "ถึงแล้ว")
        #expect(arrived.statusTitle(for: .english) == "Arrived")
    }

    @Test("Progress fraction is always 1.0 when arrived even with remaining distance")
    func testProgressFractionWhenArrived() {
        let state = TripActivityAttributes.ContentState(
            remainingDistanceMeters: 100,
            alertRadiusMeters: 500,
            initialDistanceMeters: 2_000,
            isAlertTriggered: true,
            isArrived: true
        )
        #expect(state.progressFraction == 1.0)
    }
}

@Suite("TripStore Live Activity Integration Tests")
struct TripStoreLiveActivityIntegrationTests {
    @Test("Starting trip launches Live Activity and stopping ends it")
    @MainActor
    func testStartAndStopTripLiveActivity() async {
        let mockLocation = TestLocationClient()
        let mockNotification = TestNotificationClient()
        let mockPersistence = NoopTripPersistence()
        let mockLiveActivity = MockLiveActivityManager()

        let store = TripStore(
            locationClient: mockLocation,
            notificationClient: mockNotification,
            persistence: mockPersistence,
            liveActivityManager: mockLiveActivity
        )

        store.selectDestination(.asok)
        store.selectedRadiusMeters = 1_000

        await store.startTrip()

        let startCalls = mockLiveActivity.startCalls
        #expect(startCalls.count == 1)
        #expect(startCalls.first?.destination.id == Destination.asok.id)
        #expect(startCalls.first?.alertRadius == 1_000)

        store.stopTrip()

        let endCount = mockLiveActivity.endCallCount
        #expect(endCount == 1)
    }

    @Test("Location updates push remaining distance to Live Activity")
    @MainActor
    func testLocationUpdatesLiveActivity() async {
        let mockLocation = TestLocationClient()
        let mockNotification = TestNotificationClient()
        let mockPersistence = NoopTripPersistence()
        let mockLiveActivity = MockLiveActivityManager()

        let store = TripStore(
            locationClient: mockLocation,
            notificationClient: mockNotification,
            persistence: mockPersistence,
            liveActivityManager: mockLiveActivity
        )

        store.selectDestination(.asok)
        store.selectedRadiusMeters = 500

        await store.startTrip()

        // Emit a location update
        let sample = LocationSample(
            coordinate: Destination.asok.coordinate,
            horizontalAccuracy: 10,
            timestamp: Date(),
            speed: nil,
            course: nil
        )
        await store.processLocationEvent(.sample(sample))

        let updateCalls = mockLiveActivity.updateCalls
        #expect(!updateCalls.isEmpty)
    }
}

// MARK: - Test Doubles
@MainActor
private final class TestLocationClient: LocationProviding {
    private var continuation: AsyncStream<LocationEvent>.Continuation?

    func requestWhenInUseAuthorization() {}

    func startUpdates() -> AsyncStream<LocationEvent> {
        AsyncStream { continuation in
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
private final class TestNotificationClient: NotificationProviding {
    func authorizationIsGranted() async -> Bool { true }
    func requestAuthorizationIfNeeded() async -> Bool { true }
    func readiness() async -> AlarmReadiness {
        AlarmReadiness(
            permission: .authorized,
            alertsEnabled: true,
            soundsEnabled: true,
            lockScreenEnabled: true,
            timeSensitiveSetting: .enabled
        )
    }
    func prominentAlarmAuthorizationIsGranted() async -> Bool { false }
    func requestProminentAlarmAuthorizationIfAvailable() async -> Bool { false }
    func sendArrivalAlert(destination: Destination, distanceMeters: Double) async throws {}
    func sendTestAlert() async throws {}
    func scheduleSnoozeAlert(destination: Destination, after delay: TimeInterval) async throws {}
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
