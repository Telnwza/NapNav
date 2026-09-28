import MapKit
import SwiftUI
import UIKit

private struct NapNavGlassModifier<S: Shape>: ViewModifier {
    let shape: S
    let interactive: Bool

    @ViewBuilder
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            if interactive {
                content.glassEffect(.regular.interactive(), in: shape)
            } else {
                content.glassEffect(.regular, in: shape)
            }
        } else {
            content.background(.regularMaterial, in: shape)
        }
    }
}

extension View {
    func napNavGlass<S: Shape>(in shape: S, interactive: Bool = false) -> some View {
        modifier(NapNavGlassModifier(shape: shape, interactive: interactive))
    }

    @ViewBuilder
    func napNavPrimaryButtonStyle() -> some View {
        if #available(iOS 26.0, *) {
            buttonStyle(.glassProminent)
        } else {
            buttonStyle(.borderedProminent)
        }
    }

    @ViewBuilder
    func napNavSecondaryButtonStyle() -> some View {
        if #available(iOS 26.0, *) {
            buttonStyle(.glass)
        } else {
            buttonStyle(.bordered)
        }
    }
}

struct RootView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var stopConfirmationRequest: TripStopConfirmationRequest?
    @State private var pendingDeepLinkURL: URL?
    @State private var didFinishLaunchPreparation = false
    @Bindable var store: TripStore

    var body: some View {
        ZStack {
            Color(uiColor: .systemBackground)
                .ignoresSafeArea()

            // 1. แผนที่และหน้าหลักของแอป โหลดและเรนเดอร์รอไว้เบื้องหลังทันที
            NavigationStack {
                activeScreen
            }
            .safeAreaInset(edge: .top, spacing: 0) {
                if let warning = store.alertCleanupWarning {
                    Label(warning, systemImage: "exclamationmark.triangle.fill")
                        .font(.footnote)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(12)
                        .background(.yellow.opacity(0.18), in: RoundedRectangle(cornerRadius: 14))
                        .padding(.horizontal, 12)
                        .padding(.top, 6)
                }
            }
            .scaleEffect(store.showsStartupView && !reduceMotion ? 0.96 : 1.0)
            .allowsHitTesting(!store.showsStartupView)
            .accessibilityHidden(store.showsStartupView)

            // 2. หน้าจอ Loading แอนิเมชัน อยู่ชั้นบนสุด และมี Exit Animation ที่สวยงาม
            if store.showsStartupView {
                StartupView(
                    state: store.launchState,
                    onRetry: {
                        Task { await store.retryLaunch() }
                    },
                    onResume: {
                        Task { await store.resumeRecoveredTrip() }
                    },
                    onDiscard: {
                        Task { await store.discardRecoveredTrip() }
                    }
                )
                .transition(
                    .asymmetric(
                        insertion: .identity,
                        removal: .opacity.combined(with: reduceMotion ? .identity : .scale(scale: 1.06))
                    )
                )
                .zIndex(1)
            }
        }
        .animation(MotionTokens.startupExit(reduceMotion: reduceMotion), value: store.showsStartupView)
        .task {
            await store.prepareForLaunch()
            didFinishLaunchPreparation = true
            if !hasCompletedOnboarding {
                store.showsOnboarding = true
            }
            if let pendingDeepLinkURL {
                let url = pendingDeepLinkURL
                self.pendingDeepLinkURL = nil
                handleIncomingURL(url)
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            guard newPhase == .active else { return }
            store.reconcileAutoStopDeadline()
            Task { await store.refreshReadiness() }
        }
        .onOpenURL(perform: handleIncomingURL)
        .sheet(item: $stopConfirmationRequest) { request in
            StopTripConfirmationSheet(request: request) {
                Task { await store.confirmStop(request) }
            }
            .presentationDetents(stopConfirmationDetents)
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $store.showsOnboarding) {
            OnboardingView(store: store) {
                hasCompletedOnboarding = true
                store.showsOnboarding = false
            }
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
            .interactiveDismissDisabled(!hasCompletedOnboarding)
        }
    }

    private var stopConfirmationDetents: Set<PresentationDetent> {
        if dynamicTypeSize.isAccessibilitySize {
            return [.medium, .large]
        } else if dynamicTypeSize >= .xxxLarge {
            return [.height(330), .medium, .large]
        } else if dynamicTypeSize >= .xxLarge {
            return [.height(295), .medium]
        } else if dynamicTypeSize >= .xLarge {
            return [.height(265), .medium]
        } else {
            return [.height(238)]
        }
    }

    @ViewBuilder
    private var activeScreen: some View {
        DestinationView(store: store, onRequestStopConfirmation: requestStopConfirmation)
    }

    private func handleIncomingURL(_ url: URL) {
        guard let route = NapNavDeepLink.route(for: url) else { return }
        guard didFinishLaunchPreparation else {
            pendingDeepLinkURL = url
            return
        }
        executeDeepLinkRoute(route, url: url)
    }

    private func executeDeepLinkRoute(_ route: NapNavDeepLink, url: URL) {
        switch route {
        case .requestStopConfirmation:
            requestStopConfirmation(for: url)
        case .trip:
            break
        case .quickAction:
            if store.phase == .alarm || store.phase == .arrived {
                store.handleStopAlarm()
                HapticFeedback.success()
            } else if store.phase.isActive {
                requestStopConfirmation()
            } else {
                Task { await store.handleQuickAction() }
            }
        case .stopAlarm:
            store.handleStopAlarm()
            HapticFeedback.success()
        case .startHome:
            Task { await store.startQuickFavoriteTrip(preferringHome: true) }
        }
    }

    private func requestStopConfirmation() {
        stopConfirmationRequest = store.makeStopConfirmationRequest()
    }

    private func requestStopConfirmation(for url: URL) {
        stopConfirmationRequest = NapNavDeepLink.stopConfirmationRequest(for: url, store: store)
    }
}

