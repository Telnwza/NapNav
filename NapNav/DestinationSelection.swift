import MapKit
import Observation
import SwiftUI
import UIKit

@MainActor
@Observable
final class CurrentLocationModel {
    private(set) var coordinate: LocationCoordinate?

    @ObservationIgnored
    private let authorizationManager = CLLocationManager()
    @ObservationIgnored
    private var serviceSession: CLServiceSession?
    @ObservationIgnored
    private var updateTask: Task<Void, Never>?
    @ObservationIgnored
    private var timeoutTask: Task<Void, Never>?
    @ObservationIgnored
    private let requestTimeout: Duration

    init(requestTimeout: Duration = .seconds(12)) {
        self.requestTimeout = requestTimeout
    }

    func requestOnce() {
        guard updateTask == nil, coordinate == nil else { return }

        authorizationManager.requestWhenInUseAuthorization()
        serviceSession = CLServiceSession(authorization: .whenInUse)
        let timeout = requestTimeout
        updateTask = Task { [weak self] in
            guard let self else { return }
            defer { self.finishRequest() }

            do {
                for try await update in CLLocationUpdate.liveUpdates() {
                    guard Task.isCancelled == false else { break }
                    if update.authorizationDenied || update.authorizationDeniedGlobally {
                        break
                    }
                    guard update.locationUnavailable == false,
                          let location = update.location,
                          location.horizontalAccuracy >= 0,
                          location.horizontalAccuracy <= 200 else { continue }
                    coordinate = location.coordinate.locationCoordinate
                    break
                }
            } catch {
                // The map keeps its destination fallback when location is unavailable.
            }
        }
        timeoutTask = Task { [weak self] in
            do {
                try await Task.sleep(for: timeout)
                guard Task.isCancelled == false else { return }
                self?.finishRequest()
            } catch {
                // Cancelled because a location arrived or the view disappeared.
            }
        }
    }

    func cancel() {
        finishRequest()
    }

    func requestFreshLocation() {
        finishRequest()
        coordinate = nil
        requestOnce()
    }

    private func finishRequest() {
        let activeUpdateTask = updateTask
        let activeTimeoutTask = timeoutTask
        updateTask = nil
        timeoutTask = nil
        serviceSession = nil
        activeUpdateTask?.cancel()
        activeTimeoutTask?.cancel()
    }
}

@MainActor
@Observable
final class DestinationSelectionModel {
    var candidate: Destination
    var mapPickerState: MapPickerState = .idle
    private(set) var latestCenter: LocationCoordinate

    @ObservationIgnored
    private let resolver: any MapCoordinateResolving
    @ObservationIgnored
    private let debounce: Duration
    @ObservationIgnored
    private var resolutionTask: Task<Void, Never>?
    @ObservationIgnored
    private var requestGeneration = 0

    init(
        candidate: Destination,
        resolver: any MapCoordinateResolving,
        debounce: Duration = .milliseconds(400)
    ) {
        self.candidate = candidate
        self.resolver = resolver
        self.debounce = debounce
        latestCenter = candidate.coordinate
    }

    func selectSearchDestination(_ destination: Destination) {
        cancelResolution()
        candidate = destination
        latestCenter = destination.coordinate
        mapPickerState = .ready
    }

    func cameraDidMove(to center: LocationCoordinate) {
        latestCenter = center
        requestGeneration += 1
        resolutionTask?.cancel()
        resolutionTask = nil
        mapPickerState = .moving
    }

    @discardableResult
    func cameraDidStop(at center: LocationCoordinate) -> Task<Void, Never> {
        latestCenter = center
        requestGeneration += 1
        let generation = requestGeneration
        resolutionTask?.cancel()

        let task = Task { [weak self, resolver, debounce] in
            do {
                try await Task.sleep(for: debounce)
                guard let self,
                      Task.isCancelled == false,
                      generation == self.requestGeneration else { return }

                self.mapPickerState = .resolving
                let resolution = await resolver.resolveDestination(at: center)

                guard Task.isCancelled == false,
                      generation == self.requestGeneration else { return }
                self.candidate = resolution.destination
                self.mapPickerState = resolution.isFallback ? .fallback : .ready
            } catch is CancellationError {
                // A newer camera position owns the next result.
            } catch {
                guard let self,
                      generation == self.requestGeneration else { return }
                self.candidate = Self.fallbackDestination(at: center)
                self.mapPickerState = .fallback
            }
        }
        resolutionTask = task
        return task
    }

    func cancelResolution() {
        requestGeneration += 1
        resolutionTask?.cancel()
        resolutionTask = nil
    }

    /// Place names may snap to a nearby POI, but the trip must keep the exact
    /// center coordinate underneath the pin that the user positioned.
    func destinationForConfirmation() -> Destination {
        let isSameCoordinate = abs(latestCenter.latitude - candidate.coordinate.latitude) < 0.00001
            && abs(latestCenter.longitude - candidate.coordinate.longitude) < 0.00001

        let resolvedID = isSameCoordinate
            ? candidate.id
            : String(
                format: "%.6f,%.6f",
                locale: Locale(identifier: "en_US_POSIX"),
                latestCenter.latitude,
                latestCenter.longitude
            )

        return Destination(
            id: resolvedID,
            name: candidate.name,
            detail: candidate.detail,
            coordinate: latestCenter
        )
    }

    private static func fallbackDestination(at coordinate: LocationCoordinate) -> Destination {
        let detail = String(
            format: "%.5f, %.5f",
            locale: Locale(identifier: "en_US_POSIX"),
            coordinate.latitude,
            coordinate.longitude
        )
        return Destination(
            id: String(
                format: "%.6f,%.6f",
                locale: Locale(identifier: "en_US_POSIX"),
                coordinate.latitude,
                coordinate.longitude
            ),
            name: AppLocalization.string("จุดที่เลือกบนแผนที่"),
            detail: detail,
            coordinate: coordinate
        )
    }
}

