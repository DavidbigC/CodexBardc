import SwiftUI

struct HUDRootView: View {
    let store: UsageStore
    let settings: SettingsStore
    let mode: HUDDisplayMode
    let onToggleTucked: () -> Void
    let onRefresh: () -> Void

    var body: some View {
        let state = HUDViewModel(store: self.store, settings: self.settings, mode: self.mode).state
        Group {
            if state.mode == .tucked {
                HUDTuckedView(state: state, onToggleTucked: self.onToggleTucked)
            } else {
                ScrollView(.vertical, showsIndicators: true) {
                    HUDCompactCard(state: state, onToggleTucked: self.onToggleTucked, onRefresh: self.onRefresh)
                }
                .scrollIndicators(.automatic)
            }
        }
    }
}

private struct HUDCompactCard: View {
    let state: HUDViewState
    let onToggleTucked: () -> Void
    let onRefresh: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Circle()
                    .fill(self.palette.liveDot)
                    .frame(width: 7, height: 7)

                Text(self.state.titleText)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(self.palette.secondaryText)

                Spacer()

                HUDIconButton(
                    systemImage: "arrow.clockwise",
                    palette: self.palette,
                    disabled: self.state.isRefreshing,
                    action: self.onRefresh)
                    .overlay {
                        if self.state.isRefreshing {
                            ProgressView()
                                .controlSize(.small)
                                .tint(self.palette.secondaryText)
                        }
                    }

                HUDIconButton(
                    systemImage: "pin.slash",
                    palette: self.palette,
                    action: self.onToggleTucked)
            }

            ForEach(self.state.providers) { provider in
                HUDProviderRow(provider: provider, accent: self.state.accent, palette: self.palette)
            }

            Divider()
                .overlay(self.palette.divider)

            HStack(spacing: 8) {
                Text(self.state.lastUpdatedText)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(self.palette.secondaryText)
                    .lineLimit(1)

                Spacer(minLength: 8)

                Text(self.state.refreshText)
                    .font(.system(size: 10, weight: .regular))
                    .foregroundStyle(self.palette.tertiaryText)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .frame(minHeight: 214, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(self.palette.background))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(self.palette.border, lineWidth: 1))
        .shadow(color: self.palette.shadow, radius: 14, y: 6)
    }

    private var palette: HUDPalette {
        HUDPalette(style: self.state.style, opacity: self.state.opacity)
    }
}

private struct HUDProviderRow: View {
    let provider: HUDProviderSummary
    let accent: HUDAppearanceAccent
    let palette: HUDPalette

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Circle()
                        .fill(self.primaryColor)
                        .frame(width: 7, height: 7)

                    Text(self.provider.title)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(self.palette.primaryText)

                    Text(self.provider.sourceLabel.uppercased())
                        .font(.system(size: 9, weight: .semibold))
                        .tracking(0.5)
                        .foregroundStyle(self.palette.tertiaryText)
                }

                Text(self.provider.primaryDetailText)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(self.palette.primaryText)

                if let secondaryDetailText = self.secondaryLabelText {
                    Text(secondaryDetailText)
                        .font(.system(size: 10, weight: .regular))
                        .foregroundStyle(self.palette.tertiaryText)
                }

                Text(self.provider.secondaryText)
                    .font(.system(size: 10, weight: .regular))
                    .foregroundStyle(self.palette.secondaryText)
                    .lineLimit(1)
            }

            Spacer(minLength: 4)

            self.meterStack
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(self.palette.rowBackground))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(self.palette.rowBorder, lineWidth: 1))
    }

    @ViewBuilder
    private var meterStack: some View {
        if self.provider.provider == .codex, let secondaryValue = self.provider.secondaryValue {
            HUDNestedCircularMeter(
                outerLabel: "S",
                outerValue: self.provider.primaryValue,
                outerValueText: self.provider.primaryValueText ?? "--",
                outerTint: self.primaryColor,
                innerLabel: "W",
                innerValue: secondaryValue,
                innerValueText: self.provider.secondaryValueText ?? "--",
                innerTint: self.secondaryColor,
                track: self.palette.track,
                textColor: self.palette.primaryText)
        } else {
            HUDCircularMeter(
                label: nil,
                value: self.provider.primaryValue,
                valueText: self.provider.primaryValueText ?? "--",
                tint: self.primaryColor,
                track: self.palette.track,
                textColor: self.palette.primaryText,
                lineWidth: 6,
                diameter: 46)
        }
    }

    private var secondaryLabelText: String? {
        guard let secondaryDetailText = self.provider.secondaryDetailText else { return nil }
        if self.provider.provider == .codex {
            return "\(secondaryDetailText) inside"
        }
        return secondaryDetailText
    }

    private var primaryColor: Color {
        if self.accent != .system {
            return self.accent.color
        }
        switch self.provider.tint {
        case .codex:
            return Color(red: 0.17, green: 0.73, blue: 0.46)
        case .claude:
            return Color(red: 0.90, green: 0.50, blue: 0.28)
        }
    }

    private var secondaryColor: Color {
        switch self.provider.tint {
        case .codex:
            Color(red: 0.30, green: 0.56, blue: 0.90)
        case .claude:
            self.primaryColor.opacity(0.72)
        }
    }
}

private struct HUDCircularMeter: View {
    let label: String?
    let value: Double?
    let valueText: String
    let tint: Color
    let track: Color
    let textColor: Color
    let lineWidth: CGFloat
    let diameter: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .stroke(self.track, lineWidth: self.lineWidth)

            Circle()
                .trim(from: 0, to: self.progress)
                .stroke(self.tint, style: StrokeStyle(lineWidth: self.lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))

