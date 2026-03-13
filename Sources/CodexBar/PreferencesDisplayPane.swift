import SwiftUI

@MainActor
struct DisplayPane: View {
    @Bindable var settings: SettingsStore

    var body: some View {
        ScrollView(.vertical, showsIndicators: true) {
            VStack(alignment: .leading, spacing: 16) {
                SettingsSection(contentSpacing: 12) {
                    Text("HUD")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)
                    HStack(alignment: .top, spacing: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Style")
                                .font(.body)
                            Text("Choose a light or dark HUD surface.")
                                .font(.footnote)
                                .foregroundStyle(.tertiary)
                        }
                        Spacer()
                        Picker("Style", selection: self.$settings.hudAppearanceStyle) {
                            ForEach(HUDAppearanceStyle.allCases) { style in
                                Text(style.label).tag(style)
                            }
                        }
                        .labelsHidden()
                        .pickerStyle(.menu)
                        .frame(maxWidth: 180)
                    }
                    HStack(alignment: .top, spacing: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Accent")
                                .font(.body)
                            Text("Tint the progress bars and highlights.")
                                .font(.footnote)
                                .foregroundStyle(.tertiary)
                        }
                        Spacer()
                        Picker("Accent", selection: self.$settings.hudAccent) {
                            ForEach(HUDAppearanceAccent.allCases) { accent in
                                Text(accent.label).tag(accent)
                            }
                        }
                        .labelsHidden()
                        .pickerStyle(.menu)
                        .frame(maxWidth: 180)
                    }
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Opacity")
                                .font(.body)
                            Spacer()
                            Text("\(Int((self.settings.hudOpacity * 100).rounded()))%")
                                .font(.footnote)
                                .foregroundStyle(.tertiary)
                        }
                        Slider(value: self.$settings.hudOpacity, in: 0.45...1.0)
                    }
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Scale")
                                .font(.body)
                            Spacer()
                            Text(String(format: "%.2fx", self.settings.hudScale))
                                .font(.footnote)
                                .foregroundStyle(.tertiary)
                        }
                        Slider(value: self.$settings.hudScale, in: 0.85...1.35)
                    }
                    PreferenceToggleRow(
                        title: "Show usage as used",
                        subtitle: "Progress bars fill as you consume quota instead of showing remaining quota.",
                        binding: self.$settings.usageBarsShowUsed)
                    PreferenceToggleRow(
                        title: "Show reset time as clock",
                        subtitle: "Display reset times as absolute clock values instead of countdowns.",
                        binding: self.$settings.resetTimesShowAbsolute)
                }

                Divider()

                SettingsSection(contentSpacing: 12) {
                    Text("Expanded Details")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)
                    PreferenceToggleRow(
                        title: "Show credits + extra usage",
                        subtitle: "Show optional credits and extra-usage details when the active CLI source"
                            + " exposes them.",
                        binding: self.$settings.showOptionalCreditsAndExtraUsage)
                    PreferenceToggleRow(
                        title: "Track historical usage",
                        subtitle: "Store local Codex usage history to improve pace estimates over time.",
                        binding: self.$settings.historicalTrackingEnabled)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
        }
    }
}