@MainActor
struct DestinationView: View {
    private enum PanelState {
        case compact
        case expanded
    }

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.openURL) private var openURL
    var store: TripStore
    let onRequestStopConfirmation: () -> Void
    @State private var search: PlaceSearchService
    @State private var selection: DestinationSelectionModel
    @State private var currentLocation = CurrentLocationModel()
    @State private var position: MapCameraPosition
    @State private var searchText = ""
    @State private var resolvedSuggestions: [String: Destination] = [:]
    @State private var resolvingSuggestionID: String?
    @State private var selectionTask: Task<Void, Never>?
    @State private var panelState: PanelState = .compact
    @State private var usesCustomRadius = false
    @State private var didCenterOnInitialLocation = false
    @State private var didFrameTrip = false
    private enum DestinationSheetItem: Identifiable {
        case settings
        case saveFavorite
        case editFavorite(SavedDestination)

        var id: String {
            switch self {
            case .settings:
                return "settings"
            case .saveFavorite:
                return "saveFavorite"
            case .editFavorite(let fav):
                return "editFavorite-\(fav.id)"
            }
        }
    }

    @State private var sheetItem: DestinationSheetItem?
    @State private var favoritePendingDeletion: SavedDestination?
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @GestureState private var panelDragOffset: CGFloat = 0
    @FocusState private var searchIsFocused: Bool
    @Namespace private var mapScope
    @Namespace private var cardNamespace

    private var isRegularWidth: Bool {
        horizontalSizeClass == .regular
    }

    private let presets = [500.0, 1_000.0, 2_000.0]

    init(store: TripStore, onRequestStopConfirmation: @escaping () -> Void) {
        self.store = store
        self.onRequestStopConfirmation = onRequestStopConfirmation
        let search = PlaceSearchService()
        _search = State(initialValue: search)
        _selection = State(
            initialValue: DestinationSelectionModel(
                candidate: store.destination,
                resolver: search
            )
        )
        _position = State(
            initialValue: .userLocation(
                followsHeading: false,
                fallback: Self.position(for: store.destination)
            )
        )
    }

    var body: some View {
        GeometryReader { proxy in
            let panelHeight = planningPanelHeight(in: proxy.size.height)

            ZStack {
                mapView
                if store.screen != .tracking {
                    MapHeaderOverlay()
                }
                trackingDistanceOverlay
                bottomContainer(panelHeight: panelHeight, bottomInset: proxy.safeAreaInsets.bottom)
                    .frame(maxHeight: .infinity, alignment: .bottom)
            }
            .animation(MotionTokens.morphSpring(reduceMotion: reduceMotion), value: store.screen)
            .animation(MotionTokens.morphSpring(reduceMotion: reduceMotion), value: panelHeight)
            .overlay(alignment: .bottomTrailing) {
                mapControlsOverlay(panelHeight: panelHeight, safeBottom: proxy.safeAreaInsets.bottom)
            }
            .overlay(alignment: .topTrailing) {
                settingsButtonOverlay
            }
            .mapScope(mapScope)
        }
        .toolbar(.hidden, for: .navigationBar)
        .task {
            currentLocation.requestOnce()
        }
        .onChange(of: store.phase) { _, phase in
            if phase == .alarm {
                HapticFeedback.warning()
            } else if phase == .arrived {
                HapticFeedback.success()
            }
        }
        .onChange(of: currentLocation.coordinate) { _, coordinate in
            guard let coordinate,
                  didCenterOnInitialLocation == false,
                  store.screen == .destination else { return }
            didCenterOnInitialLocation = true
            centerOnUser(coordinate)
        }
        .task(id: searchText) {
            do {
                try await Task.sleep(for: .milliseconds(300))
                guard Task.isCancelled == false else { return }
                resolvedSuggestions = [:]
                search.updateQuery(searchText)
            } catch {
                return
            }
        }
        .onChange(of: searchIsFocused) { _, focused in
            guard focused else { return }
            withAnimation(.snappy(duration: 0.28)) {
                panelState = .expanded
            }
        }
        .onChange(of: store.screen) { oldScreen, newScreen in
            searchIsFocused = false
            searchText = ""
            search.updateQuery("")

            switch newScreen {
            case .destination:
                didFrameTrip = false
                panelState = .compact
                withAnimation(.easeInOut(duration: oldScreen == .tracking ? MotionTokens.cameraFly : MotionTokens.mapCamera)) {
                    position = Self.position(for: store.destination)
                }
            case .setup:
                didFrameTrip = false
                panelState = .compact
                withAnimation(.easeInOut(duration: MotionTokens.mapCamera)) {
                    position = .region(
                        Self.radiusRegion(
                            destination: store.destination.coordinate.clCoordinate,
                            radiusMeters: store.selectedRadiusMeters
                        )
                    )
                }
            case .tracking:
                didFrameTrip = false
                let current = store.currentCoordinate ?? currentLocation.coordinate
                if let current {
                    withAnimation(.easeInOut(duration: MotionTokens.cameraFly)) {
                        position = .region(
                            trackingRegion(
                                current: current.clCoordinate,
                                destination: store.destination.coordinate.clCoordinate,
                                radiusMeters: store.selectedRadiusMeters
                            )
                        )
                    }
                } else {
                    withAnimation(.easeInOut(duration: MotionTokens.cameraFly)) {
                        position = .region(
                            trackingRegion(
                                current: store.destination.coordinate.clCoordinate,
                                destination: store.destination.coordinate.clCoordinate,
                                radiusMeters: store.selectedRadiusMeters
                            )
                        )
                    }
                }
            }
        }
        .onChange(of: store.currentCoordinate) { _, coordinate in
            guard store.screen == .tracking, let coordinate, didFrameTrip == false else { return }
            didFrameTrip = true
            withAnimation(.easeInOut(duration: MotionTokens.cameraFly)) {
                position = .region(
                    trackingRegion(
                        current: coordinate.clCoordinate,
                        destination: store.destination.coordinate.clCoordinate,
                        radiusMeters: store.selectedRadiusMeters
                    )
                )
            }
        }
        .onChange(of: store.selectedRadiusMeters) { _, radius in
            guard store.screen == .setup else { return }
            withAnimation(.easeInOut(duration: MotionTokens.mapCamera)) {
                position = .region(
                    Self.radiusRegion(
                        destination: store.destination.coordinate.clCoordinate,
                        radiusMeters: radius
                    )
                )
            }
        }
        .onDisappear {
            selectionTask?.cancel()
            selection.cancelResolution()
            currentLocation.cancel()
        }
        .sheet(item: $sheetItem, onDismiss: {
            if store.showsSettings {
                store.showsSettings = false
            }
        }) { item in
            switch item {
            case .settings:
                AlertSettingsView(store: store)
            case .saveFavorite:
                SaveFavoriteSheet(
                    initialTitle: selection.candidate.name,
                    subtitle: selection.candidate.detail,
                    coordinate: selection.candidate.coordinate,
                    initialRadius: store.selectedRadiusMeters,
                    isEditing: false,
                    onSave: { title, icon, radius in
                        store.saveFavorite(
                            title: title,
                            subtitle: selection.candidate.detail,
                            coordinate: selection.candidate.coordinate,
                            radiusMeters: radius,
                            icon: icon
                        )
                        sheetItem = nil
                        HapticFeedback.success()
                    },
                    onCancel: {
                        sheetItem = nil
                    }
                )
            case .editFavorite(let fav):
                SaveFavoriteSheet(
                    initialTitle: fav.title,
                    subtitle: fav.subtitle,
                    coordinate: fav.coordinate,
                    initialRadius: fav.radiusMeters,
                    initialIcon: fav.icon,
                    isEditing: true,
                    onSave: { title, icon, radius in
                        store.updateFavorite(
                            id: fav.id,
                            title: title,
                            icon: icon,
                            radiusMeters: radius
                        )
                        sheetItem = nil
                        HapticFeedback.success()
                    },
                    onDelete: {
                        store.removeFavorite(id: fav.id)
                        sheetItem = nil
                        HapticFeedback.warning()
                    },
                    onCancel: {
                        sheetItem = nil
                    }
                )
            }
        }
        .onChange(of: store.showsSettings) { _, shows in
            if shows && sheetItem == nil {
                sheetItem = .settings
            } else if !shows && sheetItem?.id == "settings" {
                sheetItem = nil
            }
        }
        .alert(
            AppLocalization.string("ลบสถานที่โปรดนี้หรือไม่?"),
            isPresented: Binding(
                get: { favoritePendingDeletion != nil },
                set: { if !$0 { favoritePendingDeletion = nil } }
            ),
            presenting: favoritePendingDeletion
        ) { fav in
            Button(AppLocalization.string("ลบสถานที่โปรด"), role: .destructive) {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    store.removeFavorite(id: fav.id)
                }
                HapticFeedback.warning()
                favoritePendingDeletion = nil
            }
            Button(AppLocalization.string("ยกเลิก"), role: .cancel) {
                favoritePendingDeletion = nil
            }
        } message: { fav in
            Text(AppLocalization.format("คุณแน่ใจหรือไม่ว่าต้องการลบ \"%@\" ออกจากรายการโปรด?", fav.title))
        }
    }


    @ViewBuilder
    private var mapView: some View {
        Map(position: $position, scope: mapScope) {
            UserAnnotation()

            if store.screen == .setup {
                MapCircle(
                    center: store.destination.coordinate.clCoordinate,
                    radius: store.selectedRadiusMeters
                )
                .foregroundStyle(AppTheme.secondary.opacity(0.35))
                .stroke(AppTheme.primary, lineWidth: 2)

                Annotation(
                    store.destination.name,
                    coordinate: store.destination.coordinate.clCoordinate,
                    anchor: .bottom
                ) {
                    DestinationPinView(color: AppTheme.primary)
                }
            } else if store.screen == .tracking {
                MapCircle(
                    center: store.destination.coordinate.clCoordinate,
                    radius: store.selectedRadiusMeters
                )
                .foregroundStyle(.orange.opacity(0.13))
                .stroke(.orange, lineWidth: 2)

                if let currentCoordinate = store.currentCoordinate {
                    MapPolyline(coordinates: [
                        currentCoordinate.clCoordinate,
                        store.destination.coordinate.clCoordinate
                    ])
                    .stroke(.orange.opacity(0.72), lineWidth: 3)
                }

                Annotation(
                    store.destination.name,
                    coordinate: store.destination.coordinate.clCoordinate,
                    anchor: .bottom
                ) {
                    DestinationPinView(color: .orange)
                }
            }
        }
        .mapStyle(store.mapDisplayStyle.mapStyle)
        .mapControlVisibility(.hidden)
        .onMapCameraChange(frequency: .continuous) { context in
            guard store.screen == .destination,
                  position.positionedByUser else { return }
            selection.cameraDidMove(to: context.region.center.locationCoordinate)
        }
        .onMapCameraChange(frequency: .onEnd) { context in
            search.updateRegion(context.region)
            guard store.screen == .destination,
                  position.positionedByUser else { return }
            selection.cameraDidStop(at: context.region.center.locationCoordinate)
            HapticFeedback.selection()
        }
        .overlay {
            if store.screen == .destination {
                centerPin
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .allowsHitTesting(false)
                    .transition(.scale(scale: 0.8).combined(with: .opacity))
            }
        }
        .ignoresSafeArea()
        .accessibilityLabel(mapAccessibilityLabel)
    }

    @ViewBuilder
    private var trackingDistanceOverlay: some View {
        VStack {
            if store.screen == .tracking {
                distanceCard
                    .padding(.top, 12)
                    .transition(
                        .asymmetric(
                            insertion: .move(edge: .top).combined(with: .opacity),
                            removal: .move(edge: .top).combined(with: .opacity)
                        )
                    )
            }
            Spacer()
        }
        .padding(.horizontal)
        .allowsHitTesting(store.screen == .tracking)
    }

    @ViewBuilder
    private func mapControlsOverlay(panelHeight: CGFloat, safeBottom: CGFloat) -> some View {
        MapControlCluster(
            selection: Binding(
                get: { store.mapDisplayStyle },
                set: { store.mapDisplayStyle = $0 }
            ),
            mapScope: mapScope,
            onLocate: recenterOnUser
        )
        .padding(.trailing, 16)
        .padding(
            .bottom,
            clusterBottomPadding(panelHeight: panelHeight, safeBottom: safeBottom)
        )
    }

    @ViewBuilder
    private var settingsButtonOverlay: some View {
        Button {
            store.showsSettings = true
            sheetItem = .settings
            HapticFeedback.selection()
        } label: {
            Image(systemName: "gearshape.fill")
                .font(.system(size: 17, weight: .semibold))
                .frame(width: 44, height: 44)
                .foregroundStyle(.primary)
                .napNavGlass(in: Circle(), interactive: true)
        }
        .buttonStyle(.plain)
        .contentShape(Circle())
        .accessibilityLabel(AppLocalization.string("การตั้งค่า NapNav"))
        .accessibilityIdentifier("alertSettingsButton")
        .padding(.trailing, 16)
        .padding(.top, 8)
        .transition(.opacity)
    }

    private var mapAccessibilityLabel: String {
        store.screen == .tracking
            ? "แผนที่ติดตามตำแหน่งปัจจุบันเทียบกับ \(store.destination.name)"
            : "แผนที่เลือกจุดหมาย ค้นหาสถานที่หรือเลื่อนแผนที่ให้จุดหมายอยู่ใต้หมุดกลางจอ"
    }

    private func clusterBottomPadding(panelHeight: CGFloat, safeBottom: CGFloat) -> CGFloat {
        if isRegularWidth {
            return max(safeBottom + 20, 28)
        }
        if store.screen == .tracking {
            return max(safeBottom + 96, 108)
        } else {
            return max(panelHeight - safeBottom + 12, 12)
        }
    }

    @ViewBuilder
    private func bottomContainer(panelHeight: CGFloat, bottomInset: CGFloat) -> some View {
        Group {
            if store.screen == .tracking {
                VStack(spacing: 0) {
                    tripControlsCard
                }
                .napNavGlass(in: .rect(cornerRadius: 22))
                .clipShape(.rect(cornerRadius: 22))
                .shadow(color: .black.opacity(0.12), radius: 14, y: 4)
                .frame(maxWidth: isRegularWidth ? 500 : .infinity)
                .padding(.horizontal, 16)
                .padding(.bottom, max(bottomInset, 12))
                .matchedGeometryEffect(id: "bottomGlassContainer", in: cardNamespace)
                .transition(
                    .asymmetric(
                        insertion: .opacity.combined(with: .scale(scale: 0.96)),
                        removal: .opacity.combined(with: .scale(scale: 0.96))
                    )
                )
            } else {
                planningPanel(height: panelHeight, bottomInset: bottomInset)
                    .matchedGeometryEffect(id: "bottomGlassContainer", in: cardNamespace)
                    .transition(
                        .asymmetric(
                            insertion: .opacity.combined(with: .scale(scale: 0.98)),
                            removal: .opacity.combined(with: .scale(scale: 0.98))
                        )
                    )
            }
        }
    }

    private var distanceCard: some View {
        VStack(spacing: 2) {
            Text(statusTitle)
                .font(.caption.weight(.semibold))
                .foregroundStyle(statusColor)

            if store.phase == .arrived {
                Text(AppLocalization.string("ถึงจุดหมายแล้ว"))
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(.green)
                    .frame(minHeight: 48)
            } else if let distance = store.currentDistanceMeters {
                Text(distanceText(distance))
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .minimumScaleFactor(0.75)
            } else {
                HStack {
                    ProgressView()
                    Text(AppLocalization.string("กำลังหาตำแหน่ง"))
                        .font(.headline)
                }
                .frame(minHeight: 48)
                .accessibilityLabel(AppLocalization.string("กำลังรอตำแหน่ง"))
            }

            Text(AppLocalization.format("ถึง %@", store.destination.name))
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(2)
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 12)
        .napNavGlass(in: .rect(cornerRadius: 22))
        .shadow(color: .black.opacity(0.08), radius: 10, y: 4)
        .accessibilityElement(children: .combine)
    }

    private var tripControlsCard: some View {
        VStack(alignment: .leading) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    if store.phase == .arrived {
                        Text(AppLocalization.string("สิ้นสุดทริป"))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        if let autoStopAt = store.autoStopAt, autoStopAt > Date() {
                            HStack(spacing: 4) {
                                Text(AppLocalization.string("หยุดใน"))
                                Text(timerInterval: Date()...autoStopAt, countsDown: true)
                                    .monospacedDigit()
                            }
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.primary)
                        } else {
                            Text(AppLocalization.string("ถึงที่หมายเรียบร้อย"))
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(.secondary)
                        }
                    } else {
                        Text(AppLocalization.string("เตือนเมื่อเหลือ"))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(distanceText(store.selectedRadiusMeters))
                            .font(.headline)
                    }
                }
                Spacer()
                if store.phase == .arrived {
                    Button(AppLocalization.string("เสร็จสิ้น")) {
                        store.completeTrip()
                    }
                    .napNavPrimaryButtonStyle()
                    .tint(.green)
                    .accessibilityIdentifier("completeTripButton")
                } else {
                    Button(AppLocalization.string("หยุด"), role: .destructive) {
                        onRequestStopConfirmation()
                    }
                    .napNavPrimaryButtonStyle()
                    .tint(.red)
                    .accessibilityIdentifier("stopTripButton")
                }
            }

            if let warningText {
                Divider()
                Label(warningText, systemImage: "exclamationmark.triangle.fill")
                    .font(.caption)
                    .foregroundStyle(.orange)

                if needsSettingsButton {
                    Button(AppLocalization.string("เปิด Settings"), action: openSettings)
                        .napNavSecondaryButtonStyle()
                        .controlSize(.small)
                }
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var statusTitle: String {
        switch store.phase {
        case .arrived:
            AppLocalization.string("ถึงแล้ว")
        case .approaching, .alarm:
            AppLocalization.string("ใกล้ถึง")
        default:
            if store.arrivalStatus == .nearby {
                AppLocalization.string("ใกล้ถึง")
            } else {
                store.locationStatus == .receiving
                    ? AppLocalization.string("กำลังเดินทาง")
                    : AppLocalization.string("กำลังหาตำแหน่ง")
            }
        }
    }

    private var statusColor: Color {
        switch store.phase {
        case .arrived:
            .green
        case .approaching, .alarm:
            .orange
        default:
            AppTheme.primary
        }
    }

    private var warningText: String? {
        if store.recoveryAvailable == false {
            return AppLocalization.string("ทริปนี้อาจกู้คืนไม่ได้หากปิดแอป")
        }

        if let result = store.lastAlertDeliveryResult {
            switch result {
            case .deliveryUnavailable:
                return result.summary
            case .fallbackUsed:
                return AppLocalization.format("ใช้เส้นทางสำรอง — %@", result.summary)
            case .alarmScheduled(companionNotificationScheduled: false)
                where store.alertPreferences.deliveryMode == .both:
                return AppLocalization.string("ตั้ง AlarmKit สำเร็จ แต่ companion Notification ตั้งไม่สำเร็จ")
            case .alarmScheduled, .notificationScheduled:
                break
            }
        }

        switch store.locationStatus {
        case .accuracyLimited:
            return AppLocalization.string("ตำแหน่งยังไม่แม่นพอ ลองเปิด Precise Location")
        case .denied:
            return AppLocalization.string("ไม่ได้รับสิทธิ์ตำแหน่ง")
        case .servicesDisabled:
            return AppLocalization.string("Location Services ปิดอยู่")
        case .failed(let message):
            return message
        case .unavailable:
            return AppLocalization.string("ยังหาตำแหน่งไม่ได้ ลองออกไปในที่โล่ง")
        case .idle, .requestingPermission, .receiving:
            break
        }

        if store.alertDeliveryReady == false {
            return store.alertDeliveryPlan.summary
        }
        if store.alertDeliveryPlan.paths.contains(.notification(sound: .mutedBySystem)) {
            return AppLocalization.string("การแจ้งเตือนอาจไม่มีเสียง")
        }
        if store.alarmReadiness.lockScreenEnabled == false {
            return AppLocalization.string("การแจ้งเตือนไม่แสดงบนหน้าจอล็อก")
        }
        return nil
    }

    private var needsSettingsButton: Bool {
        if case .deliveryUnavailable? = store.lastAlertDeliveryResult {
            return true
        }

        switch store.locationStatus {
        case .denied, .servicesDisabled:
            return true
        default:
            return store.alertDeliveryReady == false
                || store.alarmReadiness.soundsEnabled == false
                || store.alarmReadiness.lockScreenEnabled == false
        }
    }

    private func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        openURL(url)
    }

    private var planningPanelShape: UnevenRoundedRectangle {
        UnevenRoundedRectangle(
            topLeadingRadius: isRegularWidth ? 26 : 28,
            bottomLeadingRadius: isRegularWidth ? 26 : 0,
            bottomTrailingRadius: isRegularWidth ? 26 : 0,
            topTrailingRadius: isRegularWidth ? 26 : 28
        )
    }

    private func planningPanel(height: CGFloat, bottomInset: CGFloat) -> some View {
        VStack(spacing: 0) {
            // Drag Handle Area with generous touch target and tap-to-toggle
            ZStack {
                Capsule()
                    .fill(.secondary.opacity(0.55))
                    .frame(width: 42, height: 5)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 30)
            .contentShape(.rect)
            .gesture(panelDragGesture)
            .onTapGesture {
                guard store.screen == .destination else { return }
                HapticFeedback.selection()
                withAnimation(.snappy(duration: 0.28)) {
                    if panelState == .compact {
                        panelState = .expanded
                    } else {
                        panelState = .compact
                        searchIsFocused = false
                    }
                }
            }

            planningSheet
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .padding(.bottom, isRegularWidth ? 8 : max(bottomInset, 8))
        .frame(height: height, alignment: .top)
        .frame(maxWidth: isRegularWidth ? 500 : .infinity)
        .napNavGlass(in: planningPanelShape)
        .clipShape(planningPanelShape)
        .shadow(color: .black.opacity(0.16), radius: 18, y: isRegularWidth ? 6 : -4)
        .padding(.bottom, isRegularWidth ? max(bottomInset, 16) : 0)
        .padding(.horizontal, isRegularWidth ? 24 : 0)
        .ignoresSafeArea(.container, edges: isRegularWidth ? [] : .bottom)
    }

    private var panelDragGesture: some Gesture {
        DragGesture(minimumDistance: 6)
            .updating($panelDragOffset) { value, state, _ in
                state = value.translation.height
            }
            .onEnded { value in
                guard store.screen == .destination else { return }
                let dragDistance = value.translation.height
                let predictedDistance = value.predictedEndTranslation.height

                withAnimation(.snappy(duration: 0.28)) {
                    if panelState == .compact {
                        // In compact mode: expand if dragged up at least 25pt or flicked upward
                        if dragDistance < -25 || predictedDistance < -30 {
                            panelState = .expanded
                        } else {
                            panelState = .compact
                        }
                    } else {
                        // In expanded mode: collapse if dragged down at least 25pt or flicked downward
                        if dragDistance > 25 || predictedDistance > 30 {
                            panelState = .compact
                            searchIsFocused = false
                        } else {
                            panelState = .expanded
                        }
                    }
                }
            }
    }

    private func planningPanelHeight(in availableHeight: CGFloat) -> CGFloat {
        if store.screen == .setup {
            let baseContentHeight: CGFloat = usesCustomRadius ? 326 : 278
            let contentHeight: CGFloat = dynamicTypeSize.isAccessibilitySize ? baseContentHeight + 80 : baseContentHeight
            return min(contentHeight, availableHeight * (dynamicTypeSize.isAccessibilitySize ? 0.65 : 0.50))
        }

        let compactHeight: CGFloat = dynamicTypeSize.isAccessibilitySize ? 260 : 214
        let expandedMaxFraction = dynamicTypeSize.isAccessibilitySize ? 0.90 : 0.82
        let expandedHeight = isRegularWidth
            ? min(520, availableHeight * 0.65)
            : min(max(availableHeight * 0.65, 420), availableHeight * expandedMaxFraction)
        let restingHeight = panelState == .expanded ? expandedHeight : compactHeight
        return min(max(restingHeight - panelDragOffset, compactHeight), expandedHeight)
    }

    @ViewBuilder
    private var planningSheet: some View {
        switch store.screen {
        case .destination:
            destinationSheet
                .transition(
                    .asymmetric(
                        insertion: .opacity.combined(with: .move(edge: .leading)),
                        removal: .opacity.combined(with: .move(edge: .leading))
                    )
                )
        case .setup:
            radiusSheet
                .transition(
                    .asymmetric(
                        insertion: .opacity.combined(with: .move(edge: .trailing)),
                        removal: .opacity.combined(with: .move(edge: .trailing))
                    )
                )
        case .tracking:
            EmptyView()
        }
    }

    private var destinationSheet: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField(AppLocalization.string("ค้นหาสถานที่"), text: $searchText)
                    .focused($searchIsFocused)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .submitLabel(.search)
                    .accessibilityIdentifier("destinationSearchField")
                if searchText.isEmpty == false {
                    Button(AppLocalization.string("ล้าง"), systemImage: "xmark.circle.fill") {
                        searchText = ""
                    }
                    .labelStyle(.iconOnly)
                    .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 14)
            .frame(height: 46)
            .napNavGlass(in: RoundedRectangle(cornerRadius: 14), interactive: true)

            if searchText.isEmpty == false, panelState == .expanded {
                searchResults
            } else if panelState == .expanded {
                savedPlacesList
            } else {
                destinationSummary
                    .contentShape(.rect)
                    .simultaneousGesture(panelDragGesture)
            }
        }
        .padding(.horizontal, 18)
        .padding(.bottom, 14)
    }

    private var savedPlacesList: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 14) {
                if store.favorites.isEmpty == false {
                    favoritesSection
                }

                if store.recents.isEmpty == false {
                    recentsSection
                }

                if store.favorites.isEmpty, store.recents.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "star")
                            .font(.system(size: 28))
                            .foregroundStyle(.tertiary)
                        Text(AppLocalization.string("แตะไอคอนดาวเพื่อบันทึกสถานที่โปรด"))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 32)
                }
            }
            .padding(.bottom, 36)
        }
    }

    private var favoritesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(AppLocalization.string("สถานที่โปรด"), systemImage: "star.fill")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .padding(.top, 4)

            ForEach(store.favorites) { fav in
                AppleSwipeRow(
                    trailingAction: SwipeActionItem(
                        title: AppLocalization.string("ลบ"),
                        systemImage: "trash.fill",
                        tint: Color(red: 1.0, green: 0.27, blue: 0.27),
                        action: {
                            favoritePendingDeletion = fav
                        }
                    )
                ) {
                    favoriteCard(fav)
                }
            }
        }
    }

    private func favoriteCard(_ fav: SavedDestination) -> some View {
        HStack(spacing: 12) {
            Image(systemName: fav.icon.rawValue)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 34, height: 34)
                .background(Color.accentColor, in: Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(fav.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(dynamicTypeSize.isAccessibilitySize ? 2 : 1)
                HStack(spacing: 4) {
                    if fav.subtitle.isEmpty == false {
                        Text(fav.subtitle)
                            .lineLimit(dynamicTypeSize.isAccessibilitySize ? 2 : 1)
                        Text("•")
                    }
                    Text(distanceText(fav.radiusMeters))
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Spacer()

            Button {
                sheetItem = .editFavorite(fav)
            } label: {
                Image(systemName: "pencil")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .frame(width: 32, height: 32)
                    .background(Color.secondary.opacity(0.12), in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(AppLocalization.string("แก้ไขสถานที่โปรด"))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .napNavGlass(in: RoundedRectangle(cornerRadius: 12), interactive: true)
        .contentShape(.rect)
        .onTapGesture {
            selectSaved(fav)
        }
        .contextMenu {
            Button {
                sheetItem = .editFavorite(fav)
            } label: {
                Label(AppLocalization.string("แก้ไข"), systemImage: "pencil")
            }
            Button(role: .destructive) {
                favoritePendingDeletion = fav
            } label: {
                Label(AppLocalization.string("ลบออกจากสถานที่โปรด"), systemImage: "trash")
            }
        }
    }

    private var recentsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label(AppLocalization.string("ประวัติล่าสุด"), systemImage: "clock")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                Button(AppLocalization.string("ล้างประวัติ")) {
                    withAnimation {
                        store.clearRecents()
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            .padding(.top, 4)

            ForEach(store.recents) { item in
                AppleSwipeRow(
                    leadingAction: SwipeActionItem(
                        title: AppLocalization.string("โปรด"),
                        systemImage: "star.fill",
                        tint: Color(red: 1.0, green: 0.62, blue: 0.04),
                        action: {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                store.addRecentToFavorites(item)
                            }
                            HapticFeedback.success()
                        }
                    ),
                    trailingAction: SwipeActionItem(
                        title: AppLocalization.string("ลบ"),
                        systemImage: "trash.fill",
                        tint: Color(red: 1.0, green: 0.27, blue: 0.27),
                        action: {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                store.removeRecent(id: item.id)
                            }
                            HapticFeedback.warning()
                        }
                    )
                ) {
                    recentCard(item)
                }
            }
        }
    }

    private func recentCard(_ item: SavedDestination) -> some View {
        HStack(spacing: 12) {
            Image(systemName: item.icon.rawValue)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .frame(width: 32, height: 32)
                .background(Color.secondary.opacity(0.1), in: Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.primary)
                    .lineLimit(dynamicTypeSize.isAccessibilitySize ? 2 : 1)
                if item.subtitle.isEmpty == false {
                    Text(item.subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(dynamicTypeSize.isAccessibilitySize ? 2 : 1)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption2.bold())
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .napNavGlass(in: RoundedRectangle(cornerRadius: 12), interactive: true)
        .contentShape(.rect)
        .onTapGesture {
            selectSaved(item)
        }
        .contextMenu {
            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    store.addRecentToFavorites(item)
                }
                HapticFeedback.success()
            } label: {
                Label(AppLocalization.string("เพิ่มเป็นสถานที่โปรด"), systemImage: "star")
            }
            Button(role: .destructive) {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    store.removeRecent(id: item.id)
                }
                HapticFeedback.warning()
            } label: {
                Label(AppLocalization.string("ลบออกจากประวัติ"), systemImage: "trash")
            }
        }
    }

    private var destinationSummary: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(selection.candidate.name)
                        .font(.title3.bold())
                        .lineLimit(panelState == .compact ? 1 : 2)
                        .accessibilityAddTraits(.isHeader)
                    Text(selection.candidate.detail)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(panelState == .compact ? 1 : 2)
                }
                Spacer(minLength: 12)
                if isBusy {
                    ProgressView()
                        .controlSize(.small)
                } else {
                    Button {
                        if store.isFavorite(selection.candidate) {
                            if let fav = store.favorite(for: selection.candidate) {
                                sheetItem = .editFavorite(fav)
                            } else {
                                store.removeFavorite(for: selection.candidate)
                                HapticFeedback.selection()
                            }
                        } else {
                            sheetItem = .saveFavorite
                        }
                    } label: {
                        Image(systemName: store.isFavorite(selection.candidate) ? "star.fill" : "star")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(store.isFavorite(selection.candidate) ? .yellow : .secondary)
                            .frame(width: 36, height: 36)
                            .background(Color.secondary.opacity(0.12), in: Circle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(store.isFavorite(selection.candidate) ? AppLocalization.string("แก้ไขสถานที่โปรด") : AppLocalization.string("บันทึกเป็นสถานที่โปรด"))
                }
            }

            if panelState == .expanded, let statusText {
                Text(statusText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            if panelState == .expanded,
               let errorMessage = search.errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundStyle(.orange)
            }

            Button(AppLocalization.string("เลือกจุดหมายนี้"), action: confirmCandidate)
                .frame(maxWidth: .infinity)
                .napNavPrimaryButtonStyle()
                .controlSize(.large)
                .disabled(isBusy)
                .accessibilityIdentifier("useDestinationButton")
                .padding(.top, 4)
        }
    }

    private var searchResults: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                switch search.resultsState {
                case .loading:
                    ProgressView(AppLocalization.string("กำลังค้นหาสถานที่…"))
                        .frame(maxWidth: .infinity, minHeight: 112)
                        .padding(.top, 12)
                case .empty:
                    ContentUnavailableView {
                        Label(AppLocalization.string("ไม่พบสถานที่"), systemImage: "magnifyingglass")
                    } description: {
                        Text(AppLocalization.string("ลองค้นหาด้วยชื่อหรือที่อยู่อื่น"))
                    }
                    .padding(.top, 16)
                case .failed(let message):
                    ContentUnavailableView {
                        Label(AppLocalization.string("ค้นหาสถานที่ไม่สำเร็จ"), systemImage: "exclamationmark.triangle")
                    } description: {
                        Text(message)
                    } actions: {
                        Button(AppLocalization.string("ลองใหม่"), action: retrySearch)
                            .buttonStyle(.bordered)
                    }
                    .padding(.top, 16)
                case .results:
                    if let message = search.errorMessage {
                        VStack(alignment: .leading, spacing: 8) {
                            Label(message, systemImage: "exclamationmark.triangle")
                                .font(.caption)
                                .foregroundStyle(.orange)
                            Button(AppLocalization.string("ลองใหม่"), action: retrySearch)
                                .font(.caption)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(12)
                    }

                    ForEach(Array(search.suggestions.enumerated()), id: \.element.id) { index, suggestion in
                        Button {
                            choose(suggestion)
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "mappin.circle.fill")
                                    .foregroundStyle(AppTheme.primary)
                                    .frame(width: 24, alignment: .center)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(suggestion.title)
                                        .foregroundStyle(.primary)
                                        .lineLimit(1)
                                    if suggestion.subtitle.isEmpty == false {
                                        Text(suggestion.subtitle)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                            .lineLimit(2)
                                    }
                                }
                                Spacer()
                                if resolvingSuggestionID == suggestion.id {
                                    ProgressView()
                                        .controlSize(.small)
                                } else if let distance = distanceToSuggestion(suggestion) {
                                    Text(distanceText(distance))
                                        .font(.caption.monospacedDigit())
                                        .foregroundStyle(.secondary)
                                        .fixedSize()
                                }
                            }
                            .frame(minHeight: 56)
                            .contentShape(.rect)
                        }
                        .buttonStyle(.plain)
                        .disabled(resolvingSuggestionID != nil)

                        if index < search.suggestions.count - 1 {
                            Divider()
                                .padding(.leading, 36)
                        }
                    }
                }
            }
        }
        .scrollDismissesKeyboard(.interactively)
    }

    private var radiusSheet: some View {
        VStack(alignment: .leading) {
            HStack(alignment: .firstTextBaseline) {
                Button(AppLocalization.string("กลับไปเลือกจุดหมาย"), systemImage: "chevron.left") {
                    store.screen = .destination
                }
                .labelStyle(.iconOnly)
                .accessibilityLabel(AppLocalization.string("กลับไปเลือกจุดหมาย"))

                VStack(alignment: .leading, spacing: 2) {
                    Text(store.destination.name)
                        .font(.title3.bold())
                        .lineLimit(2)
                    Text(AppLocalization.string("ให้ปลุกตอนเหลือระยะเท่าไร?"))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }

            HStack {
                ForEach(presets, id: \.self) { radius in
                    Button(distanceText(radius)) {
                        store.selectedRadiusMeters = radius
                        usesCustomRadius = false
                    }
                    .buttonStyle(
                        RadiusButtonStyle(
                            isSelected: usesCustomRadius == false
                                && store.selectedRadiusMeters == radius
                        )
                    )
                    .accessibilityLabel(distanceText(radius))
                    .accessibilityAddTraits(usesCustomRadius == false && store.selectedRadiusMeters == radius ? [.isSelected] : [])
                }
            }

            Button(AppLocalization.string("กำหนดระยะเอง")) {
                usesCustomRadius.toggle()
            }
            .buttonStyle(RadiusButtonStyle(isSelected: usesCustomRadius))

            if usesCustomRadius {
                HStack {
                    Text(AppLocalization.string("ระยะที่เลือก"))
                    Slider(value: Binding(get: { store.selectedRadiusMeters }, set: { store.selectedRadiusMeters = $0 }), in: 100...5_000, step: 100)
                        .accessibilityIdentifier("radiusSlider")
                        .accessibilityLabel(AppLocalization.string("ระยะที่เลือก"))
                        .accessibilityValue(distanceText(store.selectedRadiusMeters))
                    Text(distanceText(store.selectedRadiusMeters))
                        .foregroundStyle(AppTheme.primary)
                        .monospacedDigit()
                        .frame(minWidth: 62, alignment: .trailing)
                }
                .font(.subheadline)
                .transition(.opacity)
            }

            Button(action: startTrip) {
                HStack {
                    if store.isStartingTrip {
                        ProgressView()
                            .tint(.white)
                    }
                    Text(AppLocalization.string("เริ่มเดินทาง"))
                }
                .frame(maxWidth: .infinity)
            }
            .napNavPrimaryButtonStyle()
            .controlSize(.large)
            .disabled(store.isStartingTrip)
            .accessibilityIdentifier("startTripButton")
        }
        .padding(.horizontal, 18)
        .padding(.bottom, 14)
        .animation(.easeInOut(duration: MotionTokens.standard), value: usesCustomRadius)
    }

    private var centerPin: some View {
        ZStack {
            groundReticleView

            DestinationPinView(
                color: AppTheme.primary,
                emphasized: selection.mapPickerState == .moving
            )
            .offset(y: pinOffset)
        }
        .animation(
            MotionTokens.pinLanding(reduceMotion: reduceMotion),
            value: selection.mapPickerState
        )
        .accessibilityHidden(true)
    }

    private var groundReticleView: some View {
        ZStack {
            // Ground contact shadow
            Ellipse()
                .fill(Color.black.opacity(selection.mapPickerState == .moving ? 0.14 : 0.28))
                .frame(
                    width: selection.mapPickerState == .moving ? 22 : 14,
                    height: selection.mapPickerState == .moving ? 10 : 6
                )
                .blur(radius: selection.mapPickerState == .moving ? 2 : 0.6)

            // Precision Target Reticle (revealed while dragging/moving map)
            if selection.mapPickerState == .moving {
                // Outer subtle glow & translucent target ring
                Circle()
                    .fill(AppTheme.secondary.opacity(0.35))
                    .frame(width: 38, height: 38)

                Circle()
                    .stroke(AppTheme.primary, lineWidth: 1.5)
                    .frame(width: 38, height: 38)

                // Precision Crosshair tick marks (Top, Bottom, Left, Right)
                Group {
                    Rectangle()
                        .fill(AppTheme.primary)
                        .frame(width: 1.5, height: 5)
                        .offset(y: -16.5)

                    Rectangle()
                        .fill(AppTheme.primary)
                        .frame(width: 1.5, height: 5)
                        .offset(y: 16.5)

                    Rectangle()
                        .fill(AppTheme.primary)
                        .frame(width: 5, height: 1.5)
                        .offset(x: -16.5)

                    Rectangle()
                        .fill(AppTheme.primary)
                        .frame(width: 5, height: 1.5)
                        .offset(x: 16.5)
                }

                // Inner fine dashed guide ring
                Circle()
                    .stroke(AppTheme.primary.opacity(0.35), style: StrokeStyle(lineWidth: 1, dash: [2, 2]))
                    .frame(width: 18, height: 18)
            }

            // Center Bullseye Target Dot (Always visible at exact 0,0)
            Circle()
                .fill(.white)
                .frame(width: 8, height: 8)
                .shadow(color: .black.opacity(0.25), radius: 2, y: 1)

            Circle()
                .fill(AppTheme.primary)
                .frame(width: 4, height: 4)
        }
        .animation(.easeInOut(duration: 0.18), value: selection.mapPickerState == .moving)
    }

    private var pinOffset: CGFloat {
        guard reduceMotion == false else { return -22 }
        return selection.mapPickerState == .moving ? -48 : -22
    }

    private var isBusy: Bool {
        search.isResolving
            || selection.mapPickerState == .moving
            || selection.mapPickerState == .resolving
    }

    private var statusText: String? {
        if search.isResolving {
            return AppLocalization.string("กำลังค้นหาสถานที่…")
        }

        switch selection.mapPickerState {
        case .idle:
            return AppLocalization.string("ค้นหาสถานที่ หรือเลื่อนแผนที่เพื่อขยับหมุด")
        case .moving:
            return AppLocalization.string("กำลังเลือกตำแหน่ง…")
        case .resolving:
            return AppLocalization.string("กำลังค้นหาชื่อสถานที่…")
        case .ready:
            return AppLocalization.string("เลื่อนแผนที่ได้ หากต้องการขยับหมุด")
        case .fallback:
            return AppLocalization.string("ไม่พบชื่อสถานที่ แต่ยังใช้พิกัดนี้ได้")
        }
    }

    private func choose(_ suggestion: PlaceSearchService.Suggestion) {
        selectionTask?.cancel()
        resolvingSuggestionID = suggestion.id
        selectionTask = Task {
            defer { resolvingSuggestionID = nil }
            let destination: Destination?
            if let resolved = resolvedSuggestions[suggestion.id] {
                destination = resolved
            } else {
                destination = await search.destination(for: suggestion)
            }
            guard let destination,
                  Task.isCancelled == false else { return }
            selection.selectSearchDestination(destination)
            searchText = ""
            search.updateQuery("")
            searchIsFocused = false
            panelState = .compact
            withAnimation(.easeInOut(duration: reduceMotion ? 0.18 : MotionTokens.mapCamera)) {
                position = Self.position(for: destination)
            }
        }
    }

    private func retrySearch() {
        search.updateQuery("")
        search.updateQuery(searchText)
    }

    private func resolveSuggestionPreview(
        _ suggestion: PlaceSearchService.Suggestion,
        index: Int
    ) async {
        if index > 0 {
            try? await Task.sleep(for: .milliseconds(index * 70))
        }
        guard resolvedSuggestions[suggestion.id] == nil,
              let destination = await search.previewDestination(for: suggestion),
              Task.isCancelled == false else { return }
        resolvedSuggestions[suggestion.id] = destination
    }

    private func distanceToSuggestion(_ suggestion: PlaceSearchService.Suggestion) -> Double? {
        guard let currentCoordinate = currentLocation.coordinate,
              let destination = resolvedSuggestions[suggestion.id] else { return nil }
        return CLLocation(latitude: currentCoordinate.latitude, longitude: currentCoordinate.longitude)
            .distance(
                from: CLLocation(
                    latitude: destination.coordinate.latitude,
                    longitude: destination.coordinate.longitude
                )
            )
    }

    private func isCurrentCandidate(_ saved: SavedDestination) -> Bool {
        saved.coordinate == selection.candidate.coordinate || saved.title == selection.candidate.name
    }

    private func selectSaved(_ saved: SavedDestination) {
        store.selectSavedDestination(saved)
        selection.selectSearchDestination(saved.asDestination)
        withAnimation(.easeInOut(duration: MotionTokens.cameraFly)) {
            position = .region(
                MKCoordinateRegion(
                    center: saved.coordinate.clCoordinate,
                    latitudinalMeters: max(saved.radiusMeters * 2.5, 1_500),
                    longitudinalMeters: max(saved.radiusMeters * 2.5, 1_500)
                )
            )
        }
        withAnimation(.snappy(duration: 0.28)) {
            panelState = .compact
            searchIsFocused = false
        }
        HapticFeedback.selection()
    }

    private func confirmCandidate() {
        store.selectDestination(selection.destinationForConfirmation())
        store.useSelectedDestination()
    }

    private func recenterOnUser() {
        if store.screen == .tracking {
            withAnimation(.easeInOut(duration: MotionTokens.mapCamera)) {
                position = .userLocation(
                    followsHeading: false,
                    fallback: Self.position(for: store.destination)
                )
            }
        } else {
            currentLocation.requestFreshLocation()
            if let coordinate = currentLocation.coordinate {
                centerOnUser(coordinate)
            } else {
                withAnimation(.easeInOut(duration: MotionTokens.mapCamera)) {
                    position = .userLocation(
                        followsHeading: false,
                        fallback: Self.position(for: selection.candidate)
                    )
                }
            }
        }
        HapticFeedback.selection()
    }

    private func centerOnUser(_ coordinate: LocationCoordinate) {
        withAnimation(.easeInOut(duration: MotionTokens.mapCamera)) {
            position = .region(
                MKCoordinateRegion(
                    center: coordinate.clCoordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.025, longitudeDelta: 0.025)
                )
            )
        }
        selection.cameraDidStop(at: coordinate)
    }

    private func startTrip() {
        Task {
            await store.startTrip()
            if store.screen == .tracking {
                HapticFeedback.success()
            }
        }
    }

    fileprivate static func position(for destination: Destination) -> MapCameraPosition {
        .region(region(for: destination))
    }

    fileprivate static func region(for destination: Destination) -> MKCoordinateRegion {
        MKCoordinateRegion(
            center: destination.coordinate.clCoordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.025, longitudeDelta: 0.025)
        )
    }

    private static func radiusRegion(
        destination: CLLocationCoordinate2D,
        radiusMeters: Double
    ) -> MKCoordinateRegion {
        let latitudeDelta = max(radiusMeters * 2.6 / 111_000, 0.012)
        let longitudeScale = max(cos(destination.latitude * .pi / 180), 0.2)
        let longitudeDelta = max(latitudeDelta / longitudeScale, 0.012)
        return MKCoordinateRegion(
            center: destination,
            span: MKCoordinateSpan(
                latitudeDelta: latitudeDelta,
                longitudeDelta: longitudeDelta
            )
        )
    }
}

