import AppIntents
import Foundation

// MARK: - Siri App Intents

struct StartHomeTripIntent: AppIntent {
    static let title: LocalizedStringResource = "เริ่มทริปกลับบ้าน"
    static let description = IntentDescription("เริ่มการเดินทางและเปิดระบบเตือนไปยังหมุดบ้านทันที")
    static let openAppWhenRun: Bool = true

    func perform() async throws -> some IntentResult & OpensIntent {
        return .result(opensIntent: OpenURLIntent(URL(string: "napnav://start-home")!))
    }
}

struct StopAlarmIntent: AppIntent {
    static let title: LocalizedStringResource = "หยุดเสียงเตือนทันที"
    static let description = IntentDescription("หยุดเสียงแจ้งเตือนและยกเลิกทริปทันที")
    static let openAppWhenRun: Bool = true

    func perform() async throws -> some IntentResult & OpensIntent {
        return .result(opensIntent: OpenURLIntent(URL(string: "napnav://stop-alarm")!))
    }
}

// MARK: - Siri App Shortcuts Provider

struct NapNavShortcuts: AppShortcutsProvider {
    @AppShortcutsBuilder
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: StartHomeTripIntent(),
            phrases: [
                "กลับบ้านด้วย \(.applicationName)",
                "เริ่มทริปกลับบ้านด้วย \(.applicationName)",
                "Go home with \(.applicationName)",
                "Navigate home with \(.applicationName)"
            ],
            shortTitle: "กลับบ้าน",
            systemImageName: "house.fill"
        )
        AppShortcut(
            intent: StopAlarmIntent(),
            phrases: [
                "หยุดเสียงเตือนใน \(.applicationName)",
                "หยุดการเตือน \(.applicationName)",
                "ปิดเสียงเตือน \(.applicationName)",
                "Stop alarm in \(.applicationName)",
                "Silence \(.applicationName)"
            ],
            shortTitle: "หยุดเสียงเตือน",
            systemImageName: "bell.slash.fill"
        )
    }
}
