import CoreLocation
import SwiftUI

struct OnboardingView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage(AppLocalization.preferenceKey) private var appLanguageRawValue = AppLanguage.system.rawValue

    let store: TripStore
    var onComplete: () -> Void = {}

    @State private var currentPage = 0
    @State private var isRequesting = false
    @State private var locationAuthorized = false
    @State private var notificationAuthorized = false
    @State private var alarmKitAuthorized = false

    private let totalPages = 4

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $currentPage) {
                permissionsPage
                    .tag(0)

                alertMethodPage
                    .tag(1)

                destinationSetupPage
                    .tag(2)

                liveTrackingPage
                    .tag(3)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut(duration: 0.3), value: currentPage)

            Divider()

            bottomControlsSection
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .interactiveDismissDisabled()
        .onAppear {
            updatePermissionStatus()
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                updatePermissionStatus()
            }
        }
    }

    // MARK: - Page 0: Permissions
    private var permissionsPage: some View {
        ScrollView {
            VStack(spacing: 18) {
                pageHeader(
                    icon: "checkmark.shield.fill",
                    gradientColors: [AppTheme.primary, AppTheme.dark],
                    title: AppLocalization.string("สิทธิ์การใช้งานที่จำเป็น"),
                    subtitle: AppLocalization.string("ใช้ตำแหน่งที่ตั้งและการแจ้งเตือนเพื่อปลุกคุณเมื่อใกล้ถึงจุดหมาย")
                )

                permissionsCard

                privacySection
            }
            .padding(.horizontal, 20)
            .padding(.top, 24)
            .padding(.bottom, 16)
        }
        .scrollBounceBehavior(.basedOnSize)
    }

    // MARK: - Page 1: Alert Method Settings
    private var alertMethodPage: some View {
        ScrollView {
            VStack(spacing: 18) {
                pageHeader(
                    icon: "bell.badge.waveform.fill",
                    gradientColors: [AppTheme.primary, AppTheme.dark],
                    title: AppLocalization.string("ตั้งค่าวิธีเตือน"),
                    subtitle: AppLocalization.string("เลือกรูปแบบและระดับเสียงการเตือนที่เหมาะกับการเดินทางของคุณ")
                )

                alertMethodCard

                if store.prominentAlarmSupported && !alarmKitAuthorized && (store.alertPreferences.deliveryMode == .alarmKit || store.alertPreferences.deliveryMode == .both) {
                    alarmKitPermissionTip
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 24)
            .padding(.bottom, 16)
        }
        .scrollBounceBehavior(.basedOnSize)
    }

    // MARK: - Page 2: Destination & Radius
    private var destinationSetupPage: some View {
        ScrollView {
            VStack(spacing: 18) {
                pageHeader(
                    icon: "mappin.and.ellipse",
                    gradientColors: [AppTheme.primary, AppTheme.secondary],
                    title: AppLocalization.string("ปักหมุดจุดหมายง่ายๆ"),
                    subtitle: AppLocalization.string("หลับสบายบนรถเมล์ รถไฟฟ้า หรือรถไฟ ไม่ต้องคอยพะวงมองทาง")
                )

                VStack(spacing: 12) {
                    featureCard(
                        icon: "magnifyingglass.circle.fill",
                        color: AppTheme.primary,
                        title: AppLocalization.string("ค้นหาหรือแตะบนแผนที่"),
                        detail: AppLocalization.string("พิมพ์ค้นหาสถานี ป้ายรถเมล์ หรือเลื่อนหมุดบนแผนที่ได้")
                    )

                    featureCard(
                        icon: "target",
                        color: .orange,
                        title: AppLocalization.string("เลือกระยะปลุกตามต้องการ"),
                        detail: AppLocalization.string("กำหนดระยะเตือนล่วงหน้า เช่น 500 ม., 1 กม. หรือกำหนดระยะเอง")
                    )

                    featureCard(
                        icon: "map.fill",
                        color: .green,
                        title: AppLocalization.string("แผนที่หลายรูปแบบ"),
                        detail: AppLocalization.string("สลับมุมมองได้ทั้งแบบมาตรฐาน ขนส่งสาธารณะ และดาวเทียม")
                    )
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 24)
            .padding(.bottom, 16)
        }
        .scrollBounceBehavior(.basedOnSize)
    }

    // MARK: - Page 3: Live Activity & Tracking
    private var liveTrackingPage: some View {
        ScrollView {
            VStack(spacing: 18) {
                pageHeader(
                    icon: "sparkles.tv.fill",
                    gradientColors: [.purple, .indigo],
                    title: AppLocalization.string("พักสายตาได้อย่างสบายใจ"),
                    subtitle: AppLocalization.string("ติดตามระยะทางและปลุกให้คุณตื่นตรงเวลา แม้ขณะล็อกหน้าจอ")
                )

                VStack(spacing: 12) {
                    featureCard(
                        icon: "iphone.badge.play",
                        color: .indigo,
                        title: AppLocalization.string("Dynamic Island & หน้าจอล็อก"),
                        detail: AppLocalization.string("ดูระยะทางที่เหลือและสถานะทริป; ตัวนับ Auto-Stop แสดงหลังถึงจุดหมาย")
                    )

                    featureCard(
                        icon: "timer",
                        color: .teal,
                        title: AppLocalization.string("ตั้ง Auto-Stop หลังถึงจุดหมาย"),
                        detail: AppLocalization.string("หลังถึงจุดหมาย ระบบจะเริ่ม Auto-Stop ตามเวลาที่เลือก; iOS อาจทำให้ล่าช้า")
                    )

                    featureCard(
                        icon: "bolt.shield.fill",
                        color: .green,
                        title: AppLocalization.string("การใช้แบตเตอรี่"),
                        detail: AppLocalization.string("ติดตามตำแหน่งขณะทริปทำงาน; การใช้แบตเตอรี่ขึ้นกับสัญญาณ อุปกรณ์ และระยะเวลาทริป")
                    )
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 24)
            .padding(.bottom, 16)
        }
        .scrollBounceBehavior(.basedOnSize)
    }

    // MARK: - Header Component
    private func pageHeader(
        icon: String,
        gradientColors: [Color],
        title: String,
        subtitle: String
    ) -> some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: gradientColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 58, height: 58)
                    .shadow(color: gradientColors[0].opacity(0.3), radius: 8, y: 4)

                Image(systemName: icon)
                    .font(.system(size: 26, weight: .semibold))
                    .foregroundStyle(.white)
            }

            Text(title)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .multilineTextAlignment(.center)
                .foregroundStyle(.primary)

            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 8)
        }
    }

    // MARK: - Alert Method Card
    private var alertMethodCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label(
                    AppLocalization.string("วิธีเตือน"),
                    systemImage: "speaker.wave.3.fill"
                )
                .font(.caption.weight(.bold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)

                Spacer()
            }

            VStack(spacing: 8) {
                ForEach(store.availableDeliveryModes) { mode in
                    let isSelected = store.alertPreferences.deliveryMode == mode
                    Button {
                        var prefs = store.alertPreferences
                        prefs.deliveryMode = mode
                        store.updateAlertPreferences(prefs)
                        HapticFeedback.selection()
                    } label: {
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: mode.systemImage)
                                .font(.system(size: 18))
                                .foregroundStyle(isSelected ? AppTheme.primary : .secondary)
                                .frame(width: 24, height: 24)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(mode.title)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.primary)

                                Text(mode.subtitle)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }

                            Spacer()

                            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                                .font(.system(size: 18))
                                .foregroundStyle(isSelected ? AppTheme.primary : Color(uiColor: .tertiaryLabel))
                        }
                        .padding(10)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(isSelected ? AppTheme.secondary.opacity(0.25) : Color(uiColor: .tertiarySystemGroupedBackground))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(isSelected ? AppTheme.primary.opacity(0.5) : Color.clear, lineWidth: 1.5)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(14)
        .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.primary.opacity(0.06), lineWidth: 1)
        )
    }

    private var alarmKitPermissionTip: some View {
        HStack(alignment: .center, spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.title3)
                .foregroundStyle(.orange)

            VStack(alignment: .leading, spacing: 2) {
                Text(AppLocalization.string("ยังไม่ได้รับอนุญาต AlarmKit"))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.primary)
                Text(AppLocalization.string("แตะขอสิทธิ์เพื่อให้ระบบนาฬิกาปลุกทำงานได้เต็มรูปแบบ"))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button(AppLocalization.string("ขอสิทธิ์")) {
                Task {
                    await store.requestAlarmKitPermission()
                    updatePermissionStatus()
                }
            }
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Color.orange.opacity(0.15), in: Capsule())
            .foregroundStyle(.orange)
            .buttonStyle(.plain)
        }
        .padding(12)
        .background(Color.orange.opacity(0.08), in: RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.orange.opacity(0.25), lineWidth: 1)
        )
    }

    // MARK: - Permissions Card
    private var permissionsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label(
                    AppLocalization.string("สิทธิ์การใช้งาน"),
                    systemImage: "checklist"
                )
                .font(.caption.weight(.bold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)

                Spacer()

                if allPermissionsAuthorized {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundStyle(.green)
                        Text(AppLocalization.string("อนุญาตแล้ว"))
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.green)
                    }
                }
            }

            VStack(spacing: 12) {
                permissionRow(
                    icon: "location.fill",
                    color: AppTheme.primary,
                    title: AppLocalization.string("ตำแหน่งที่ตั้ง"),
                    detail: AppLocalization.string("ช่วยคำนวณระยะจากตำแหน่งที่ได้รับ"),
                    isGranted: locationAuthorized,
                    actionTitle: AppLocalization.string("ขอสิทธิ์")
                ) {
                    store.requestLocationPermission()
                }

                Divider()

                permissionRow(
                    icon: "bell.badge.fill",
                    color: .orange,
                    title: AppLocalization.string("การแจ้งเตือน & เสียงเตือน"),
                    detail: AppLocalization.string("ใช้สำหรับแจ้งเตือนใกล้รัศมีที่เลือก; การส่งขึ้นกับสิทธิ์และการตั้งค่า iOS"),
                    isGranted: notificationAuthorized,
                    actionTitle: AppLocalization.string("ขอสิทธิ์")
                ) {
                    Task {
                        await store.requestNotificationPermission()
                        updatePermissionStatus()
                    }
                }

                if store.prominentAlarmSupported {
                    Divider()

                    permissionRow(
                        icon: "alarm.fill",
                        color: .purple,
                        title: AppLocalization.string("ระบบนาฬิกาปลุก (AlarmKit)"),
                        detail: AppLocalization.string("AlarmKit ส่งเสียงเตือนบนอุปกรณ์ที่รองรับ; ผลการเตือนขึ้นกับสิทธิ์และการตั้งค่า iOS (iOS 26+)"),
                        isGranted: alarmKitAuthorized,
                        actionTitle: AppLocalization.string("ขอสิทธิ์")
                    ) {
                        Task {
                            await store.requestAlarmKitPermission()
                            updatePermissionStatus()
                        }
                    }
                }
            }
        }
        .padding(14)
        .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.primary.opacity(0.06), lineWidth: 1)
        )
    }

    private func permissionRow(
        icon: String,
        color: Color,
        title: String,
        detail: String,
        isGranted: Bool,
        actionTitle: String,
        action: @escaping () -> Void
    ) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(color)
                .frame(width: 28, height: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)

                Text(detail)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()

            if isGranted {
                Label(AppLocalization.string("อนุญาตแล้ว"), systemImage: "checkmark.circle.fill")
                    .labelStyle(.iconOnly)
                    .foregroundStyle(.green)
                    .font(.title3)
            } else {
                Button(actionTitle) {
                    action()
                }
                .font(.caption.weight(.semibold))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(AppTheme.secondary.opacity(0.4), in: Capsule())
                .foregroundStyle(AppTheme.primary)
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Feature Card
    private func featureCard(
        icon: String,
        color: Color,
        title: String,
        detail: String
    ) -> some View {
        HStack(alignment: .center, spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(color.opacity(0.14))
                    .frame(width: 44, height: 44)

                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(color)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)

                Text(detail)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
        }
        .padding(14)
        .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.primary.opacity(0.06), lineWidth: 1)
        )
    }

    // MARK: - Privacy Notice
    private var privacySection: some View {
        VStack(spacing: 6) {
            HStack(alignment: .center, spacing: 6) {
                Image(systemName: "hand.raised.fill")
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                Text(AppLocalization.string("ตำแหน่งใช้คำนวณระยะทางระหว่างทริป; ค้นหาสถานที่ผ่านบริการ Apple และบันทึกสถานที่โปรด/ล่าสุดไว้บนอุปกรณ์"))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Link(
                AppLocalization.string("อ่านนโยบายความเป็นส่วนตัว"),
                destination: URL(string: "https://telnwza.github.io/NapNav/privacy.html")!
            )
            .font(.caption2.weight(.semibold))
            .foregroundStyle(AppTheme.primary)
        }
        .padding(.horizontal, 4)
    }

    // MARK: - Bottom Controls
    private var bottomControlsSection: some View {
        VStack(spacing: 12) {
            // Page Indicator
            HStack(spacing: 6) {
                ForEach(0..<totalPages, id: \.self) { index in
                    Capsule()
                        .fill(currentPage == index ? AppTheme.primary : Color(uiColor: .systemGray4))
                        .frame(width: currentPage == index ? 20 : 6, height: 6)
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: currentPage)
                }
            }
            .padding(.top, 4)

            // Primary Action Button
            Button {
                handlePrimaryAction()
            } label: {
                HStack(spacing: 6) {
                    if isRequesting {
                        ProgressView()
                            .tint(.white)
                            .padding(.trailing, 4)
                    }

                    Text(primaryButtonTitle)
                        .font(.headline)

                    if currentPage < totalPages - 1 {
                        Image(systemName: "arrow.right")
                            .font(.headline)
                    } else {
                        Image(systemName: "checkmark")
                            .font(.headline)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 4)
            }
            .napNavPrimaryButtonStyle()
            .disabled(isRequesting)

            // Secondary Action Button (Only show on page > 0 so permissions are never delayed on page 0)
            if currentPage > 0 {
                Button {
                    handleSecondaryAction()
                } label: {
                    Text(secondaryButtonTitle)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .padding(.vertical, 2)
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 12)
        .padding(.bottom, 16)
        .background(Color(uiColor: .systemBackground))
    }

    private var primaryButtonTitle: String {
        if currentPage == totalPages - 1 {
            return AppLocalization.string("เริ่มต้นใช้งาน")
        } else if currentPage == 0 {
            return AppLocalization.string("ดำเนินการต่อ")
        } else {
            return AppLocalization.string("ถัดไป")
        }
    }

    private var secondaryButtonTitle: String {
        AppLocalization.string("ย้อนกลับ")
    }

    private func handlePrimaryAction() {
        if currentPage == 0 && !allPermissionsAuthorized {
            Task {
                isRequesting = true
                await store.requestOnboardingPermissions()
                updatePermissionStatus()
                isRequesting = false
                withAnimation {
                    currentPage += 1
                }
            }
        } else if currentPage < totalPages - 1 {
            withAnimation {
                currentPage += 1
            }
        } else {
            completeOnboarding()
        }
    }

    private func handleSecondaryAction() {
        guard currentPage > 0 else { return }
        withAnimation {
            currentPage -= 1
        }
    }

    private func completeOnboarding() {
        onComplete()
        dismiss()
    }

    // MARK: - Helpers
    private var allPermissionsAuthorized: Bool {
        let base = locationAuthorized && notificationAuthorized
        return store.prominentAlarmSupported ? (base && alarmKitAuthorized) : base
    }

    private func updatePermissionStatus() {
        let auth = CLLocationManager().authorizationStatus
        locationAuthorized = (auth == .authorizedWhenInUse || auth == .authorizedAlways)
        notificationAuthorized = (store.alarmReadiness.permission == .authorized) || store.notificationReady
        alarmKitAuthorized = store.prominentAlarmReady
    }
}