extension LocationCoordinate {
    var clCoordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

private extension CLLocationCoordinate2D {
    var locationCoordinate: LocationCoordinate {
        LocationCoordinate(latitude: latitude, longitude: longitude)
    }
}


// MARK: - Apple-Style Swipeable Place Row

struct SwipeActionItem {
    let title: String
    let systemImage: String
    let tint: Color
    let action: () -> Void
}

struct HorizontalPanGesture: UIGestureRecognizerRepresentable {
    var onChanged: (CGFloat) -> Void
    var onEnded: (CGFloat) -> Void

    func makeUIGestureRecognizer(context: Context) -> UIPanGestureRecognizer {
        let pan = UIPanGestureRecognizer()
        pan.delegate = context.coordinator
        pan.cancelsTouchesInView = false
        return pan
    }

    func updateUIGestureRecognizer(_ recognizer: UIPanGestureRecognizer, context: Context) {}

    func handleUIGestureRecognizerAction(_ recognizer: UIPanGestureRecognizer, context: Context) {
        guard let view = recognizer.view else { return }
        let translation = recognizer.translation(in: view).x
        switch recognizer.state {
        case .began, .changed:
            onChanged(translation)
        case .ended, .cancelled:
            onEnded(translation)
        default:
            break
        }
    }

    func makeCoordinator(converter: CoordinateSpaceConverter) -> Coordinator {
        Coordinator()
    }

