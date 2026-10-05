enum OnboardingMode: Equatable, Sendable {
    case firstRun
    case replay

    var requiresCompletion: Bool { self == .firstRun }
    var requestsPermissionsOnContinue: Bool { self == .firstRun }

    func requestsPermissions(on page: OnboardingPage) -> Bool {
        requestsPermissionsOnContinue && page == .permissions
    }
}

enum OnboardingPage: Int, CaseIterable, Identifiable {
    case destination
    case alertMethod
    case permissions

    var id: Self { self }

    var next: Self? {
        switch self {
        case .destination: .alertMethod
        case .alertMethod: .permissions
        case .permissions: nil
        }
    }

    var previous: Self? {
        switch self {
        case .destination: nil
        case .alertMethod: .destination
        case .permissions: .alertMethod
        }
    }
}

struct TutorialHandoff {
    private var pendingMode: OnboardingMode?

    mutating func request(_ mode: OnboardingMode) {
        pendingMode = mode
    }

    mutating func consumeAfterDismissal() -> OnboardingMode? {
        defer { pendingMode = nil }
        return pendingMode
    }
}
