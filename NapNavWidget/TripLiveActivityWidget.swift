import ActivityKit
import SwiftUI
import WidgetKit

public struct TripLiveActivityWidget: Widget {
    public init() {}

    public var body: some WidgetConfiguration {
        ActivityConfiguration(for: TripActivityAttributes.self) { context in
            // MARK: - Lock Screen Banner View
            TripLockScreenBannerView(
                attributes: context.attributes,
                state: context.state
            )
            .environment(\.locale, context.attributes.locale)
            .widgetURL(URL(string: "napnav://trip"))
        } dynamicIsland: { context in
            let language = context.state.resolvedLanguage(fallback: context.attributes.languageCode)
            let languageCode = language.resolvedIdentifier

            return DynamicIsland {
                // MARK: - Expanded Dynamic Island
                // Leading: Status pill + Destination name (2 lines)
                DynamicIslandExpandedRegion(.leading) {
                    VStack(alignment: .leading, spacing: 3) {
                        HStack(spacing: 4) {
                            Image(systemName: context.state.statusIconName)
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(statusColor(context.state))
                            Text(context.state.statusTitle(for: language))
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(statusColor(context.state))
                        }

                        Text(context.attributes.destinationName)
                            .font(.subheadline.weight(.semibold))
                            .lineLimit(2)
                            .foregroundStyle(.primary)
                    }
                    .padding(.leading, 4)
                    .environment(\.locale, language.locale)
                }

                // Trailing: Remaining distance OR Arrival / Timer
                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing, spacing: 2) {
                        if context.state.isArrived {
                            if let autoStopAt = context.state.autoStopAt, autoStopAt > Date() {
                                Text(timerInterval: Date()...autoStopAt, countsDown: true)
                                    .monospacedDigit()
                                    .font(.system(size: 18, weight: .bold, design: .rounded))
                                    .foregroundStyle(.green)
                                    .lineLimit(1)
                            } else {
                                Text(AppLocalization.string("ถึงแล้ว", language: language))
                                    .font(.system(size: 18, weight: .bold, design: .rounded))
                                    .foregroundStyle(.green)
                                    .lineLimit(1)
                            }
                        } else {
                            Text(context.state.formattedRemainingDistance(languageCode: languageCode))
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                .foregroundStyle(statusColor(context.state))
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                        }
                    }
                    .padding(.trailing, 4)
                    .environment(\.locale, language.locale)
                }

                // Bottom: Progress bar + Footer info / Countdown & Action button
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(spacing: 8) {
                        ProgressView(value: context.state.progressFraction)
                            .tint(statusColor(context.state))

                        HStack {
                            if context.state.isArrived {
                                if let autoStopAt = context.state.autoStopAt, autoStopAt > Date() {
                                    HStack(spacing: 4) {
                                        Image(systemName: "timer")
                                        Text(AppLocalization.string("หยุดใน", language: language))
                                        Text(timerInterval: Date()...autoStopAt, countsDown: true)
                                            .monospacedDigit()
                                    }
                                    .font(.caption2.weight(.medium))
                                    .foregroundStyle(.secondary)
                                } else {
                                    Text(AppLocalization.string("ถึงที่หมายเรียบร้อย", language: language))
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                            } else {
                                Label {
                                    Text(AppLocalization.format(
                                        "แจ้งเตือนที่ %@",
                                        context.state.formattedAlertRadius(languageCode: languageCode),
                                        language: language
                                    ))
                                } icon: {
                                    Image(systemName: "bell.fill")
                                }
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            }

                            Spacer()

                            Link(destination: URL(string: "napnav://stop-trip")!) {
                                HStack(spacing: 4) {
                                    Image(systemName: context.state.isArrived ? "checkmark.circle.fill" : "xmark.circle.fill")
                                    Text(
                                        AppLocalization.string(
                                            context.state.isArrived ? "เสร็จสิ้น" : "หยุดทริป",
                                            language: language
                                        )
                                    )
                                }
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(context.state.isArrived ? .green : .red)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background((context.state.isArrived ? Color.green : Color.red).opacity(0.18), in: Capsule())
                            }
                        }
                    }
                    .padding(.horizontal, 4)
                    .padding(.top, 4)
                    .environment(\.locale, language.locale)
                }
            } compactLeading: {
                Image(systemName: context.state.statusIconName)
                    .foregroundStyle(statusColor(context.state))
            } compactTrailing: {
                let language = context.state.resolvedLanguage(fallback: context.attributes.languageCode)
                let languageCode = language.resolvedIdentifier

                Group {
                    if context.state.isArrived {
                        if let autoStopAt = context.state.autoStopAt, autoStopAt > Date() {
                            Text(timerInterval: Date()...autoStopAt, countsDown: true)
                                .monospacedDigit()
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(.green)
                        } else {
                            Text(AppLocalization.string("ถึงแล้ว", language: language))
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(.green)
                        }
                    } else {
                        Text(context.state.formattedRemainingDistance(languageCode: languageCode))
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .minimumScaleFactor(0.8)
                            .foregroundStyle(statusColor(context.state))
                    }
                }
                .environment(\.locale, language.locale)
            } minimal: {
                Image(systemName: context.state.statusIconName)
                    .foregroundStyle(statusColor(context.state))
            }
            .widgetURL(URL(string: "napnav://trip"))
        }
    }

    private func statusColor(_ state: TripActivityAttributes.ContentState) -> Color {
        if state.isArrived {
            return .green
        } else if state.isAlertTriggered || state.remainingDistanceMeters <= state.alertRadiusMeters {
            return .orange
        } else {
            return AppTheme.primary
        }
    }
}