    final class Coordinator: NSObject, UIGestureRecognizerDelegate {
        func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
            guard let pan = gestureRecognizer as? UIPanGestureRecognizer,
                  let view = pan.view else { return false }
            let velocity = pan.velocity(in: view)
            return abs(velocity.x) > abs(velocity.y) * 1.25 && abs(velocity.x) > 20
        }
    }
}

struct AppleSwipeRow<Content: View>: View {
    let leadingAction: SwipeActionItem?
    let trailingAction: SwipeActionItem?
    @ViewBuilder let content: Content

    @State private var offset: CGFloat = 0
    @State private var dragOffset: CGFloat = 0
    @State private var isDragging = false

    private let actionWidth: CGFloat = 68
    private let spacing: CGFloat = 8
    private let triggerDistance: CGFloat = 135

    init(
        leadingAction: SwipeActionItem? = nil,
        trailingAction: SwipeActionItem? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.leadingAction = leadingAction
        self.trailingAction = trailingAction
        self.content = content()
    }

    private var currentTotalOffset: CGFloat {
        offset + dragOffset
    }

    private var effectiveOffset: CGFloat {
        let raw = currentTotalOffset
        let maxTravel = actionWidth + spacing
        if raw < 0 {
            guard trailingAction != nil else { return 0 }
            if raw < -maxTravel {
                let excess = raw + maxTravel
                return -maxTravel + excess * 0.35
            }
            return raw
        } else if raw > 0 {
            guard leadingAction != nil else { return 0 }
            if raw > maxTravel {
                let excess = raw - maxTravel
                return maxTravel + excess * 0.35
            }
            return raw
        }
        return 0
    }

