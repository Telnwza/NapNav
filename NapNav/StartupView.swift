import SwiftUI

struct StartupView: View {
    @AppStorage(AppLocalization.preferenceKey) private var appLanguageRawValue = AppLanguage.system.rawValue
    let state: AppLaunchState
    let onRetry: () -> Void
    let onResume: () -> Void
    let onDiscard: () -> Void

    init(
        state: AppLaunchState,
        onRetry: @escaping () -> Void,
        onResume: @escaping () -> Void = {},
        onDiscard: @escaping () -> Void = {}
    ) {
        self.state = state
        self.onRetry = onRetry
        self.onResume = onResume
        self.onDiscard = onDiscard
    }

    var body: some View {
        VStack(spacing: 28) {
            Spacer(minLength: 32)

            Image("LaunchLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 121)
                .accessibilityLabel("NapNav")

            switch state {
            case .launching(let message), .recoveringTrip(let message):
                VStack(spacing: 12) {
                    ProgressView()
                        .controlSize(.regular)
                        .tint(AppTheme.primary)
                        .accessibilityHidden(true)
                    Text(message)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .accessibilityElement(children: .combine)
            case .failed(let message):
                ContentUnavailableView {
                    Label(AppLocalization.string("เตรียมแอปไม่สำเร็จ"), systemImage: "exclamationmark.triangle")
                } description: {
                    Text(message)
                } actions: {
                    VStack(spacing: 10) {
                        Button(AppLocalization.string("ลองใหม่"), action: onRetry)
                            .napNavPrimaryButtonStyle()
                            .accessibilityIdentifier("retryStartupButton")
                        Button(AppLocalization.string("ล้างข้อมูลทริปเดิม"), role: .destructive, action: onDiscard)
                            .napNavSecondaryButtonStyle()
                            .accessibilityIdentifier("clearCorruptTripButton")
                    }
                }
            case .awaitingTripRecovery(let destinationName):
                ContentUnavailableView {
                    Label(AppLocalization.string("พบทริปที่ยังไม่จบ"), systemImage: "location.circle")
                } description: {
                    Text(AppLocalization.format("จะเดินทางต่อไปที่ %@ หรือทิ้งทริปนี้", destinationName))
                } actions: {
                    VStack(spacing: 10) {
                        Button(AppLocalization.string("เดินทางต่อ"), action: onResume)
                            .napNavPrimaryButtonStyle()
                            .accessibilityIdentifier("resumeRecoveredTripButton")
                        Button(AppLocalization.string("ทิ้งทริป"), role: .destructive, action: onDiscard)
                            .napNavSecondaryButtonStyle()
                            .accessibilityIdentifier("discardRecoveredTripButton")
                    }
                }
            case .ready:
                EmptyView()
            }

            Spacer(minLength: 32)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(uiColor: .systemBackground).ignoresSafeArea())
    }
}

#Preview("Startup กำลังเตรียม") {
    StartupView(
        state: .launching(message: "กำลังเตรียมแผนที่"),
        onRetry: {}
    )
}

#Preview("Startup กำลังกู้ทริป") {
    StartupView(
        state: .recoveringTrip(message: "กำลังกู้คืนทริป"),
        onRetry: {}
    )
}

#Preview("Startup เลือกกู้ทริป") {
    StartupView(
        state: .awaitingTripRecovery(destinationName: "สถานีอโศก"),
        onRetry: {}
    )
}

#Preview("Startup ผิดพลาด") {
    StartupView(
        state: .failed(message: "อ่านข้อมูลทริปเดิมไม่ได้"),
        onRetry: {}
    )
}
