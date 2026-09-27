import Foundation
#if canImport(ActivityKit)
import ActivityKit
#endif

@MainActor
protocol LiveActivityManaging: AnyObject {
    func startTripActivity(
        destination: Destination,
        initialDistance: Double,
        alertRadius: Double
    )
    func updateTripActivity(
        remainingDistance: Double,
        isAlertTriggered: Bool,
        isArrived: Bool,
        autoStopAt: Date?
    )
    func updateTripActivity(
        remainingDistance: Double,
        initialDistance: Double?,
        languageCode: String?,
        isAlertTriggered: Bool,
        isArrived: Bool,
        autoStopAt: Date?
    )
    /// wasArrived: true  → แสดง "ถึงจุดหมาย" นาน 15 วิก่อนหายจาก Lock Screen
    /// wasArrived: false → หายทันที (cancelled/stopped)
    func endTripActivity(wasArrived: Bool)
    /// Ends every activity that survived a previous process. Use during launch
    /// before deciding whether a persisted trip should be resumed.
    func endAllTripActivities() async
}

extension LiveActivityManaging {
    func updateTripActivity(
        remainingDistance: Double,
        isAlertTriggered: Bool,
        isArrived: Bool,
        autoStopAt: Date? = nil
    ) {
        updateTripActivity(
            remainingDistance: remainingDistance,
            initialDistance: nil,
            languageCode: nil,
            isAlertTriggered: isAlertTriggered,
            isArrived: isArrived,
            autoStopAt: autoStopAt
        )
    }

    func updateTripActivity(
        remainingDistance: Double,
        initialDistance: Double?,
        languageCode: String?,
        isAlertTriggered: Bool,
        isArrived: Bool,
        autoStopAt: Date?
    ) {
        updateTripActivity(
            remainingDistance: remainingDistance,
            isAlertTriggered: isAlertTriggered,
            isArrived: isArrived,
            autoStopAt: autoStopAt
        )
    }

    func updateTripActivity(
        remainingDistance: Double,
        initialDistance: Double?,
        isAlertTriggered: Bool,
        isArrived: Bool
    ) {
        updateTripActivity(
            remainingDistance: remainingDistance,
            initialDistance: initialDistance,
            languageCode: nil,
            isAlertTriggered: isAlertTriggered,
            isArrived: isArrived,
            autoStopAt: nil
        )
    }

    /// Convenience no-arg variant (cancelled / non-arrival end)
    func endTripActivity() { endTripActivity(wasArrived: false) }

    func endAllTripActivities() async {}
}

#if canImport(ActivityKit)
private struct SendableActivityWrapper: @unchecked Sendable {
    let activity: Activity<TripActivityAttributes>

    func update(state: TripActivityAttributes.ContentState, staleDate: Date? = nil) async {
        let content = ActivityContent(
            state: state,
            staleDate: staleDate,
            relevanceScore: state.isArrived ? 100.0 : (state.isAlertTriggered ? 75.0 : 50.0)
        )
        await activity.update(content)
    }

    func end(state: TripActivityAttributes.ContentState, wasArrived: Bool) async {
        let policy: ActivityUIDismissalPolicy = wasArrived
            ? .after(Date().addingTimeInterval(15))
            : .immediate
        await activity.end(.init(state: state, staleDate: nil), dismissalPolicy: policy)
    }
}

@MainActor
final class LiveActivityClient: LiveActivityManaging {
    private var currentActivity: SendableActivityWrapper?
    private var initialDistance: Double = 0
    private var alertRadius: Double = 0
    private var isUpdating = false
    private var pendingUpdateState: (state: TripActivityAttributes.ContentState, staleDate: Date?)?

    init() {}

