import SwiftUI
import UIKit

struct AlertSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @Environment(\.scenePhase) private var scenePhase
    @Bindable var store: TripStore
    @AppStorage("isDeveloperModeEnabled") private var isDeveloperModeEnabled = false
    @AppStorage(AppLocalization.preferenceKey) private var appLanguageRawValue = AppLanguage.system.rawValue
    @State private var devTapCount = 0
    @State private var lastTapTime: Date?

    private var appLanguage: AppLanguage {
        AppLanguage(rawValue: appLanguageRawValue) ?? .system
    }

    private var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0.1.0"
    }

    var body: some View {
        NavigationStack {
            Form {
                alertPreferencesSection
                permissionsSection
                languageSection

                if isDeveloperModeEnabled {
                    developerEntrySection
                }

                aboutSection
            }
            .navigationTitle(AppLocalization.string("การแจ้งเตือน"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(AppLocalization.string("เสร็จสิ้น")) {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .task(id: scenePhase) {
                guard scenePhase == .active else { return }
                await store.refreshReadiness()
            }
        }
        .id(appLanguageRawValue)
        .environment(\.locale, appLanguage.locale)
    }

    private var alertPreferencesSection: some View {
        Section(AppLocalization.string("การตั้งค่า")) {
            NavigationLink {
                AlertDeliveryModeSelectionView(store: store)
            } label: {
                LabeledContent(AppLocalization.string("วิธีเตือน"), value: store.alertPreferences.deliveryMode.title)
            }



            alertIssueContent
        }
    }

    @ViewBuilder
    private var alertIssueContent: some View {
        let plan = store.alertDeliveryPlan

        if let reason = plan.unavailableReason {
            issueLabel(reason.summary)
            openSettingsButton
        } else if let reason = plan.fallbackReason {
            issueLabel(reason.summary)
            if reason == .alarmKitNotAuthorized || reason == .notificationUnavailable {
                openSettingsButton
            }
        } else if plan.paths.contains(.notification(sound: .mutedBySystem)) {
            issueLabel(AppLocalization.string("เสียง Notification ถูกปิดอยู่"))
            openSettingsButton
        } else if usesNotificationPath && store.alarmReadiness.lockScreenEnabled == false {
            issueLabel(AppLocalization.string("Notification จะไม่แสดงบนหน้าจอล็อก"))
            openSettingsButton
        }
    }

    private var permissionsSection: some View {
        Section {
            NavigationLink {
                AlertPermissionDetailsView(store: store)
            } label: {
                HStack {
                    Text(AppLocalization.string("สิทธิ์การแจ้งเตือน"))
                    Spacer()
                    if hasPermissionIssue {
                        Image(systemName: "exclamationmark.circle.fill")
                            .foregroundStyle(.orange)
                            .accessibilityLabel(AppLocalization.string("มีสิทธิ์ที่ต้องตรวจสอบ"))
                    }
                }
            }
        }
    }

    private var developerEntrySection: some View {
        Section {
            NavigationLink {
                DeveloperToolsView(
                    store: store,
                    isDeveloperModeEnabled: $isDeveloperModeEnabled
                )
            } label: {
                Label(AppLocalization.string("เครื่องมือนักพัฒนา"), systemImage: "wrench.and.screwdriver")
            }
        }
    }

    private var languageSection: some View {
        Section(AppLocalization.string("ภาษา")) {
            Picker(AppLocalization.string("ภาษาของแอป"), selection: $appLanguageRawValue) {
                ForEach(AppLanguage.allCases) { language in
                    Text(AppLocalization.string(language.titleKey))
                        .tag(language.rawValue)
                }
            }
            .pickerStyle(.navigationLink)
            .onChange(of: appLanguageRawValue) {
                LocalAlarmDelivery.registerCategories(language: appLanguage)
                store.appLanguageDidChange()
                HapticFeedback.selection()
            }
        }
    }

    private var aboutSection: some View {
        Section(AppLocalization.string("เกี่ยวกับ")) {
            Button {
                store.showsOnboarding = true
            } label: {
                Label(AppLocalization.string("แนะนำการใช้งาน"), systemImage: "sparkles")
            }

            Link(destination: URL(string: "https://github.com/Telnwza/NapNav")!) {
                HStack {
                    Label(
                        AppLocalization.string("NapNav บน GitHub"),
                        systemImage: "chevron.left.forwardslash.chevron.right"
                    )
                    .foregroundStyle(.primary)

                    Spacer()

                    Image(systemName: "arrow.up.forward")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
            }

            HStack {
                Text(AppLocalization.string("เวอร์ชัน"))
                Spacer()
                Text(appVersion)
                    .foregroundStyle(.secondary)
            }
            .contentShape(.rect)
            .onTapGesture(perform: handleVersionTap)
        }
    }

    private var usesNotificationPath: Bool {
        store.alertDeliveryPlan.paths.contains { path in
            if case .notification = path { return true }
            return false
        }
    }

    private var hasPermissionIssue: Bool {
        let plan = store.alertDeliveryPlan
        return plan.isAvailable == false
            || plan.usesFallback
            || (usesNotificationPath && store.alarmReadiness.lockScreenEnabled == false)
            || plan.paths.contains(.notification(sound: .mutedBySystem))
    }

    private func issueLabel(_ text: String) -> some View {
        Label(text, systemImage: "exclamationmark.triangle.fill")
            .font(.caption)
            .foregroundStyle(.orange)
    }

    private var openSettingsButton: some View {
        Button(action: openSystemSettings) {
            Label(AppLocalization.string("เปิดการตั้งค่า iPhone"), systemImage: "arrow.up.forward.app")
        }
    }

    private func openSystemSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        openURL(url)
    }

    private func handleVersionTap() {
        let now = Date()
        if let lastTap = lastTapTime, now.timeIntervalSince(lastTap) > 2.0 {
            devTapCount = 0
        }
        lastTapTime = now
        devTapCount += 1

        if devTapCount >= 5 {
            devTapCount = 0
            withAnimation {
                isDeveloperModeEnabled.toggle()
            }
            HapticFeedback.success()
        } else {
            HapticFeedback.selection()
        }
    }
}

private struct AlertDeliveryModeSelectionView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var store: TripStore
    @AppStorage(AppLocalization.preferenceKey) private var appLanguageRawValue = AppLanguage.system.rawValue

    private var appLanguage: AppLanguage {
        AppLanguage(rawValue: appLanguageRawValue) ?? .system
    }

    var body: some View {
        Form {
            Section {
                ForEach(store.availableDeliveryModes) { mode in
                    Button {
                        select(mode)
                    } label: {
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: mode.systemImage)
                                .frame(width: 24)
                                .foregroundStyle(AppTheme.primary)

                            VStack(alignment: .leading, spacing: 3) {
                                Text(mode.title)
                                    .foregroundStyle(.primary)
                                Text(mode.subtitle)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            if store.alertPreferences.deliveryMode == mode {
                                Image(systemName: "checkmark")
                                    .fontWeight(.semibold)
                                    .foregroundStyle(AppTheme.primary)
                            }
                        }
                        .contentShape(.rect)
                    }
                    .buttonStyle(.plain)
                }
            } footer: {
                if let reason = store.alertDeliveryPlan.fallbackReason {
                    Text(reason.summary)
                        .foregroundStyle(.orange)
                }
            }
        }
        .navigationTitle(AppLocalization.string("วิธีเตือน"))
        .navigationBarTitleDisplayMode(.inline)
        .id(appLanguageRawValue)
        .environment(\.locale, appLanguage.locale)
        .task {
            await store.refreshReadiness()
        }
    }

    private func select(_ mode: AlertDeliveryMode) {
        var preferences = store.alertPreferences
        preferences.deliveryMode = mode
        store.updateAlertPreferences(preferences)
        HapticFeedback.selection()
        dismiss()
    }
}

