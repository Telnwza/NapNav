import Foundation

struct LocationCoordinate: Codable, Equatable, Hashable, Sendable {
    let latitude: Double
    let longitude: Double
}

struct Destination: Codable, Identifiable, Equatable, Hashable, Sendable {
    let id: String
    let name: String
    let detail: String
    let coordinate: LocationCoordinate

    static var asok: Destination {
        Destination(
            id: "asok-bts",
            name: AppLocalization.string("อโศก"),
            detail: AppLocalization.string("สถานี BTS อโศก ถนนสุขุมวิท"),
            coordinate: LocationCoordinate(latitude: 13.7367, longitude: 100.5604)
        )
    }
}

struct LocationSample: Equatable, Sendable {
    let coordinate: LocationCoordinate
    let horizontalAccuracy: Double
    let timestamp: Date
    let speed: Double?
    let course: Double?
}

enum TripPhase: String, Codable, Equatable, Sendable {
    case idle
    case preparing
    case tracking
    case approaching
    case alarm
    case arrived
    case completed
    case cancelled

    var isActive: Bool {
        switch self {
        case .tracking, .approaching, .alarm, .arrived:
            true
        case .idle, .preparing, .completed, .cancelled:
            false
        }
    }

    var title: String {
        switch self {
        case .idle: AppLocalization.string("ยังไม่เริ่มทริป")
        case .preparing: AppLocalization.string("กำลังเตรียมพร้อม")
        case .tracking: AppLocalization.string("กำลังเดินทาง")
        case .approaching: AppLocalization.string("ใกล้ถึงแล้ว")
        case .alarm: AppLocalization.string("กำลังเตือน")
        case .arrived: AppLocalization.string("ถึงจุดหมายแล้ว")
        case .completed: AppLocalization.string("ทริปเสร็จสิ้น")
        case .cancelled: AppLocalization.string("ยกเลิกแล้ว")
        }
    }
}

struct TripStopConfirmationRequest: Identifiable, Equatable, Sendable {
    enum Action: Equatable, Sendable {
        case stop
        case finish
    }

    let tripID: UUID
    let destinationName: String
    let action: Action

    var id: UUID { tripID }
}

enum ArrivalStatus: Equatable, Sendable {
    case outside
    case nearby
    case arrived
}

enum TripHealth: Equatable, Sendable {
    case ready
    case locationUnavailable
    case staleLocation
    case reducedAccuracy
    case notificationUnavailable
    case alertCleanupFailed
    case persistenceUnavailable
}

enum NotificationCleanupStatus: Equatable, Sendable {
    case notRequested
    case requestsRemoved
}

enum AlarmKitCancellationOutcome: Equatable, Sendable {
    case cancelled(UUID)
    case alreadyAbsent(UUID)
    case failed(UUID, reason: String)
    case unsupported(UUID)

    var alarmID: UUID {
        switch self {
        case .cancelled(let id), .alreadyAbsent(let id), .failed(let id, _), .unsupported(let id):
            id
        }
    }

    var didFail: Bool {
        switch self {
        case .failed, .unsupported:
            true
        case .cancelled, .alreadyAbsent:
            false
        }
    }

    var isResolved: Bool {
        switch self {
        case .cancelled, .alreadyAbsent:
            true
        case .failed, .unsupported:
            false
        }
    }
}

struct AlertCancellationResult: Equatable, Sendable {
    var notificationCleanup: NotificationCleanupStatus
    var alarmKitOutcomes: [AlarmKitCancellationOutcome]
    var alarmKitEnumerationFailure: String?
    var alarmKitEnumerationCompleted: Bool

    init(
        notificationCleanup: NotificationCleanupStatus = .notRequested,
        alarmKitOutcomes: [AlarmKitCancellationOutcome] = [],
        alarmKitEnumerationFailure: String? = nil,
        alarmKitEnumerationCompleted: Bool = false
    ) {
        self.notificationCleanup = notificationCleanup
        self.alarmKitOutcomes = alarmKitOutcomes
        self.alarmKitEnumerationFailure = alarmKitEnumerationFailure
        self.alarmKitEnumerationCompleted = alarmKitEnumerationCompleted
    }