func trackingRegion(
    current: CLLocationCoordinate2D,
    destination: CLLocationCoordinate2D,
    radiusMeters: Double = 1_000
) -> MKCoordinateRegion {
    let radiusLatitudeDelta = radiusMeters * 2.6 / 111_000
    let longitudeScale = max(cos(destination.latitude * .pi / 180), 0.2)
    let radiusLongitudeDelta = radiusLatitudeDelta / longitudeScale
    let latitudeDelta = max(
        abs(current.latitude - destination.latitude) * 1.8,
        radiusLatitudeDelta,
        0.012
    )
    let longitudeDelta = max(
        abs(current.longitude - destination.longitude) * 1.8,
        radiusLongitudeDelta,
        0.012
    )
    return MKCoordinateRegion(
        center: CLLocationCoordinate2D(
            latitude: (current.latitude + destination.latitude) / 2,
            longitude: (current.longitude + destination.longitude) / 2
        ),
        span: MKCoordinateSpan(
            latitudeDelta: latitudeDelta,
            longitudeDelta: longitudeDelta
        )
    )
}

struct StopTripConfirmationSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    let request: TripStopConfirmationRequest
    let onConfirm: () -> Void

    private var isStopping: Bool {
        request.action == .stop
    }

    var body: some View {
        if dynamicTypeSize.isAccessibilitySize {
            ScrollView {
                content
                    .padding(.horizontal, 22)
                    .padding(.top, 26)
                    .padding(.bottom, 16)
            }
            .scrollBounceBehavior(.basedOnSize)
        } else {
            content
                .padding(.horizontal, 22)
                .padding(.top, 26)
                .padding(.bottom, 16)
        }
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(
                AppLocalization.string(isStopping ? "หยุดทริปนี้หรือไม่?" : "เสร็จสิ้นทริปนี้หรือไม่?"),
                systemImage: isStopping ? "stop.circle.fill" : "checkmark.circle.fill"
            )
            .font(.title3.bold())
            .foregroundStyle(isStopping ? Color.red : Color.green)

            Text(AppLocalization.format(
                isStopping
                    ? "NapNav จะหยุดติดตามตำแหน่งและยกเลิกการแจ้งเตือนของทริปไป %@"
                    : "NapNav จะยกเลิกการแจ้งเตือนของทริปไป %@ และจบทริปนี้",
                request.destinationName
            ))
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .fixedSize(horizontal: false, vertical: true)

            VStack(spacing: 8) {
                Button(role: isStopping ? .destructive : nil, action: confirm) {
                    Text(AppLocalization.string(isStopping ? "หยุดทริป" : "เสร็จสิ้น"))
                        .frame(maxWidth: .infinity)
                }
                .napNavPrimaryButtonStyle()
                .tint(isStopping ? .red : .green)
                .controlSize(.large)

                Button {
                    dismiss()
                } label: {
                    Text(AppLocalization.string(isStopping ? "เดินทางต่อ" : "ยังไม่เสร็จ"))
                        .frame(maxWidth: .infinity)
                }
                .napNavSecondaryButtonStyle()
                .controlSize(.large)
            }
        }
    }

    private func confirm() {
        dismiss()
        onConfirm()
    }
}

