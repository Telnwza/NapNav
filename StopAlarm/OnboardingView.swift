import CoreLocation
import SwiftUI

struct OnboardingView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage(AppLocalization.preferenceKey) private var appLanguageRawValue = AppLanguage.system.rawValue

    let store: TripStore
    var onComplete: () -> Void = {}

    @State private var isRequesting = false
    @State private var locationAuthorized = false
    @State private var notificationAuthorized = false

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 20) {
                    headerSection

                    featureListSection

                    permissionsCard
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                .padding(.bottom, 12)
            }
            .scrollBounceBehavior(.basedOnSize)

            VStack(spacing: 12) {
                privacySection

                actionButtonsSection
            }
            .padding(.horizontal, 24)
            .padding(.top, 8)
            .padding(.bottom, 16)
        }
        .background(Color(uiColor: .systemBackground))
        .onAppear {
            updatePermissionStatus()
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                updatePermissionStatus()
            }
        }
    }

    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.blue, .indigo],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 60, height: 60)
                    .shadow(color: .blue.opacity(0.25), radius: 8, y: 4)

                Image(systemName: "bell.badge.waveform.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(.white)
            }
            .padding(.bottom, 2)

            Text(AppLocalization.string("ยินดีต้อนรับสู่ NapNav"))
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .multilineTextAlignment(.center)

            Text(AppLocalization.string("ปลุกตามพิกัด หลับสบายไม่เลยป้าย"))
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - Feature List Section
    private var featureListSection: some View {
        VStack(spacing: 14) {
            featureRow(
                icon: "mappin.and.ellipse",
                color: .blue,
                title: AppLocalization.string("ปักหมุดจุดหมาย"),
                detail: AppLocalization.string("ค้นหาสถานีหรือแตะเลือกบนแผนที่")
            )

            featureRow(
                icon: "alarm.waves.left.and.right.fill",
                color: .orange,
                title: AppLocalization.string("ปลุกดังแม้ปิดเสียง"),
                detail: AppLocalization.string("เตือนชัดเจนไม่พลาดสถานี แม้เปิดโหมดเงียบ")
            )
        }
    }

    private func featureRow(
        icon: String,
        color: Color,
        title: String,
        detail: String
    ) -> some View {
        HStack(alignment: .center, spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(color.opacity(0.14))
                    .frame(width: 38, height: 38)

                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(color)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)

                Text(detail)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Permissions Primer Card
    private var permissionsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label(
                    AppLocalization.string("สิทธิ์ที่จำเป็น"),
                    systemImage: "checklist"
                )
                .font(.caption.weight(.bold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)

                Spacer()
            }

            permissionItem(
                icon: "location.fill",
                color: .blue,
                title: AppLocalization.string("ตำแหน่งที่ตั้ง"),
                detail: AppLocalization.string("ใช้วัดระยะห่างถึงจุดหมาย"),
                isGranted: locationAuthorized
            )

            Divider()

            permissionItem(
                icon: "bell.badge.fill",
                color: .orange,
                title: AppLocalization.string("เสียงและการแจ้งเตือน"),
                detail: AppLocalization.string("ส่งเสียงปลุกเมื่อใกล้ถึง"),
                isGranted: notificationAuthorized
            )
        }
        .padding(14)
        .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.primary.opacity(0.06), lineWidth: 1)
        )
    }

    private func permissionItem(
        icon: String,
        color: Color,
        title: String,
        detail: String,
        isGranted: Bool
    ) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(color)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.primary)

                Text(detail)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if isGranted {
                Label(AppLocalization.string("อนุญาตแล้ว"), systemImage: "checkmark.circle.fill")
                    .labelStyle(.iconOnly)
                    .foregroundStyle(.green)
                    .font(.subheadline)
            }
        }
    }

    // MARK: - Privacy Notice
    private var privacySection: some View {
        HStack(alignment: .center, spacing: 6) {
            Image(systemName: "hand.raised.fill")
                .font(.caption2)
                .foregroundStyle(.secondary)

            Text(AppLocalization.string("ประมวลผลตำแหน่งบนเครื่องเท่านั้น ไม่ส่งข้อมูลออกภายนอก"))
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 4)
    }

    // MARK: - Action Buttons
    private var actionButtonsSection: some View {
        VStack(spacing: 8) {
            Button {
                Task {
                    isRequesting = true
                    await store.requestOnboardingPermissions()
                    updatePermissionStatus()
                    isRequesting = false
                    onComplete()
                    dismiss()
                }
            } label: {
                HStack {
                    if isRequesting {
                        ProgressView()
                            .tint(.white)
                            .padding(.trailing, 4)
                    }
                    Text(AppLocalization.string("เริ่มต้นใช้งาน"))
                        .font(.headline)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 3)
            }
            .napNavPrimaryButtonStyle()
            .disabled(isRequesting)

            Button {
                onComplete()
                dismiss()
            } label: {
                Text(AppLocalization.string("ตั้งค่าภายหลัง"))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 2)
            }
        }
    }

    // MARK: - Helpers
    private func updatePermissionStatus() {
        let auth = CLLocationManager().authorizationStatus
        locationAuthorized = (auth == .authorizedWhenInUse || auth == .authorizedAlways)
        notificationAuthorized = (store.alarmReadiness.permission == .authorized) || store.notificationReady
    }
}