// MARK: - Lock Screen Banner View
struct TripLockScreenBannerView: View {
    let attributes: TripActivityAttributes
    let state: TripActivityAttributes.ContentState

    var body: some View {
        let language = state.resolvedLanguage(fallback: attributes.languageCode)
        let languageCode = language.resolvedIdentifier

        VStack(spacing: 12) {
            // Header Row: Status + Destination Name (2 lines) on Left | Remaining Distance or "ถึงจุดหมายแล้ว" on Right
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 5) {
                        Image(systemName: state.statusIconName)
                            .font(.caption.weight(.bold))
                            .foregroundStyle(statusColor)

                        Text(state.statusTitle(for: language))
                            .font(.caption.weight(.bold))
                            .foregroundStyle(statusColor)
                    }

                    Text(attributes.destinationName)
                        .font(.headline.weight(.semibold))
                        .lineLimit(2)
                        .foregroundStyle(.primary)
                }

                Spacer(minLength: 12)

                if state.isArrived {
                    Text(AppLocalization.string("ถึงจุดหมายแล้ว", language: language))
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(.green)
                        .multilineTextAlignment(.trailing)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                } else {
                    Text(state.formattedRemainingDistance(languageCode: languageCode))
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundStyle(statusColor)
                        .lineLimit(1)
                }
            }

            // Middle: Clean Native Progress Bar
            ProgressView(value: state.progressFraction)
                .tint(statusColor)

            // Footer Row: Small Alert Distance / Auto-Stop Countdown + Action Button
            HStack {
                if state.isArrived {
                    if let autoStopAt = state.autoStopAt, autoStopAt > Date() {
                        HStack(spacing: 4) {
                            Image(systemName: "timer")
                            Text(AppLocalization.string("หยุดใน", language: language))
                            Text(timerInterval: Date()...autoStopAt, countsDown: true)
                                .monospacedDigit()
                        }
                        .font(.footnote.weight(.medium))
                        .foregroundStyle(.secondary)
                    } else {
                        Text(AppLocalization.string("ถึงที่หมายเรียบร้อย", language: language))
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    Label {
                        Text(AppLocalization.format(
                            "แจ้งเตือนที่ %@",
                            state.formattedAlertRadius(languageCode: languageCode),
                            language: language
                        ))
                    } icon: {
                        Image(systemName: "bell.fill")
                    }
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                }

                Spacer()

                Link(destination: URL(string: "napnav://stop-trip")!) {
                    HStack(spacing: 5) {
                        Image(systemName: state.isArrived ? "checkmark.circle.fill" : "xmark.circle.fill")
                        Text(
                            AppLocalization.string(
                                state.isArrived ? "เสร็จสิ้น" : "หยุดทริป",
                                language: language
                            )
                        )
                    }
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(state.isArrived ? .green : .red)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background((state.isArrived ? Color.green : Color.red).opacity(0.12), in: Capsule())
                }
            }
        }
        .padding(16)
        .environment(\.locale, language.locale)
    }

    private var statusColor: Color {
        if state.isArrived {
            return .green
        } else if state.isAlertTriggered || state.remainingDistanceMeters <= state.alertRadiusMeters {
            return .orange
        } else {
            return AppTheme.primary
        }
    }
}