private struct AlertPermissionDetailsView: View {
    @Environment(\.openURL) private var openURL
    @Bindable var store: TripStore
    @AppStorage(AppLocalization.preferenceKey) private var appLanguageRawValue = AppLanguage.system.rawValue

    private var appLanguage: AppLanguage {
        AppLanguage(rawValue: appLanguageRawValue) ?? .system
    }

    var body: some View {
        Form {
            Section(AppLocalization.string("การแจ้งเตือนทั่วไป")) {
                statusRow(AppLocalization.string("สิทธิ์"), value: notificationPermissionText, isEnabled: notificationIsAuthorized)
                statusRow(AppLocalization.string("เสียง"), value: enabledText(store.alarmReadiness.soundsEnabled), isEnabled: store.alarmReadiness.soundsEnabled)
                statusRow(AppLocalization.string("หน้าจอล็อก"), value: enabledText(store.alarmReadiness.lockScreenEnabled), isEnabled: store.alarmReadiness.lockScreenEnabled)
                statusRow(
                    AppLocalization.string("Time Sensitive"),
                    value: store.alarmReadiness.timeSensitiveSetting.title,
                    isEnabled: store.alarmReadiness.timeSensitiveSetting == .enabled
                )
                Text(timeSensitiveExplanation)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            if store.prominentAlarmSupported {
                Section("AlarmKit") {
                    statusRow(
                        AppLocalization.string("สิทธิ์"),
                        value: store.prominentAlarmReady
                            ? AppLocalization.string("อนุญาต")
                            : AppLocalization.string("ยังไม่ได้อนุญาต"),
                        isEnabled: store.prominentAlarmReady
                    )
                }
            }

            Section {
                Button {
                    guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
                    openURL(url)
                } label: {
                    Label(AppLocalization.string("เปิดการตั้งค่า iPhone"), systemImage: "arrow.up.forward.app")
                }
            }
        }
        .navigationTitle(AppLocalization.string("สิทธิ์การแจ้งเตือน"))
        .navigationBarTitleDisplayMode(.inline)
        .id(appLanguageRawValue)
        .environment(\.locale, appLanguage.locale)
        .task {
            await store.refreshReadiness()
        }
    }

    private var notificationIsAuthorized: Bool {
        store.alarmReadiness.permission == .authorized
    }

    private var notificationPermissionText: String {
        switch store.alarmReadiness.permission {
        case .authorized: AppLocalization.string("อนุญาต")
        case .denied: AppLocalization.string("ไม่อนุญาต")
        case .notDetermined: AppLocalization.string("ยังไม่ได้เลือก")
        case .unknown: AppLocalization.string("ไม่ทราบ")
        }
    }

    private var timeSensitiveExplanation: String {
        if store.alarmReadiness.timeSensitiveSetting == .notSupported {
            return AppLocalization.string("Time Sensitive ไม่พร้อมใช้งานสำหรับ NapNav")
        }
        return AppLocalization.string("เปลี่ยนการตั้งค่านี้ได้จาก Settings ของ iPhone เท่านั้น")
    }

    private func enabledText(_ enabled: Bool) -> String {
        enabled ? AppLocalization.string("เปิด") : AppLocalization.string("ปิด")
    }

    private func statusRow(_ title: String, value: String, isEnabled: Bool) -> some View {
        HStack {
            Text(title)
            Spacer()
            if isEnabled {
                Text(value)
                    .foregroundStyle(.secondary)
            } else {
                Text(value)
                    .foregroundStyle(.orange)
            }
        }
    }
}

private struct DeveloperToolsView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var store: TripStore
    @Binding var isDeveloperModeEnabled: Bool
    @AppStorage(AppLocalization.preferenceKey) private var appLanguageRawValue = AppLanguage.system.rawValue