    func startTripActivity(
        destination: Destination,
        initialDistance: Double,
        alertRadius: Double
    ) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }

        // ปิด Activity เดิมก่อนเริ่มอันใหม่
        endTripActivity(wasArrived: false)

        for activity in Activity<TripActivityAttributes>.activities {
            let wrapper = SendableActivityWrapper(activity: activity)
            Task {
                await wrapper.end(state: activity.content.state, wasArrived: false)
            }
        }

        self.initialDistance = max(initialDistance, 1.0)
        self.alertRadius = alertRadius

        let lang = AppLocalization.selectedLanguage.resolvedIdentifier
        let attributes = TripActivityAttributes(
            destinationName: destination.name,
            destinationDetail: destination.detail,
            languageCode: lang
        )
        let initialState = TripActivityAttributes.ContentState(
            remainingDistanceMeters: initialDistance,
            alertRadiusMeters: alertRadius,
            initialDistanceMeters: self.initialDistance,
            isAlertTriggered: false,
            isArrived: false,
            autoStopAt: nil,
            languageCode: lang,
            lastUpdatedAt: Date()
        )

        do {
            let activity = try Activity<TripActivityAttributes>.request(
                attributes: attributes,
                content: .init(state: initialState, staleDate: nil, relevanceScore: 50.0),
                pushType: nil
            )
            self.currentActivity = SendableActivityWrapper(activity: activity)
        } catch {
            #if DEBUG
            print("❌ [LiveActivity] Failed to start Live Activity: \(error)")
            #endif
        }
    }

    func updateTripActivity(
        remainingDistance: Double,
        initialDistance: Double? = nil,
        languageCode: String? = nil,
        isAlertTriggered: Bool,
        isArrived: Bool,
        autoStopAt: Date? = nil
    ) {
        guard let current = currentActivity else { return }

        if let newInitial = initialDistance, newInitial > self.initialDistance {
            self.initialDistance = newInitial
        }

        let resolvedLanguage = languageCode ?? AppLocalization.selectedLanguage.resolvedIdentifier

        let updatedState = TripActivityAttributes.ContentState(
            remainingDistanceMeters: remainingDistance,
            alertRadiusMeters: alertRadius,
            initialDistanceMeters: self.initialDistance,
            isAlertTriggered: isAlertTriggered,
            isArrived: isArrived,
            autoStopAt: autoStopAt,
            languageCode: resolvedLanguage,
            lastUpdatedAt: Date()
        )

        scheduleUpdate(updatedState, staleDate: autoStopAt, on: current)
    }

    private func scheduleUpdate(
        _ state: TripActivityAttributes.ContentState,
        staleDate: Date?,
        on wrapper: SendableActivityWrapper
    ) {
        pendingUpdateState = (state, staleDate)
        guard !isUpdating else { return }
        isUpdating = true

        Task { [weak self] in
            while let self, let pending = self.pendingUpdateState {
                self.pendingUpdateState = nil
                await wrapper.update(state: pending.state, staleDate: pending.staleDate)
            }
            self?.isUpdating = false
        }
    }

    func endTripActivity(wasArrived: Bool) {
        pendingUpdateState = nil
        guard let current = currentActivity else { return }
        currentActivity = nil

        // Force arrived state in the final snapshot so Lock Screen always shows "ถึงจุดหมาย"
        // even if the live update task hasn't been applied yet (race-condition safety)
        var finalState = current.activity.content.state
        if wasArrived {
            finalState = TripActivityAttributes.ContentState(
                remainingDistanceMeters: finalState.remainingDistanceMeters,
                alertRadiusMeters: finalState.alertRadiusMeters,
                initialDistanceMeters: finalState.initialDistanceMeters,
                isAlertTriggered: true,
                isArrived: true,
                autoStopAt: finalState.autoStopAt,
                languageCode: finalState.languageCode,
                lastUpdatedAt: Date()
            )
        }
        Task {
            await current.end(state: finalState, wasArrived: wasArrived)
        }
    }

    func endAllTripActivities() async {
        pendingUpdateState = nil
        currentActivity = nil

        for activity in Activity<TripActivityAttributes>.activities {
            let wrapper = SendableActivityWrapper(activity: activity)
            await wrapper.end(state: activity.content.state, wasArrived: false)
        }
    }
}
#else
@MainActor
final class LiveActivityClient: LiveActivityManaging {
    init() {}
    func startTripActivity(destination: Destination, initialDistance: Double, alertRadius: Double) {}
    func updateTripActivity(remainingDistance: Double, initialDistance: Double?, languageCode: String?, isAlertTriggered: Bool, isArrived: Bool, autoStopAt: Date?) {}
    func endTripActivity(wasArrived: Bool) {}
    func endAllTripActivities() async {}
}
#endif

@MainActor
final class NoopLiveActivityManager: LiveActivityManaging {
    init() {}
    func startTripActivity(destination: Destination, initialDistance: Double, alertRadius: Double) {}
    func updateTripActivity(remainingDistance: Double, initialDistance: Double?, languageCode: String?, isAlertTriggered: Bool, isArrived: Bool, autoStopAt: Date?) {}
    func endTripActivity(wasArrived: Bool) {}
    func endAllTripActivities() async {}
}

@MainActor
final class MockLiveActivityManager: LiveActivityManaging {
    private(set) var startCalls: [(destination: Destination, initialDistance: Double, alertRadius: Double)] = []
    private(set) var updateCalls: [(remainingDistance: Double, isAlertTriggered: Bool, isArrived: Bool, autoStopAt: Date?)] = []
    private(set) var detailedUpdateCalls: [(remainingDistance: Double, initialDistance: Double?, languageCode: String?, isAlertTriggered: Bool, isArrived: Bool, autoStopAt: Date?)] = []
    private(set) var endCallCount: Int = 0
    private(set) var endAllCallCount: Int = 0
    private(set) var lastEndWasArrived: Bool = false

    init() {}

    func startTripActivity(destination: Destination, initialDistance: Double, alertRadius: Double) {
        startCalls.append((destination, initialDistance, alertRadius))
    }

    func updateTripActivity(
        remainingDistance: Double,
        initialDistance: Double? = nil,
        languageCode: String? = nil,
        isAlertTriggered: Bool,
        isArrived: Bool,
        autoStopAt: Date? = nil
    ) {
        updateCalls.append((remainingDistance, isAlertTriggered, isArrived, autoStopAt))
        detailedUpdateCalls.append((remainingDistance, initialDistance, languageCode, isAlertTriggered, isArrived, autoStopAt))
    }

    func endTripActivity(wasArrived: Bool) {
        endCallCount += 1
        lastEndWasArrived = wasArrived
    }

    func endAllTripActivities() async {
        endAllCallCount += 1
    }
}