struct MapControlCluster: View {
    @Binding var selection: MapDisplayStyle
    let mapScope: Namespace.ID
    let onLocate: () -> Void
    @State private var showsStylePicker = false

    var body: some View {
        HStack(spacing: 10) {
            MapCompass(scope: mapScope)
                .frame(width: 46, height: 46)
                .accessibilityLabel(AppLocalization.string("รีเซ็ตทิศเหนือของแผนที่"))

            Button(action: onLocate) {
                Image(systemName: "location.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .frame(width: 46, height: 46)
                    .foregroundStyle(AppTheme.primary)
                    .napNavGlass(in: Circle(), interactive: true)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(AppLocalization.string("แสดงตำแหน่งของฉัน"))

            Button {
                showsStylePicker = true
            } label: {
                Image(systemName: selection.systemImage)
                    .font(.system(size: 18, weight: .semibold))
                    .frame(width: 46, height: 46)
                    .foregroundStyle(AppTheme.primary)
                    .napNavGlass(in: Circle(), interactive: true)
            }
            .buttonStyle(.plain)
            .popover(isPresented: $showsStylePicker, arrowEdge: .bottom) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(AppLocalization.string("รูปแบบแผนที่"))
                        .font(.headline)
                        .padding(.horizontal, 6)

                    ForEach(MapDisplayStyle.allCases) { style in
                        Button {
                            selection = style
                            showsStylePicker = false
                            HapticFeedback.selection()
                        } label: {
                            HStack {
                                Label(style.title, systemImage: style.systemImage)
                                Spacer()
                                if selection == style {
                                    Image(systemName: "checkmark")
                                        .fontWeight(.semibold)
                                        .foregroundStyle(AppTheme.primary)
                                }
                            }
                            .contentShape(.rect)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 8)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(12)
                .frame(width: 240)
                .presentationCompactAdaptation(.popover)
            }
            .accessibilityLabel(AppLocalization.format("รูปแบบแผนที่ ปัจจุบันแบบ%@", selection.title))
            .accessibilityHint(AppLocalization.string("แตะเพื่อเปลี่ยนรูปแบบแผนที่"))
        }
        .shadow(color: .black.opacity(0.14), radius: 7, y: 3)
    }
}

struct MapHeaderOverlay: View {
    var body: some View {
        ZStack(alignment: .top) {
            Rectangle()
                .fill(.ultraThinMaterial)
                .mask {
                    LinearGradient(
                        stops: [
                            .init(color: .black.opacity(0.88), location: 0),
                            .init(color: .black.opacity(0.65), location: 0.3),
                            .init(color: .black.opacity(0.36), location: 0.75),
                            .init(color: .clear, location: 1.0)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                }
                .frame(height: 115)
                .ignoresSafeArea(edges: .top)

            VStack(spacing: 0) {
                Text("NapNav")
                    .font(.headline)
                Text("Wake at Your Stop")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 10)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

struct DestinationPinView: View {
    let color: Color
    var emphasized = false

    var body: some View {
        ZStack {
            DestinationPinShape()
                .fill(color.opacity(0.92))
                .overlay {
                    DestinationPinShape()
                        .fill(
                            LinearGradient(
                                colors: [
                                    .white.opacity(0.32),
                                    .white.opacity(0.08),
                                    .clear
                                ],
                                startPoint: .topLeading,
                                endPoint: .center
                            )
                        )
                }
                .overlay {
                    DestinationPinShape()
                        .stroke(.white.opacity(0.92), lineWidth: 2)
                }
            Image(systemName: "flag.fill")
                .font(.system(size: 10.5, weight: .bold))
                .foregroundStyle(.white)
                .offset(y: -7)
        }
        .frame(width: 34, height: 44)
        .scaleEffect(emphasized ? 1.10 : 1, anchor: .bottom)
        .shadow(
            color: .black.opacity(emphasized ? 0.32 : 0.18),
            radius: emphasized ? 8 : 3,
            y: emphasized ? 6 : 2
        )
        .accessibilityHidden(true)
    }
}

private struct DestinationPinShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let centerX = rect.midX
        let headRadius = min(rect.width * 0.46, rect.height * 0.36)
        let centerY = rect.minY + headRadius + 2

        path.move(to: CGPoint(x: centerX, y: rect.maxY))
        path.addCurve(
            to: CGPoint(x: centerX - headRadius, y: centerY),
            control1: CGPoint(x: centerX - rect.width * 0.08, y: rect.maxY * 0.78),
            control2: CGPoint(x: centerX - headRadius, y: centerY + headRadius * 0.72)
        )
        path.addArc(
            center: CGPoint(x: centerX, y: centerY),
            radius: headRadius,
            startAngle: .degrees(180),
            endAngle: .degrees(0),
            clockwise: false
        )
        path.addCurve(
            to: CGPoint(x: centerX, y: rect.maxY),
            control1: CGPoint(x: centerX + headRadius, y: centerY + headRadius * 0.72),
            control2: CGPoint(x: centerX + rect.width * 0.08, y: rect.maxY * 0.78)
        )
        path.closeSubpath()
        return path
    }
}

extension MapDisplayStyle {
    var mapStyle: MapStyle {
        switch self {
        case .explore:
            .standard(
                elevation: .realistic,
                pointsOfInterest: .all,
                showsTraffic: false
            )
        case .driving:
            .standard(
                elevation: .realistic,
                pointsOfInterest: .all,
                showsTraffic: true
            )
        case .transit:
            .standard(
                elevation: .realistic,
                pointsOfInterest: .including(.publicTransport),
                showsTraffic: false
            )
        case .satellite:
            .hybrid(
                elevation: .flat,
                pointsOfInterest: .all,
                showsTraffic: false
            )
        }
    }
}

struct RadiusButtonStyle: ButtonStyle {
    let isSelected: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.body.weight(isSelected ? .semibold : .regular))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 11)
            .foregroundStyle(isSelected ? Color.white : Color.primary)
            .background(isSelected ? AppTheme.primary : Color.clear, in: .rect(cornerRadius: 14))
            .napNavGlass(in: RoundedRectangle(cornerRadius: 14), interactive: true)
            .overlay {
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isSelected ? Color.clear : Color.secondary.opacity(0.28))
            }
            .opacity(configuration.isPressed ? 0.72 : 1)
    }
}

func distanceText(_ meters: Double) -> String {
    if meters < 1_000 {
        return AppLocalization.format("%d ม.", Int(meters))
    }

    let kilometers = meters / 1_000
    if kilometers.rounded() == kilometers {
        return AppLocalization.format("%d กม.", Int(kilometers))
    }
    return AppLocalization.format("%.1f กม.", kilometers)
}

#Preview("เลือกจุดหมาย") {
    RootView(store: TripStore())
}

#Preview("ตั้งค่าการเตือน") {
    let store = TripStore()
    store.screen = .setup
    return RootView(store: store)
}
