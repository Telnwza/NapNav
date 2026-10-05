import SwiftUI
import UIKit

enum MotionTokens {
    static let quick = 0.14
    static let standard = 0.28
    static let mapCamera = 0.45
    static let cameraFly = 0.65

    static func standardAnimation(reduceMotion: Bool) -> Animation? {
        reduceMotion ? nil : .easeInOut(duration: standard)
    }

    static func pinLanding(reduceMotion: Bool) -> Animation? {
        reduceMotion ? nil : .spring(duration: standard, bounce: 0.18)
    }

    static func morphSpring(reduceMotion: Bool) -> Animation? {
        reduceMotion ? nil : .spring(response: 0.48, dampingFraction: 0.78)
    }

    static func cameraAnimation(reduceMotion: Bool, fly: Bool = false) -> Animation? {
        reduceMotion ? nil : .easeInOut(duration: fly ? cameraFly : mapCamera)
    }

    static func panelAnimation(reduceMotion: Bool) -> Animation? {
        reduceMotion ? nil : .snappy(duration: standard)
    }

    static func swipeAnimation(reduceMotion: Bool, response: Double = 0.32, dampingFraction: Double = 0.8) -> Animation? {
        reduceMotion ? nil : .spring(response: response, dampingFraction: dampingFraction)
    }

    static func startupExit(reduceMotion: Bool) -> Animation {
        reduceMotion ? .easeOut(duration: 0.20) : .spring(response: 0.44, dampingFraction: 0.88)
    }
}

struct CalmPressButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.98 : 1)
            .opacity(configuration.isPressed ? 0.86 : 1)
            .animation(.easeOut(duration: MotionTokens.quick), value: configuration.isPressed)
    }
}

@MainActor
enum HapticFeedback {
    static func selection() {
        UISelectionFeedbackGenerator().selectionChanged()
    }

    static func success() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    static func warning() {
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
    }
}
