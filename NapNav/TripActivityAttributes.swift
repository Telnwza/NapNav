import Foundation
import SwiftUI
#if canImport(UIKit)
import UIKit
#endif
#if canImport(ActivityKit)
import ActivityKit
#endif

public enum AppTheme {
    /// #10B981 - Primary modern emerald / mint green
    public static let primary = Color(red: 16.0 / 255.0, green: 185.0 / 255.0, blue: 129.0 / 255.0)

    /// #A7F3D0 - Secondary soft mint
    public static let secondary = Color(red: 167.0 / 255.0, green: 243.0 / 255.0, blue: 208.0 / 255.0)

    /// #065F46 - Dark deep emerald
    public static let dark = Color(red: 6.0 / 255.0, green: 95.0 / 255.0, blue: 70.0 / 255.0)

    public static let primaryButtonFill = primary
    public static let actionForeground = primary

    /// #ECFDF5 - Background soft mint wash
    public static let backgroundTint = Color(red: 236.0 / 255.0, green: 253.0 / 255.0, blue: 245.0 / 255.0)

    #if canImport(UIKit)
    public static let uiPrimary = UIColor(red: 16.0 / 255.0, green: 185.0 / 255.0, blue: 129.0 / 255.0, alpha: 1.0)
    public static let uiSecondary = UIColor(red: 167.0 / 255.0, green: 243.0 / 255.0, blue: 208.0 / 255.0, alpha: 1.0)
    public static let uiDark = UIColor(red: 6.0 / 255.0, green: 95.0 / 255.0, blue: 70.0 / 255.0, alpha: 1.0)
    public static let uiBackgroundTint = UIColor(red: 236.0 / 255.0, green: 253.0 / 255.0, blue: 245.0 / 255.0, alpha: 1.0)
    #endif
}


#if canImport(ActivityKit)
public struct TripActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable, Sendable {
        public var remainingDistanceMeters: Double
        public var alertRadiusMeters: Double
        public var initialDistanceMeters: Double
        public var isAlertTriggered: Bool
        public var isArrived: Bool
        public var autoStopAt: Date?
        public var languageCode: String?
        public var lastUpdatedAt: Date

        public init(
            remainingDistanceMeters: Double,
            alertRadiusMeters: Double,
            initialDistanceMeters: Double,
            isAlertTriggered: Bool = false,
            isArrived: Bool = false,
            autoStopAt: Date? = nil,
            languageCode: String? = nil,
            lastUpdatedAt: Date = Date()
        ) {
            self.remainingDistanceMeters = remainingDistanceMeters
            self.alertRadiusMeters = alertRadiusMeters
            self.initialDistanceMeters = initialDistanceMeters
            self.isAlertTriggered = isAlertTriggered
            self.isArrived = isArrived
            self.autoStopAt = autoStopAt
            self.languageCode = languageCode
            self.lastUpdatedAt = lastUpdatedAt
        }

        public static func formatDistance(_ meters: Double, languageCode: String = "en") -> String {
            let isThai = languageCode.hasPrefix("th")
            if meters >= 1_000 {
                let km = meters / 1_000.0
                let unit = isThai ? "กม." : "km"
                if km.truncatingRemainder(dividingBy: 1) == 0 {
                    return String(format: "%.0f %@", km, unit)
                } else {
                    return String(format: "%.1f %@", km, unit)
                }
            } else {
                let m = max(0, Int(meters.rounded()))
                let unit = isThai ? "ม." : "m"
                return "\(m) \(unit)"
            }
        }

        public func formattedRemainingDistance(languageCode: String = "en") -> String {
            Self.formatDistance(remainingDistanceMeters, languageCode: languageCode)
        }

        public func formattedAlertRadius(languageCode: String = "en") -> String {
            Self.formatDistance(alertRadiusMeters, languageCode: languageCode)
        }

        public var formattedRemainingDistance: String {
            formattedRemainingDistance(languageCode: languageCode ?? "en")
        }

        public var formattedAlertRadius: String {
            formattedAlertRadius(languageCode: languageCode ?? "en")
        }

        public var progressFraction: Double {
            if isArrived { return 1.0 }
            guard initialDistanceMeters > 0 else { return 0.0 }
            let traveled = initialDistanceMeters - remainingDistanceMeters
            let fraction = traveled / initialDistanceMeters
            return min(max(fraction, 0.0), 1.0)
        }

        public var statusTitle: String {
            statusTitle(for: .thai)
        }

        func statusTitle(for language: AppLanguage) -> String {
            if isArrived {
                return AppLocalization.string("ถึงแล้ว", language: language)
            } else if isAlertTriggered || remainingDistanceMeters <= alertRadiusMeters {
                return AppLocalization.string("ใกล้ถึง", language: language)
            } else {
                return AppLocalization.string("กำลังเดินทาง", language: language)
            }
        }

        func resolvedLanguage(fallback: String) -> AppLanguage {
            let code = languageCode ?? fallback
            return AppLanguage(rawValue: code) ?? .system
        }

        public var statusIconName: String {
            if isArrived {
                return "checkmark.circle.fill"
            } else if isAlertTriggered || remainingDistanceMeters <= alertRadiusMeters {
                return "bell.badge.fill"
            } else {
                return "mappin.circle.fill"
            }
        }
    }

    public var destinationName: String
    public var destinationDetail: String
    public var languageCode: String

    public init(
        destinationName: String,
        destinationDetail: String,
        languageCode: String = "en"
    ) {
        self.destinationName = destinationName
        self.destinationDetail = destinationDetail
        self.languageCode = languageCode
    }

    var appLanguage: AppLanguage {
        AppLanguage(rawValue: languageCode) ?? .system
    }

    public var locale: Locale {
        Locale(identifier: languageCode)
    }
}
#endif