    var failedAlarmIdentifiers: Set<UUID> {
        Set(alarmKitOutcomes.filter(\.didFail).map(\.alarmID))
    }

    var hasFailures: Bool {
        alarmKitEnumerationFailure != nil || alarmKitOutcomes.contains(where: \.didFail)
    }

    var resolvedAlarmIdentifiers: Set<UUID> {
        Set(alarmKitOutcomes.filter(\.isResolved).map(\.alarmID))
    }

    var didResolveAlarmCancellation: Bool {
        resolvedAlarmIdentifiers.isEmpty == false || alarmKitEnumerationCompleted
    }
}

enum MapDisplayStyle: String, CaseIterable, Identifiable, Equatable, Sendable {
    case explore
    case driving
    case transit
    case satellite

    var id: Self { self }

    var title: String {
        switch self {
        case .explore: AppLocalization.string("สำรวจ")
        case .driving: AppLocalization.string("ขับรถ")
        case .transit: AppLocalization.string("ขนส่ง")
        case .satellite: AppLocalization.string("ดาวเทียม")
        }
    }

    var systemImage: String {
        switch self {
        case .explore: "map.fill"
        case .driving: "car.fill"
        case .transit: "tram.fill"
        case .satellite: "globe.asia.australia.fill"
        }
    }
}

enum NotificationPermissionState: Equatable, Sendable {
    case unknown
    case notDetermined
    case denied
    case authorized
}

enum NotificationSettingState: Equatable, Sendable {
    case enabled
    case disabled
    case notSupported
    case unknown

    var title: String {
        switch self {
        case .enabled: AppLocalization.string("เปิด")
        case .disabled: AppLocalization.string("ปิด")
        case .notSupported: AppLocalization.string("ไม่รองรับ")
        case .unknown: AppLocalization.string("ไม่ทราบ")
        }
    }
}

struct AlarmReadiness: Equatable, Sendable {
    var permission: NotificationPermissionState
    var alertsEnabled: Bool
    var soundsEnabled: Bool
    var lockScreenEnabled: Bool
    var timeSensitiveSetting: NotificationSettingState

    static let unknown = AlarmReadiness(
        permission: .unknown,
        alertsEnabled: false,
        soundsEnabled: false,
        lockScreenEnabled: false,
        timeSensitiveSetting: .unknown
    )

    var canDeliverVisibleAlert: Bool {
        permission == .authorized && alertsEnabled
    }
}

enum MapPickerState: Equatable, Sendable {
    case idle
    case moving
    case resolving
    case ready
    case fallback
}

enum AppLaunchState: Equatable, Sendable {
    case launching(message: String)
    case recoveringTrip(message: String)
    case awaitingTripRecovery(destinationName: String)
    case ready
    case failed(message: String)
}

struct DestinationResolution: Equatable, Sendable {
    let destination: Destination
    let isFallback: Bool
}

struct ActiveTripSnapshot: Codable, Equatable, Sendable {
    let id: UUID
    let destination: Destination
    let radiusMeters: Double
    let startedAt: Date
    let phase: TripPhase
    let alertTriggered: Bool
    let alertSent: Bool
    let prominentAlarmIdentifier: UUID?
    let autoStopAt: Date?
    let snoozeAt: Date?

    init(
        id: UUID = UUID(),
        destination: Destination,
        radiusMeters: Double,
        startedAt: Date,
        phase: TripPhase = .tracking,
        alertTriggered: Bool = false,
        alertSent: Bool = false,
        prominentAlarmIdentifier: UUID? = nil,
        autoStopAt: Date? = nil,
        snoozeAt: Date? = nil
    ) {
        self.id = id
        self.destination = destination
        self.radiusMeters = radiusMeters
        self.startedAt = startedAt
        self.phase = phase
        self.alertTriggered = alertTriggered
        self.alertSent = alertSent
        self.prominentAlarmIdentifier = prominentAlarmIdentifier
        self.autoStopAt = autoStopAt
        self.snoozeAt = snoozeAt
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case destination
        case radiusMeters
        case startedAt
        case phase
        case alertTriggered
        case alertSent
        case prominentAlarmIdentifier
        case autoStopAt
        case snoozeAt
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        destination = try container.decode(Destination.self, forKey: .destination)
        radiusMeters = try container.decode(Double.self, forKey: .radiusMeters)
        startedAt = try container.decode(Date.self, forKey: .startedAt)
        phase = try container.decodeIfPresent(TripPhase.self, forKey: .phase) ?? .tracking
        alertTriggered = try container.decodeIfPresent(Bool.self, forKey: .alertTriggered) ?? false
        alertSent = try container.decodeIfPresent(Bool.self, forKey: .alertSent) ?? false
        prominentAlarmIdentifier = try container.decodeIfPresent(UUID.self, forKey: .prominentAlarmIdentifier)
        autoStopAt = try container.decodeIfPresent(Date.self, forKey: .autoStopAt)
        snoozeAt = try container.decodeIfPresent(Date.self, forKey: .snoozeAt)
    }
}

