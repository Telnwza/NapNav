import Foundation

private final class LocalizationBundleAnchor {}

enum AppLanguage: String, CaseIterable, Identifiable, Sendable {
    case system
    case thai = "th"
    case english = "en"

    var id: Self { self }

    var locale: Locale {
        switch self {
        case .system:
            .autoupdatingCurrent
        case .thai:
            Locale(identifier: "th")
        case .english:
            Locale(identifier: "en")
        }
    }

    var resolvedIdentifier: String {
        switch self {
        case .system:
            let supported = ["th", "en"]
            let matched = Bundle.preferredLocalizations(from: supported, forPreferences: Locale.preferredLanguages)
            return matched.first ?? "th"
        case .thai:
            return "th"
        case .english:
            return "en"
        }
    }

    var titleKey: String {
        switch self {
        case .system: "ตามระบบ"
        case .thai: "ไทย"
        case .english: "English"
        }
    }
}

enum AppLocalization {
    static let preferenceKey = "appLanguage"

    static var selectedLanguage: AppLanguage {
        guard let storedValue = UserDefaults.standard.string(forKey: preferenceKey) else {
            return .system
        }
        return AppLanguage(rawValue: storedValue) ?? .system
    }

    static var locale: Locale {
        selectedLanguage.locale
    }

    static func bundle(for language: AppLanguage = selectedLanguage) -> Bundle {
        let identifier = language.resolvedIdentifier
        let anchorBundle = Bundle(for: LocalizationBundleAnchor.self)
        if let path = anchorBundle.path(forResource: identifier, ofType: "lproj"),
           let bundle = Bundle(path: path) {
            return bundle
        }
        if let path = Bundle.main.path(forResource: identifier, ofType: "lproj"),
           let bundle = Bundle(path: path) {
            return bundle
        }
        return anchorBundle
    }

    static func string(
        _ key: String,
        language: AppLanguage = selectedLanguage
    ) -> String {
        let targetBundle = bundle(for: language)
        return targetBundle.localizedString(forKey: key, value: key, table: nil)
    }

    static func format(
        _ key: String,
        _ arguments: CVarArg...,
        language: AppLanguage = selectedLanguage
    ) -> String {
        let formatTemplate = string(key, language: language)
        return String(
            format: formatTemplate,
            locale: language.locale,
            arguments: arguments
        )
    }
}
