import CoreLocation
import SwiftUI

struct OnboardingView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage(AppLocalization.preferenceKey) private var appLanguageRawValue = AppLanguage.system.rawValue

    let store: TripStore
    var mode: OnboardingMode = .firstRun
    var onComplete: () -> Void = {}

    @State private var currentPage = OnboardingPage.destination
    @State private var isRequesting = false
    @State private var locationAuthorized = false
    @State private var notificationAuthorized = false
    @State private var alarmKitAuthorized = false

    var body: some View {
        VStack(spacing: 0) {
            if reduceMotion || mode.requestsPermissions(on: currentPage) {
                pageContent(for: currentPage)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                TabView(selection: $currentPage) {
                    ForEach(OnboardingPage.allCases) { page in
                        pageContent(for: page).tag(page)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.3), value: currentPage)
            }

            Divider()

            bottomControlsSection
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .interactiveDismissDisabled(mode.requiresCompletion)
        .onAppear {
            updatePermissionStatus()
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                updatePermissionStatus()
            }
        }
    }

    @ViewBuilder
    private func pageContent(for page: OnboardingPage) -> some View {
        switch page {
        case .destination: destinationSetupPage
        case .alertMethod: alertMethodPage
        case .permissions: permissionsPage
        }
    }

    // MARK: - Permissions
    private var permissionsPage: some View {
        ScrollView {
            VStack(spacing: 18) {
                pageHeader(
                    icon: "checkmark.shield.fill",
                    gradientColors: [AppTheme.primary, AppTheme.dark],
                    title: AppLocalization.string("การตั้งค่าสิทธิ์"),
                    subtitle: AppLocalization.string(mode.requestsPermissions(on: .permissions)
                        ? "ขั้นตอนถัดไป iOS จะแสดงคำขอสิทธิ์ คุณเลือกอนุญาตหรือไม่อนุญาตได้ในแต่ละคำขอ"
                        : "สิทธิ์ที่ใช้คำนวณระยะและส่งเตือน ตรวจสอบหรือเปลี่ยนได้ในการตั้งค่า iPhone")
                )

                permissionsCard
            }
            .padding(.horizontal, 20)
            .padding(.top, 24)
            .padding(.bottom, 16)
        }
        .scrollBounceBehavior(.basedOnSize)
    }

    // MARK: - Alert Method
    private var alertMethodPage: some View {
        ScrollView {
            VStack(spacing: 18) {
                pageHeader(
                    icon: "bell.badge.waveform.fill",
                    gradientColors: [AppTheme.primary, AppTheme.dark],
                    title: AppLocalization.string("เลือกวิธีเตือน"),
                    subtitle: AppLocalization.string("เปลี่ยนภายหลังได้ในการตั้งค่า")
                )

                alertMethodCard

                Text(AppLocalization.string("สัญญาณตำแหน่งไม่ดีอาจทำให้เตือนช้า Focus อาจทำให้ไม่มีเสียง"))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 20)
            .padding(.top, 24)
            .padding(.bottom, 16)
        }
        .scrollBounceBehavior(.basedOnSize)
    }

    // MARK: - Destination & Radius
    private var destinationSetupPage: some View {
        ScrollView {
            VStack(spacing: 18) {
                pageHeader(
                    icon: "mappin.and.ellipse",
                    gradientColors: [AppTheme.primary, AppTheme.secondary],
                    title: AppLocalization.string("เตือนก่อนถึงจุดหมาย"),
                    subtitle: AppLocalization.string("เลือกจุดหมาย ตั้งระยะ แล้วเริ่มทริป")
                )

                VStack(spacing: 12) {
                    featureCard(
                        icon: "magnifyingglass.circle.fill",
                        color: AppTheme.primary,
                        title: AppLocalization.string("เลือกจุดหมาย"),
                        detail: AppLocalization.string("ค้นหาสถานที่ หรือเลื่อนแผนที่ให้จุดหมายอยู่ใต้หมุด")
                    )

                    featureCard(
                        icon: "target",
                        color: .orange,
                        title: AppLocalization.string("ตั้งระยะเตือน"),
                        detail: AppLocalization.string("เลือกระยะสำเร็จรูปหรือกำหนดเอง แล้วแตะเริ่มเดินทาง")
                    )
                }

                privacySection
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
                    .accessibilityHidden(true)
            }

            Text(title)
                .font(.title2.weight(.bold))
                .accessibilityAddTraits(.isHeader)
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
                                .foregroundStyle(isSelected ? AppTheme.actionForeground : .secondary)
                                .frame(width: 24, height: 24)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(mode.title)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.primary)

                                Text(deliverySummary(for: mode))
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
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel(mode.title)
                    .accessibilityValue(deliverySummary(for: mode))
                    .accessibilityAddTraits(isSelected ? .isSelected : [])
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

    private func deliverySummary(for mode: AlertDeliveryMode) -> String {
        switch mode {
        case .both: AppLocalization.string("นาฬิกาปลุก พร้อมแจ้งเตือนแบบเงียบ")
        case .notification: AppLocalization.string("เสียงและแบนเนอร์แจ้งเตือน")
        case .alarmKit: AppLocalization.string("เสียงปลุกของระบบ")
        }
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
            }

            VStack(spacing: 12) {
                permissionRow(
                    icon: "location.fill",
                    color: AppTheme.primary,
                    title: AppLocalization.string("ตำแหน่งที่ตั้ง"),
                    detail: AppLocalization.string("คำนวณระยะถึงจุดหมาย"),
                    isGranted: locationAuthorized
                )

                Divider()

                permissionRow(
                    icon: "bell.badge.fill",
                    color: .orange,
                    title: AppLocalization.string("การแจ้งเตือนทั่วไป"),
                    detail: AppLocalization.string("ส่งเตือนเมื่อใกล้จุดหมาย"),
                    isGranted: notificationAuthorized
                )

                if store.prominentAlarmSupported {
                    Divider()

                    permissionRow(
                        icon: "alarm.fill",
                        color: .purple,
                        title: AppLocalization.string("ระบบนาฬิกาปลุก"),
                        detail: AppLocalization.string("ส่งเสียงปลุกเมื่อใกล้จุดหมาย"),
                        isGranted: alarmKitAuthorized
                    )
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
        isGranted: Bool
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
        Link(
            AppLocalization.string("นโยบายความเป็นส่วนตัว"),
            destination: URL(string: "https://telnwza.github.io/NapNav/privacy.html")!
        )
        .font(.caption.weight(.semibold))
        .foregroundStyle(AppTheme.actionForeground)
    }

    // MARK: - Bottom Controls
    private var bottomControlsSection: some View {
        VStack(spacing: 12) {
            // Page Indicator
            HStack(spacing: 6) {
                ForEach(OnboardingPage.allCases) { page in
                    Capsule()
                        .fill(currentPage == page ? AppTheme.primary : Color(uiColor: .systemGray4))
                        .frame(width: currentPage == page ? 20 : 6, height: 6)
                        .animation(reduceMotion ? nil : .spring(response: 0.3, dampingFraction: 0.7), value: currentPage)
                }
            }
            .padding(.top, 4)
            .accessibilityHidden(true)

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

                    if currentPage.next != nil || mode.requestsPermissions(on: currentPage) {
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

            if mode.showsBackButton(on: currentPage) {
                Button {
                    handleSecondaryAction()
                } label: {
                    Text(secondaryButtonTitle)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .padding(.vertical, 2)
                }
                .disabled(isRequesting)
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 12)
        .padding(.bottom, 16)
        .background(Color(uiColor: .systemBackground))
    }

    private var primaryButtonTitle: String {
        AppLocalization.string(mode.primaryButtonTitleKey(on: currentPage))
    }

    private var secondaryButtonTitle: String {
        AppLocalization.string("ย้อนกลับ")
    }

    private func handlePrimaryAction() {
        if mode.requestsPermissions(on: currentPage) {
            isRequesting = true
            Task {
                await store.requestOnboardingPermissions()
                updatePermissionStatus()
                isRequesting = false
                completeOnboarding()
            }
        } else if let nextPage = currentPage.next {
            withAnimation(MotionTokens.standardAnimation(reduceMotion: reduceMotion)) {
                currentPage = nextPage
            }
        } else {
            completeOnboarding()
        }
    }

    private func handleSecondaryAction() {
        guard let previousPage = currentPage.previous else { return }
        withAnimation(MotionTokens.standardAnimation(reduceMotion: reduceMotion)) {
            currentPage = previousPage
        }
    }

    private func completeOnboarding() {
        onComplete()
        dismiss()
    }

    // MARK: - Helpers
    private func updatePermissionStatus() {
        let auth = CLLocationManager().authorizationStatus
        locationAuthorized = (auth == .authorizedWhenInUse || auth == .authorizedAlways)
        notificationAuthorized = (store.alarmReadiness.permission == .authorized) || store.notificationReady
        alarmKitAuthorized = store.prominentAlarmReady
    }
}