enum LiveLocationStatus: Equatable, Sendable {
    case idle
    case requestingPermission
    case receiving
    case accuracyLimited
    case unavailable
    case denied
    case servicesDisabled
    case failed(String)
}

enum LocationEvent: Equatable, Sendable {
    case sample(LocationSample)
    case accuracyLimited
    case unavailable
    case authorizationDenied
    case servicesDisabled
    case failed(String)
}

enum LocationRejectionReason: Equatable, Sendable {
    case invalidAccuracy
    case stale
    case inaccurate
}

enum TriggerDecision: Equatable, Sendable {
    case rejected(LocationRejectionReason)
    case outside(distanceMeters: Double)
    case uncertain(distanceMeters: Double)
    case approaching(distanceMeters: Double)
    case trigger(distanceMeters: Double)
}

enum ArrivalDecision: Equatable, Sendable {
    case rejected(LocationRejectionReason)
    case outside(distanceMeters: Double)
    case nearbyUncertain(distanceMeters: Double)
    case confirming(distanceMeters: Double)
    case arrived(distanceMeters: Double)
}

enum AlertDeliveryMode: String, CaseIterable, Identifiable, Codable, Sendable {
    case notification = "notification"
    case alarmKit = "alarmKit"
    case both = "both"

    var id: Self { self }

    var title: String {
        switch self {
        case .notification: AppLocalization.string("การแจ้งเตือนทั่วไป")
        case .alarmKit: AppLocalization.string("ระบบนาฬิกาปลุก")
        case .both: AppLocalization.string("เตือนทั้งสองแบบ")
        }
    }

    var subtitle: String {
        switch self {
        case .notification: AppLocalization.string("ส่งเสียงเตือนและแบนเนอร์แบบด่วน")
        case .alarmKit: AppLocalization.string("ใช้ AlarmKit เมื่อรองรับและได้รับอนุญาต (iOS 26+)")
        case .both: AppLocalization.string("ใช้ AlarmKit เป็นเสียงหลัก พร้อม Notification แบบไม่มีเสียง")
        }
    }

    var systemImage: String {
        switch self {
        case .notification: "bell.badge.fill"
        case .alarmKit: "alarm.fill"
        case .both: "bell.and.waves.left.and.right.fill"
        }
    }
}

enum AlertSoundMode: String, CaseIterable, Identifiable, Codable, Sendable {
    case soundAndHaptic = "soundAndHaptic"

    var id: Self { self }

    var title: String {
        switch self {
        case .soundAndHaptic: AppLocalization.string("มีเสียง")
        }
    }

    var subtitle: String {
        switch self {
        case .soundAndHaptic: AppLocalization.string("ใช้เสียงของ Notification หรือ AlarmKit ตามโหมดที่เลือก")
        }
    }

    var systemImage: String {
        switch self {
        case .soundAndHaptic: "speaker.wave.2.fill"
        }
    }
}

enum NotificationSoundBehavior: Equatable, Hashable, Sendable {
    case audible
    case silentByChoice
    case mutedBySystem
    case silentCompanion

    var includesSound: Bool {
        self == .audible
    }

    var summary: String {
        switch self {
        case .audible:
            AppLocalization.string("Notification พร้อมเสียง")
        case .silentByChoice:
            AppLocalization.string("Notification แบบไม่มีเสียง (iOS อาจไม่สั่น)")
        case .mutedBySystem:
            AppLocalization.string("Notification จะแสดง แต่เสียงถูกปิดในการตั้งค่า iPhone")
        case .silentCompanion:
            AppLocalization.string("Notification แบบไม่มีเสียง เพื่อไม่ให้เสียงซ้อน")
        }
    }
}