    private var isLeadingTriggered: Bool {
        currentTotalOffset > triggerDistance
    }

    private var isTrailingTriggered: Bool {
        currentTotalOffset < -triggerDistance
    }

    var body: some View {
        content
            .frame(maxWidth: .infinity)
            .overlay {
                if offset != 0 {
                    Color.clear
                        .contentShape(.rect)
                        .onTapGesture {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.82)) {
                                offset = 0
                                dragOffset = 0
                            }
                        }
                }
            }
            .overlay(alignment: .trailing) {
                if let trailingAction {
                    actionButtonView(
                        item: trailingAction,
                        isTriggered: isTrailingTriggered
                    )
                    .offset(x: actionWidth + spacing)
                    .opacity(effectiveOffset < 0 ? min(1.0, abs(effectiveOffset) / 20.0) : 0)
                    .allowsHitTesting(effectiveOffset < -10)
                }
            }
            .overlay(alignment: .leading) {
                if let leadingAction {
                    actionButtonView(
                        item: leadingAction,
                        isTriggered: isLeadingTriggered
                    )
                    .offset(x: -(actionWidth + spacing))
                    .opacity(effectiveOffset > 0 ? min(1.0, abs(effectiveOffset) / 20.0) : 0)
                    .allowsHitTesting(effectiveOffset > 10)
                }
            }
            .offset(x: effectiveOffset)
            .gesture(
                HorizontalPanGesture(
                    onChanged: { translationX in
                        isDragging = true
                        dragOffset = translationX
                    },
                    onEnded: { translationX in
                        defer {
                            isDragging = false
                            dragOffset = 0
                        }

                        let finalRaw = offset + translationX
                        let snapDistance = actionWidth + spacing

                        if finalRaw < -triggerDistance, let trailing = trailingAction {
                            withAnimation(.spring(response: 0.32, dampingFraction: 0.8)) {
                                offset = 0
                            }
                            trailing.action()
                        } else if finalRaw < -36 && trailingAction != nil {
                            withAnimation(.spring(response: 0.32, dampingFraction: 0.8)) {
                                offset = -snapDistance
                            }
                            HapticFeedback.selection()
                        } else if finalRaw > triggerDistance, let leading = leadingAction {
                            withAnimation(.spring(response: 0.32, dampingFraction: 0.8)) {
                                offset = 0
                            }
                            leading.action()
                        } else if finalRaw > 36 && leadingAction != nil {
                            withAnimation(.spring(response: 0.32, dampingFraction: 0.8)) {
                                offset = snapDistance
                            }
                            HapticFeedback.selection()
                        } else {
                            withAnimation(.spring(response: 0.32, dampingFraction: 0.8)) {
                                offset = 0
                            }
                        }
                    }
                )
            )
    }

    private func actionButtonView(item: SwipeActionItem, isTriggered: Bool) -> some View {
        Button {
            withAnimation(.spring(response: 0.32, dampingFraction: 0.8)) {
                offset = 0
                dragOffset = 0
            }
            item.action()
        } label: {
            VStack(spacing: 3) {
                ZStack {
                    RoundedRectangle(cornerRadius: 13, style: .continuous)
                        .fill(item.tint)
                        .frame(width: 44, height: 44)
                        .shadow(color: item.tint.opacity(0.35), radius: 3, y: 1.5)

                    Image(systemName: item.systemImage)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(.white)
                }

                Text(item.title)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            .frame(width: actionWidth)
            .contentShape(.rect)
            .scaleEffect(isTriggered ? 1.08 : 1.0)
        }
        .buttonStyle(.plain)
    }
}