    private var appLanguage: AppLanguage {
        AppLanguage(rawValue: appLanguageRawValue) ?? .system
    }

    var body: some View {
        Form {
            Section(AppLocalization.string("ทดสอบการเตือน")) {
                Button {
                    Task { await store.sendTestNotification(after: 0) }
                } label: {
                    Label(AppLocalization.string("ทดสอบแจ้งเตือนทันที"), systemImage: "bell")
                }

                Button {
                    Task { await store.sendTestNotification(after: 5) }
                } label: {
                    Label(AppLocalization.string("ทดสอบแจ้งเตือนหน่วงเวลา 5 วิ"), systemImage: "clock.badge.waveform")
                }

                Button {
                    Task { await store.sendTestApproachingNotification() }
                } label: {
                    Label(AppLocalization.string("ทดสอบเตือนใกล้ถึง (500 ม.)"), systemImage: "location.north.line")
                }

                Button {
                    Task { await store.sendTestArrivalNotification() }
                } label: {
                    Label(AppLocalization.string("ทดสอบเตือนถึงจุดหมาย (20 ม.)"), systemImage: "flag.checkered")
                }

                if #available(iOS 26.0, *) {
                    Button {
                        Task { await store.sendProminentAlarmSpike() }
                    } label: {
                        Label(AppLocalization.string("ทดสอบ AlarmKit (หน่วง 5 วิ)"), systemImage: "alarm")
                    }
                }
            }

            Section("Live Activity") {
                Menu {
                    Button(AppLocalization.string("กำลังเดินทาง")) {
                        store.startTripActivitySimulation(phase: .tracking)
                    }
                    Button(AppLocalization.string("ใกล้ถึง")) {
                        store.startTripActivitySimulation(phase: .approaching)
                    }
                    Button(AppLocalization.string("ถึงแล้ว + นับถอยหลัง")) {
                        store.startTripActivitySimulation(phase: .arrived)
                    }
                    Divider()
                    Button(AppLocalization.string("ปิด Live Activity"), role: .destructive) {
                        store.stopTripActivitySimulation()
                    }
                } label: {
                    Label(AppLocalization.string("จำลองสถานะ"), systemImage: "platter.2.filled.iphone")
                }
            }

            Section {
                Button {
                    UserDefaults.standard.set(false, forKey: "hasCompletedOnboarding")
                    store.showsOnboarding = true
                } label: {
                    Label(AppLocalization.string("รีเซ็ตหน้าแรก (Onboarding)"), systemImage: "sparkles.rectangle.stack")
                }

                Button {
                    guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
                    UIApplication.shared.open(url)
                } label: {
                    Label(AppLocalization.string("เปิดการตั้งค่าเพื่อรีเซ็ตสิทธิ์ (iOS Settings)"), systemImage: "gearshape.arrow.triangle.2.circlepath")
                }

                Button {
                    Task {
                        dismiss()
                        try? await Task.sleep(for: .milliseconds(350))
                        await store.relaunchApp()
                    }
                } label: {
                    Label(AppLocalization.string("ทดสอบเปิดแอปใหม่ตามโหมดนี้"), systemImage: "arrow.clockwise.circle")
                }
            } header: {
                Text(AppLocalization.string("หน้าจอเริ่มต้น (Startup & Loading)"))
            } footer: {
                Text(AppLocalization.string("iOS ไม่อนุญาตให้แอปรีเซ็ตสิทธิ์เองได้โดยตรง แตะเพื่อไปที่การตั้งค่าแล้วปิดสิทธิ์เพื่อทดสอบใหม่"))
            }

            Section(AppLocalization.string("ข้อมูลล่าสุด")) {
                LabeledContent(AppLocalization.string("สถานะทริป"), value: store.phase.title)

                if let coordinate = store.currentCoordinate {
                    LabeledContent(
                        AppLocalization.string("พิกัด"),
                        value: String(format: "%.4f, %.4f", coordinate.latitude, coordinate.longitude)
                    )
                    .monospacedDigit()
                }

                if let accuracy = store.horizontalAccuracyMeters {
                    LabeledContent(
                        AppLocalization.string("ความแม่นยำ GPS"),
                        value: AppLocalization.format("±%.1f ม.", accuracy)
                    )
                }

                if let message = store.testNotificationMessage {
                    Text(message)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Section {
                Button(AppLocalization.string("ปิดโหมดนักพัฒนา"), role: .destructive) {
                    isDeveloperModeEnabled = false
                    HapticFeedback.selection()
                    dismiss()
                }
            }
        }
        .navigationTitle(AppLocalization.string("เครื่องมือนักพัฒนา"))
        .navigationBarTitleDisplayMode(.inline)
        .id(appLanguageRawValue)
        .environment(\.locale, appLanguage.locale)
    }
}