enum AlertDeliveryPath: Equatable, Hashable, Sendable {
    case notification(sound: NotificationSoundBehavior)
    case alarmKit
}

enum AlertDeliveryFallbackReason: Equatable, Sendable {
    case alarmKitUnsupported
    case alarmKitNotAuthorized
    case alarmKitCannotHonorSilentMode
    case notificationUnavailable
    case alarmSchedulingFailed

    var summary: String {
        switch self {
        case .alarmKitUnsupported:
            AppLocalization.string("เครื่องนี้ยังไม่รองรับ AlarmKit จึงใช้ Notification แทน")
        case .alarmKitNotAuthorized:
            AppLocalization.string("AlarmKit ยังไม่ได้รับอนุญาต จึงใช้ Notification แทน")
        case .alarmKitCannotHonorSilentMode:
            AppLocalization.string("AlarmKit ไม่มีโหมดไม่มีเสียง จึงใช้ Notification แบบไม่มีเสียงแทน")
        case .notificationUnavailable:
            AppLocalization.string("Notification ไม่พร้อม จึงใช้ AlarmKit เพียงช่องทางเดียว")
        case .alarmSchedulingFailed:
            AppLocalization.string("ตั้ง AlarmKit ไม่สำเร็จ จึงใช้ Notification แทน")
        }
    }
}

enum AlertDeliveryUnavailableReason: Equatable, Sendable {
    case notificationUnavailable
    case silentDeliveryUnavailable
    case noAvailablePath
    case notificationSchedulingFailed
    case alarmSchedulingFailed

    var summary: String {
        switch self {
        case .notificationUnavailable:
            AppLocalization.string("Notification ยังไม่พร้อม กรุณาเปิดการแจ้งเตือนในการตั้งค่า iPhone")
        case .silentDeliveryUnavailable:
            AppLocalization.string("โหมดไม่มีเสียงต้องใช้ Notification แต่ Notification ยังไม่พร้อม")
        case .noAvailablePath:
            AppLocalization.string("ยังไม่มีช่องทางเตือนที่พร้อมใช้งาน กรุณาตรวจสิทธิ์การแจ้งเตือน")
        case .notificationSchedulingFailed:
            AppLocalization.string("ส่ง Notification ไม่สำเร็จ กรุณาตรวจการตั้งค่าแล้วลองใหม่")
        case .alarmSchedulingFailed:
            AppLocalization.string("ตั้ง AlarmKit ไม่สำเร็จและไม่มี Notification สำหรับ fallback")
        }
    }
}

struct AlertDeliveryCapabilities: Equatable, Sendable {
    var notificationReady: Bool
    var notificationSoundsEnabled: Bool
    var alarmKitSupported: Bool
    var alarmKitAuthorized: Bool
}

struct AlertDeliveryPlan: Equatable, Sendable {
    var paths: [AlertDeliveryPath]
    var fallbackReason: AlertDeliveryFallbackReason?
    var unavailableReason: AlertDeliveryUnavailableReason?

    var isAvailable: Bool {
        paths.isEmpty == false && unavailableReason == nil
    }

    var usesFallback: Bool {
        fallbackReason != nil
    }

    var summary: String {
        if let unavailableReason {
            return unavailableReason.summary
        }

        let routeSummary: String
        if paths.contains(.alarmKit),
           paths.contains(.notification(sound: .silentCompanion)) {
            routeSummary = AppLocalization.string("จะใช้ AlarmKit พร้อม Notification แบบไม่มีเสียง เพื่อไม่ให้เสียงซ้อน")
        } else if paths.contains(.alarmKit) {
            routeSummary = AppLocalization.string("จะใช้ AlarmKit เป็นเสียงเตือนหลัก")
        } else if case .notification(let sound)? = paths.first {
            routeSummary = AppLocalization.format("จะใช้ %@", sound.summary)
        } else {
            routeSummary = AppLocalization.string("ยังไม่มีช่องทางเตือนที่พร้อมใช้งาน")
        }

        if let fallbackReason {
            return AppLocalization.format("%@ — %@", routeSummary, fallbackReason.summary)
        }
        return routeSummary
    }
}