struct SaveFavoriteSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var title: String
    @State private var showingDeleteConfirmation = false
    let subtitle: String
    let coordinate: LocationCoordinate
    @State private var radius: Double
    @State private var selectedIcon: SavedDestinationIcon
    let isEditing: Bool
    let onSave: (String, SavedDestinationIcon, Double) -> Void
    let onDelete: (() -> Void)?
    let onCancel: () -> Void

    init(
        initialTitle: String,
        subtitle: String,
        coordinate: LocationCoordinate,
        initialRadius: Double,
        initialIcon: SavedDestinationIcon = .star,
        isEditing: Bool = false,
        onSave: @escaping (String, SavedDestinationIcon, Double) -> Void,
        onDelete: (() -> Void)? = nil,
        onCancel: @escaping () -> Void
    ) {
        _title = State(initialValue: initialTitle)
        self.subtitle = subtitle
        self.coordinate = coordinate
        _radius = State(initialValue: initialRadius)
        _selectedIcon = State(initialValue: initialIcon)
        self.isEditing = isEditing
        self.onSave = onSave
        self.onDelete = onDelete
        self.onCancel = onCancel
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField(AppLocalization.string("ชื่อสถานที่"), text: $title)
                        .font(.body)

                    if subtitle.isEmpty == false {
                        Text(subtitle)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text(AppLocalization.string("ชื่อสถานที่"))
                }

                Section {
                    HStack(spacing: 12) {
                        ForEach(SavedDestinationIcon.allCases) { icon in
                            Button {
                                selectedIcon = icon
                                HapticFeedback.selection()
                            } label: {
                                VStack(spacing: 6) {
                                    Image(systemName: icon.rawValue)
                                        .font(.title3)
                                        .frame(width: 44, height: 44)
                                        .background(
                                            Circle()
                                                .fill(selectedIcon == icon ? Color.accentColor : Color.secondary.opacity(0.12))
                                        )
                                        .foregroundStyle(selectedIcon == icon ? Color.white : Color.primary)
                                    Text(icon.title)
                                        .font(.caption2)
                                        .foregroundStyle(selectedIcon == icon ? Color.accentColor : Color.secondary)
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.8)
                                }
                            }
                            .buttonStyle(.plain)
                            .frame(maxWidth: .infinity)
                        }
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text(AppLocalization.string("ไอคอน"))
                }

                Section {
                    Picker(AppLocalization.string("ระยะเตือนเริ่มต้น"), selection: $radius) {
                        Text(distanceText(500.0)).tag(500.0)
                        Text(distanceText(1_000.0)).tag(1_000.0)
                        Text(distanceText(2_000.0)).tag(2_000.0)
                    }
                    .pickerStyle(.segmented)
                } header: {
                    Text(AppLocalization.string("ระยะเตือนเริ่มต้น"))
                }

                if onDelete != nil {
                    Section {
                        Button(role: .destructive) {
                            showingDeleteConfirmation = true
                        } label: {
                            HStack {
                                Spacer()
                                Label(AppLocalization.string("ลบออกจากสถานที่โปรด"), systemImage: "trash")
                                Spacer()
                            }
                        }
                    }
                }
            }
            .navigationTitle(isEditing ? AppLocalization.string("แก้ไขสถานที่โปรด") : AppLocalization.string("บันทึกสถานที่โปรด"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(AppLocalization.string("ยกเลิก")) {
                        onCancel()
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(AppLocalization.string("บันทึก")) {
                        let finalTitle = title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                            ? AppLocalization.string("สถานที่โปรด")
                            : title.trimmingCharacters(in: .whitespacesAndNewlines)
                        onSave(finalTitle, selectedIcon, radius)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.medium])
        .confirmationDialog(
            AppLocalization.string("ลบสถานที่โปรดนี้หรือไม่?"),
            isPresented: $showingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button(AppLocalization.string("ลบสถานที่โปรด"), role: .destructive) {
                onDelete?()
                dismiss()
            }
            Button(AppLocalization.string("ยกเลิก"), role: .cancel) { }
        } message: {
            Text(AppLocalization.format("คุณแน่ใจหรือไม่ว่าต้องการลบ \"%@\" ออกจากรายการโปรด?", title.isEmpty ? AppLocalization.string("สถานที่โปรด") : title))
        }
    }
}