            VStack(spacing: 1) {
                Text(self.valueText)
                    .font(.system(size: self.diameter > 40 ? 11 : 9, weight: .semibold))
                    .foregroundStyle(self.textColor)

                if let label {
                    Text(label)
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(self.textColor.opacity(0.7))
                }
            }
        }
        .frame(width: self.diameter, height: self.diameter)
    }

    private var progress: CGFloat {
        guard let value else { return 0.04 }
        return max(0.04, min(1.0, CGFloat(value / 100)))
    }
}

private struct HUDNestedCircularMeter: View {
    let outerLabel: String
    let outerValue: Double?
    let outerValueText: String
    let outerTint: Color
    let innerLabel: String
    let innerValue: Double?
    let innerValueText: String
    let innerTint: Color
    let track: Color
    let textColor: Color

    var body: some View {
        ZStack {
            Circle()
                .stroke(self.track, lineWidth: 6)
                .frame(width: 56, height: 56)

            Circle()
                .trim(from: 0, to: self.progress(for: self.outerValue))
                .stroke(self.outerTint, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .frame(width: 56, height: 56)

            Circle()
                .stroke(self.track, lineWidth: 5)
                .frame(width: 34, height: 34)

            Circle()
                .trim(from: 0, to: self.progress(for: self.innerValue))
                .stroke(self.innerTint, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .frame(width: 34, height: 34)

            VStack(spacing: 1) {
                Text(self.outerValueText)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(self.textColor)

                Text(self.innerLabel)
                    .font(.system(size: 7, weight: .bold))
                    .foregroundStyle(self.textColor.opacity(0.65))
            }

            VStack {
                HStack {
                    Spacer()
                    Text(self.outerLabel)
                        .font(.system(size: 7, weight: .bold))
                        .foregroundStyle(self.textColor.opacity(0.55))
                }
                Spacer()
            }
            .frame(width: 62, height: 62)
        }
        .frame(width: 66, height: 66)
    }

    private func progress(for value: Double?) -> CGFloat {
        guard let value else { return 0.04 }
        return max(0.04, min(1.0, CGFloat(value / 100)))
    }
}

private struct HUDIconButton: View {
    let systemImage: String
    let palette: HUDPalette
    var disabled = false
    let action: () -> Void

    var body: some View {
        Button(action: self.action) {
            Image(systemName: self.systemImage)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(self.disabled ? self.palette.tertiaryText : self.palette.secondaryText)
                .frame(width: 24, height: 24)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(self.palette.controlBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(self.palette.controlBorder, lineWidth: 1))
        }
        .buttonStyle(.plain)
        .disabled(self.disabled)
    }
}

private struct HUDTuckedView: View {
    let state: HUDViewState
    let onToggleTucked: () -> Void

    var body: some View {
        HStack(spacing: 7) {
            ForEach(self.state.providers) { provider in
                Circle()
                    .fill(self.providerColor(for: provider))
                    .frame(width: 8, height: 8)
            }

            Spacer(minLength: 0)

            Button("Show", action: self.onToggleTucked)
                .buttonStyle(.plain)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(self.palette.secondaryText)
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            Capsule(style: .continuous)
                .fill(self.palette.background))
        .overlay(
            Capsule(style: .continuous)
                .stroke(self.palette.border, lineWidth: 1))
        .shadow(color: self.palette.shadow, radius: 8, y: 4)
    }

    private var palette: HUDPalette {
        HUDPalette(style: self.state.style, opacity: self.state.opacity)
    }

    private func providerColor(for provider: HUDProviderSummary) -> Color {
        switch provider.tint {
        case .codex:
            Color(red: 0.17, green: 0.73, blue: 0.46)
        case .claude:
            Color(red: 0.90, green: 0.50, blue: 0.28)
        }
    }
}

private struct HUDPalette {
    let background: Color
    let rowBackground: Color
    let controlBackground: Color
    let border: Color
    let rowBorder: Color
    let controlBorder: Color
    let divider: Color
    let track: Color
    let primaryText: Color
    let secondaryText: Color
    let tertiaryText: Color
    let liveDot: Color
    let shadow: Color

    init(style: HUDAppearanceStyle, opacity: Double) {
        let alpha = max(0.62, min(1.0, opacity))
        switch style {
        case .light:
            self.background = Color(red: 0.98, green: 0.97, blue: 0.95).opacity(alpha)
            self.rowBackground = Color.white.opacity(min(1.0, alpha + 0.02))
            self.controlBackground = Color.white.opacity(0.9)
            self.border = Color.black.opacity(0.08)
            self.rowBorder = Color.black.opacity(0.06)
            self.controlBorder = Color.black.opacity(0.08)
            self.divider = Color.black.opacity(0.07)
            self.track = Color.black.opacity(0.10)
            self.primaryText = Color.black.opacity(0.88)
            self.secondaryText = Color.black.opacity(0.62)
            self.tertiaryText = Color.black.opacity(0.42)
            self.liveDot = Color(red: 0.22, green: 0.71, blue: 0.45)
            self.shadow = Color.black.opacity(0.12)
        case .dark:
            self.background = Color(red: 0.12, green: 0.13, blue: 0.15).opacity(alpha)
            self.rowBackground = Color.white.opacity(0.05)
            self.controlBackground = Color.white.opacity(0.06)
            self.border = Color.white.opacity(0.08)
            self.rowBorder = Color.white.opacity(0.07)
            self.controlBorder = Color.white.opacity(0.09)
            self.divider = Color.white.opacity(0.08)
            self.track = Color.white.opacity(0.12)
            self.primaryText = Color.white.opacity(0.92)
            self.secondaryText = Color.white.opacity(0.72)
            self.tertiaryText = Color.white.opacity(0.48)
            self.liveDot = Color(red: 0.22, green: 0.78, blue: 0.50)
            self.shadow = Color.black.opacity(0.28)
        }
    }
}