enum AlertDeliveryResult: Equatable, Sendable {
    case alarmScheduled(companionNotificationScheduled: Bool)
    case notificationScheduled(sound: NotificationSoundBehavior)
    case fallbackUsed(
        from: AlertDeliveryMode,
        to: AlertDeliveryPath,
        reason: AlertDeliveryFallbackReason
    )
    case deliveryUnavailable(reason: AlertDeliveryUnavailableReason)

    var didDeliver: Bool {
        if case .deliveryUnavailable = self { return false }
        return true
    }

    var usesProminentAlarm: Bool {
        switch self {
        case .alarmScheduled:
            true
        case .fallbackUsed(_, let path, _):
            path == .alarmKit
        case .notificationScheduled, .deliveryUnavailable:
            false
        }
    }

    var summary: String {
        switch self {
        case .alarmScheduled(let companionNotificationScheduled):
            return companionNotificationScheduled
                ? AppLocalization.string("ตั้ง AlarmKit แล้ว พร้อม Notification แบบไม่มีเสียง")
                : AppLocalization.string("ตั้ง AlarmKit แล้ว โดยไม่มี companion Notification")
        case .notificationScheduled(let sound):
            return AppLocalization.format("ส่งผ่าน %@ แล้ว", sound.summary)
        case .fallbackUsed(_, let path, let reason):
            if case .notification(let sound) = path, sound == .mutedBySystem {
                return AppLocalization.format("%@ — %@", reason.summary, sound.summary)
            }
            return reason.summary
        case .deliveryUnavailable(let reason):
            return reason.summary
        }
    }
}

struct AlertDeliveryPolicy {
    static func plan(
        preferences: UserAlertPreferences,
        capabilities: AlertDeliveryCapabilities
    ) -> AlertDeliveryPlan {
        let notificationSound = notificationSoundBehavior(
            for: preferences.soundMode,
            soundsEnabled: capabilities.notificationSoundsEnabled
        )

        func notificationPlan(
            fallbackReason: AlertDeliveryFallbackReason? = nil,
            unavailableReason: AlertDeliveryUnavailableReason = .notificationUnavailable
        ) -> AlertDeliveryPlan {
            guard capabilities.notificationReady else {
                return AlertDeliveryPlan(
                    paths: [],
                    fallbackReason: fallbackReason,
                    unavailableReason: unavailableReason
                )
            }
            return AlertDeliveryPlan(
                paths: [.notification(sound: notificationSound)],
                fallbackReason: fallbackReason,
                unavailableReason: nil
            )
        }

        switch preferences.deliveryMode {
        case .notification:
            return notificationPlan(
                unavailableReason: .notificationUnavailable
            )

        case .alarmKit:
            if capabilities.alarmKitSupported, capabilities.alarmKitAuthorized {
                return AlertDeliveryPlan(paths: [.alarmKit], fallbackReason: nil, unavailableReason: nil)
            }
            return notificationPlan(
                fallbackReason: capabilities.alarmKitSupported
                    ? .alarmKitNotAuthorized
                    : .alarmKitUnsupported,
                unavailableReason: .noAvailablePath
            )

        case .both:
            guard capabilities.alarmKitSupported, capabilities.alarmKitAuthorized else {
                return notificationPlan(
                    fallbackReason: capabilities.alarmKitSupported
                        ? .alarmKitNotAuthorized
                        : .alarmKitUnsupported,
                    unavailableReason: .noAvailablePath
                )
            }
            if capabilities.notificationReady {
                return AlertDeliveryPlan(
                    paths: [.alarmKit, .notification(sound: .silentCompanion)],
                    fallbackReason: nil,
                    unavailableReason: nil
                )
            }
            return AlertDeliveryPlan(
                paths: [.alarmKit],
                fallbackReason: .notificationUnavailable,
                unavailableReason: nil
            )
        }
    }

    static func notificationSoundBehavior(
        for mode: AlertSoundMode,
        soundsEnabled: Bool
    ) -> NotificationSoundBehavior {
        soundsEnabled ? .audible : .mutedBySystem
    }
}

