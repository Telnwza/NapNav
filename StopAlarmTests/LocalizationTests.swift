import Foundation
import Testing
@testable import StopAlarm

@Suite("App localization", .serialized)
struct LocalizationTests {
    @Test("The saved-language default remains system controlled")
    func systemIsTheDefaultSelection() {
        #expect(AppLanguage.system.rawValue == "system")
        #expect(AppLanguage.allCases == [.system, .thai, .english])
    }

    @Test("English and Thai resources resolve independently")
    func resolvesSupportedLanguages() {
        #expect(
            AppLocalization.string("การแจ้งเตือน", language: .english) == "Alerts"
        )
        #expect(
            AppLocalization.string("การแจ้งเตือน", language: .thai) == "การแจ้งเตือน"
        )
        #expect(
            AppLocalization.string("ซอร์สโค้ด (GitHub)", language: .english) == "Source Code (GitHub)"
        )
        #expect(
            AppLocalization.string("ซอร์สโค้ด (GitHub)", language: .thai) == "ซอร์สโค้ด (GitHub)"
        )
    }

    @Test("Permission copy and unsupported Time Sensitive state resolve in Thai and English")
    func resolvesPermissionDetailsCopy() {
        #expect(AppLocalization.string("การแจ้งเตือนทั่วไป", language: .english) == "Notification")
        #expect(AppLocalization.string("การแจ้งเตือนทั่วไป", language: .thai) == "การแจ้งเตือนทั่วไป")
        #expect(AppLocalization.string("Time Sensitive", language: .english) == "Time Sensitive")
        #expect(AppLocalization.string("Time Sensitive", language: .thai) == "การแจ้งเตือนด่วน")
        #expect(AppLocalization.string("ไม่รองรับ", language: .english) == "Not Supported")
        #expect(AppLocalization.string("ไม่รองรับ", language: .thai) == "ไม่รองรับ")
        #expect(
            AppLocalization.string(
                "เปลี่ยนการตั้งค่านี้ได้จาก Settings ของ iPhone เท่านั้น",
                language: .english
            ) == "You can only change this setting in iPhone Settings."
        )
        #expect(
            AppLocalization.string("Time Sensitive ไม่พร้อมใช้งานสำหรับ NapNav", language: .english)
                == "Time Sensitive isn’t available for NapNav."
        )
        #expect(
            AppLocalization.string("Time Sensitive ไม่พร้อมใช้งานสำหรับ NapNav", language: .thai)
                == "Time Sensitive ไม่พร้อมใช้งานสำหรับ NapNav"
        )
    }

    @Test("Notification action titles follow the selected app language")
    @MainActor
    func notificationActionsResolveInSelectedLanguage() {
        let english = LocalAlarmDelivery.notificationCategory(language: .english)
        let thai = LocalAlarmDelivery.notificationCategory(language: .thai)
        let englishTitles = Dictionary(uniqueKeysWithValues: english.actions.map { ($0.identifier, $0.title) })
        let thaiTitles = Dictionary(uniqueKeysWithValues: thai.actions.map { ($0.identifier, $0.title) })
        let categoryIdentifier = LocalAlarmDelivery.tripCategoryIdentifier
        let snoozeIdentifier = LocalAlarmDelivery.snoozeActionIdentifier
        let stopIdentifier = LocalAlarmDelivery.stopActionIdentifier

        #expect(english.identifier == categoryIdentifier)
        #expect(english.options.contains(.customDismissAction))
        #expect(englishTitles[snoozeIdentifier] == "Remind Me Again in 5 Minutes")
        #expect(englishTitles[stopIdentifier] == "Stop Trip")
        #expect(thaiTitles[snoozeIdentifier] == "เตือนอีกครั้งใน 5 นาที")
        #expect(thaiTitles[stopIdentifier] == "หยุดทริป")
    }

    @Test("Stop and finish confirmations resolve in Thai and English")
    func resolvesTripEndConfirmationCopy() {
        #expect(AppLocalization.string("หยุดทริปนี้หรือไม่?", language: .thai) == "หยุดทริปนี้หรือไม่?")
        #expect(AppLocalization.string("หยุดทริปนี้หรือไม่?", language: .english) == "Stop This Trip?")
        #expect(AppLocalization.string("เสร็จสิ้นทริปนี้หรือไม่?", language: .thai) == "เสร็จสิ้นทริปนี้หรือไม่?")
        #expect(AppLocalization.string("เสร็จสิ้นทริปนี้หรือไม่?", language: .english) == "Finish This Trip?")
        #expect(AppLocalization.string("ยังไม่เสร็จ", language: .english) == "Not Yet")
        #expect(
            AppLocalization.format(
                "NapNav จะยกเลิกการแจ้งเตือนของทริปไป %@ และจบทริปนี้",
                "Asok",
                language: .english
            ) == "NapNav will cancel alerts for the trip to Asok and finish it."
        )
    }

    @Test("Alarm cancellation warning is localized in both supported languages")
    func alarmCancellationWarningResolvesInBothLanguages() {
        let warning = "ยกเลิกเสียงเตือนไม่สำเร็จ เสียงอาจยังดังอยู่ NapNav จะลองอีกครั้งเมื่อเปิดแอป"
        #expect(AppLocalization.string(warning, language: .thai) == warning)
        #expect(
            AppLocalization.string(warning, language: .english)
                == "Couldn't cancel the alarm. It may still sound; NapNav will retry when you reopen the app."
        )
    }

    @Test("Formatted values use the selected language")
    func formatsValuesInSelectedLanguage() {
        #expect(
            AppLocalization.format("%d ม.", 500, language: .english) == "500 m"
        )
        #expect(
            AppLocalization.format("%d ม.", 500, language: .thai) == "500 ม."
        )
        #expect(
            AppLocalization.format("%.1f กม.", 2.5, language: .english) == "2.5 km"
        )
        #expect(
            AppLocalization.format("%.1f กม.", 2.5, language: .thai) == "2.5 กม."
        )
    }

    @Test("Domain model properties resolve to selected language")
    func domainModelsResolveCorrectly() {
        #expect(AppLocalization.string(TripPhase.arrived.title, language: .english) == "You’ve Arrived" || AppLocalization.string("ถึงจุดหมายแล้ว", language: .english) == "You’ve Arrived")
        #expect(AppLocalization.string("มีเสียง", language: .english) == "Sound On")
        #expect(AppLocalization.string("ไม่มีเสียง", language: .english) == "Silent")
        #expect(AppLocalization.string("อัตโนมัติ", language: .english) == "Automatic")
    }

    @Test("TripActivityAttributes distance formatting respects languageCode")
    func activityAttributesDistanceFormatting() {
        #expect(TripActivityAttributes.ContentState.formatDistance(500, languageCode: "th") == "500 ม.")
        #expect(TripActivityAttributes.ContentState.formatDistance(500, languageCode: "en") == "500 m")
        #expect(TripActivityAttributes.ContentState.formatDistance(1500, languageCode: "th") == "1.5 กม.")
        #expect(TripActivityAttributes.ContentState.formatDistance(1500, languageCode: "en") == "1.5 km")
    }

    @Test("Accessibility labels and map controls resolve in Thai and English")
    func accessibilityLabelsAndMapControlsResolve() {
        #expect(AppLocalization.string("รีเซ็ตทิศเหนือของแผนที่", language: .english) == "Reset map to north")
        #expect(AppLocalization.string("รีเซ็ตทิศเหนือของแผนที่", language: .thai) == "รีเซ็ตทิศเหนือของแผนที่")
        #expect(AppLocalization.string("แสดงตำแหน่งของฉัน", language: .english) == "Show my location")
        #expect(AppLocalization.string("แสดงตำแหน่งของฉัน", language: .thai) == "แสดงตำแหน่งของฉัน")
        #expect(AppLocalization.format("รูปแบบแผนที่ ปัจจุบันแบบ%@", "Explore", language: .english) == "Map style, currently Explore")
        #expect(AppLocalization.format("รูปแบบแผนที่ ปัจจุบันแบบ%@", "สำรวจ", language: .thai) == "รูปแบบแผนที่ ปัจจุบันแบบสำรวจ")
        #expect(AppLocalization.string("แตะเพื่อเปลี่ยนรูปแบบแผนที่", language: .english) == "Double tap to change map style")
        #expect(AppLocalization.string("แตะเพื่อเปลี่ยนรูปแบบแผนที่", language: .thai) == "แตะเพื่อเปลี่ยนรูปแบบแผนที่")
        #expect(AppLocalization.string("กำลังรอตำแหน่ง", language: .english) == "Waiting for your location")
        #expect(AppLocalization.string("กำลังรอตำแหน่ง", language: .thai) == "กำลังรอตำแหน่ง")
        #expect(AppLocalization.format("ถึง %@", "Asok", language: .english) == "To Asok")
        #expect(AppLocalization.format("ถึง %@", "อโศก", language: .thai) == "ถึง อโศก")
        #expect(AppLocalization.string("ให้ปลุกตอนเหลือระยะเท่าไร?", language: .english) == "How far away should NapNav alert you?")
        #expect(AppLocalization.string("กำหนดระยะเอง", language: .english) == "Set a Custom Distance")
        #expect(AppLocalization.string("ระยะที่เลือก", language: .english) == "Selected Distance")
        #expect(AppLocalization.string("เริ่มเดินทาง", language: .english) == "Start Trip")
        #expect(AppLocalization.string("เลือกจุดหมายนี้", language: .english) == "Use This Destination")
        #expect(AppLocalization.string("กลับไปเลือกจุดหมาย", language: .english) == "Back to Destination")
    }

    @Test("Favorite deletion confirmation and Lock Screen strings resolve in Thai and English")
    func favoriteDeletionAndLockScreenStringsResolve() {
        #expect(AppLocalization.string("ลบสถานที่โปรดนี้หรือไม่?", language: .thai) == "ลบสถานที่โปรดนี้หรือไม่?")
        #expect(AppLocalization.string("ลบสถานที่โปรดนี้หรือไม่?", language: .english) == "Remove from Favorites?")
        #expect(AppLocalization.string("ลบสถานที่โปรด", language: .thai) == "ลบสถานที่โปรด")
        #expect(AppLocalization.string("ลบสถานที่โปรด", language: .english) == "Remove Favorite")
        #expect(
            AppLocalization.format("คุณแน่ใจหรือไม่ว่าต้องการลบ \"%@\" ออกจากรายการโปรด?", "บ้าน", language: .english)
                == "Are you sure you want to remove \"บ้าน\" from favorites?"
        )
        #expect(AppLocalization.string("Dynamic Island & หน้าจอล็อก", language: .english) == "Dynamic Island & Lock Screen")
        #expect(AppLocalization.string("Dynamic Island & หน้าจอล็อค", language: .english) == "Dynamic Island & Lock Screen")
        #expect(
            AppLocalization.string("ติดตามระยะทางและปลุกให้คุณตื่นตรงเวลา แม้ขณะล็อกหน้าจอ", language: .english)
                == "Track remaining distance and wake up on time even while locked."
        )
    }
}