enum AutoStopDelay: Int, CaseIterable, Identifiable, Codable, Sendable {
    case immediately = 0
    case fiveSeconds = 5
    case tenSeconds = 10
    case fifteenSeconds = 15
    case thirtySeconds = 30
    case fortyFiveSeconds = 45
    case sixtySeconds = 60

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .immediately: AppLocalization.string("ทันที")
        case .fiveSeconds: AppLocalization.string("5 วินาที")
        case .tenSeconds: AppLocalization.string("10 วินาที")
        case .fifteenSeconds: AppLocalization.string("15 วินาที")
        case .thirtySeconds: AppLocalization.string("30 วินาที (แนะนำ)")
        case .fortyFiveSeconds: AppLocalization.string("45 วินาที")
        case .sixtySeconds: AppLocalization.string("60 วินาที (1 นาที)")
        }
    }

    var shortTitle: String {
        switch self {
        case .immediately: AppLocalization.string("ทันที")
        case .fiveSeconds: AppLocalization.string("5 วิ")
        case .tenSeconds: AppLocalization.string("10 วิ")
        case .fifteenSeconds: AppLocalization.string("15 วิ")
        case .thirtySeconds: AppLocalization.string("30 วิ")
        case .fortyFiveSeconds: AppLocalization.string("45 วิ")
        case .sixtySeconds: AppLocalization.string("60 วิ")
        }
    }

    var timeInterval: TimeInterval {
        TimeInterval(rawValue)
    }
}

struct UserAlertPreferences: Codable, Equatable, Sendable {
    var deliveryMode: AlertDeliveryMode = .notification
    var soundMode: AlertSoundMode = .soundAndHaptic
    var autoStopDelay: AutoStopDelay = .sixtySeconds

    static let `default` = UserAlertPreferences()

    enum CodingKeys: String, CodingKey {
        case deliveryMode
        case soundMode
        case autoStopDelay
    }

    init(
        deliveryMode: AlertDeliveryMode = .notification,
        soundMode: AlertSoundMode = .soundAndHaptic,
        autoStopDelay: AutoStopDelay = .sixtySeconds
    ) {
        self.deliveryMode = deliveryMode
        self.soundMode = soundMode
        self.autoStopDelay = autoStopDelay
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let modeString = try container.decodeIfPresent(String.self, forKey: .deliveryMode) {
            if modeString == "auto" {
                self.deliveryMode = .notification
            } else {
                self.deliveryMode = AlertDeliveryMode(rawValue: modeString) ?? .notification
            }
        } else {
            self.deliveryMode = .notification
        }
        self.soundMode = .soundAndHaptic
        self.autoStopDelay = try container.decodeIfPresent(AutoStopDelay.self, forKey: .autoStopDelay) ?? .sixtySeconds
    }
}


enum SavedDestinationIcon: String, CaseIterable, Identifiable, Codable, Sendable {
    case house = "house.fill"
    case briefcase = "briefcase.fill"
    case education = "graduationcap.fill"
    case star = "star.fill"
    case pin = "mappin"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .house: AppLocalization.string("บ้าน")
        case .briefcase: AppLocalization.string("ที่ทำงาน")
        case .education: AppLocalization.string("สถานศึกษา")
        case .star: AppLocalization.string("สถานที่โปรด")
        case .pin: AppLocalization.string("หมุด")
        }
    }
}

struct SavedDestination: Identifiable, Codable, Equatable, Sendable {
    let id: UUID
    var title: String
    var subtitle: String
    var coordinate: LocationCoordinate
    var radiusMeters: Double
    var icon: SavedDestinationIcon
    var isFavorite: Bool
    var lastUsedAt: Date

    init(
        id: UUID = UUID(),
        title: String,
        subtitle: String,
        coordinate: LocationCoordinate,
        radiusMeters: Double = 1_000,
        icon: SavedDestinationIcon = .star,
        isFavorite: Bool = false,
        lastUsedAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.coordinate = coordinate
        self.radiusMeters = radiusMeters
        self.icon = icon
        self.isFavorite = isFavorite
        self.lastUsedAt = lastUsedAt
    }

    var asDestination: Destination {
        Destination(
            id: id.uuidString,
            name: title,
            detail: subtitle,
            coordinate: coordinate
        )
    }
}
