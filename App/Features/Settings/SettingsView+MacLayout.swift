import AnyTimeCore
import SwiftUI

extension SettingsView {
    static let macRowHeight: CGFloat = 54

    var macOSBody: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                macSection("Display") {
                    VStack(spacing: 0) {
                        macSettingsRow(
                            title: "Primary label",
                            systemImage: "textformat.alt",
                            tint: AppTheme.actionBlue
                        ) {
                            Picker("Primary label", selection: $store.labelStyle) {
                                ForEach(ClockLabelStyle.allCases) { style in
                                    Text(style.title).tag(style)
                                }
                            }
                            .pickerStyle(.menu)
                            .labelsHidden()
                            .frame(width: 220, alignment: .trailing)
                        }

                        Divider()

                        macSettingsRow(
                            title: "Clock format",
                            systemImage: "clock.arrow.trianglehead.counterclockwise.rotate.90",
                            tint: AppTheme.accent
                        ) {
                            Picker("Clock format", selection: $store.dateStyle) {
                                ForEach(ClockDateStyle.allCases) { style in
                                    Text(style.title).tag(style)
                                }
                            }
                            .pickerStyle(.menu)
                            .labelsHidden()
                            .frame(width: 220, alignment: .trailing)
                        }

                        Divider()

                        macSettingsRow(
                            title: "Hour format",
                            systemImage: "clock",
                            tint: AppTheme.warm
                        ) {
                            Picker("Hour format", selection: $store.hourFormat) {
                                ForEach(ClockHourFormat.allCases) { format in
                                    Text(format.title).tag(format)
                                }
                            }
                            .pickerStyle(.menu)
                            .labelsHidden()
                            .frame(width: 220, alignment: .trailing)
                        }

                        Divider()

                        macSettingsRow(
                            title: "Preview",
                            systemImage: "eye",
                            tint: AppTheme.magic
                        ) {
                            Text(
                                store.dateStyle.formatted(
                                    date: store.referenceDate,
                                    in: store.referenceTimeZone,
                                    hourFormat: store.hourFormat
                                )
                            )
                            .font(.body.weight(.medium))
                            .monospacedDigit()
                            .foregroundStyle(.primary)
                        }
                    }
                }

                macSection("About") {
                    VStack(spacing: 0) {
                        macSettingsRow(
                            title: "Version",
                            systemImage: "app.badge",
                            tint: AppTheme.actionBlue
                        ) {
                            Text(Bundle.main.releaseVersion)
                                .font(.body.weight(.medium))
                                .foregroundStyle(.primary)
                        }

                        Divider()

                        macSettingsButtonRow(
                            title: "About",
                            systemImage: "info.circle",
                            tint: AppTheme.magic
                        ) {
                            guard let aboutURL = URL(string: Self.aboutURL) else {
                                return
                            }
                            openURL(aboutURL)
                        }

                        Divider()

                        macSettingsButtonRow(
                            title: "Rate on App Store",
                            systemImage: "star.bubble",
                            tint: AppTheme.warm
                        ) {
                            guard let reviewURL = URL(string: Self.appStoreReviewURL) else {
                                requestReview()
                                return
                            }
                            openURL(reviewURL)
                        }
                    }
                }

                macSection("Reset") {
                    macSettingsButtonRow(
                        title: "Restore Defaults",
                        systemImage: "arrow.counterclockwise.circle",
                        tint: .red
                    ) {
                        withAnimation(.snappy) {
                            store.restoreDefaults()
                        }
                    }
                }
            }
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(AppTheme.background.opacity(0.32))
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    func macSection<Content: View>(
        _ title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        GroupBox {
            content()
                .padding(.vertical, 4)
                .frame(maxWidth: .infinity, alignment: .leading)
        } label: {
            Text(title)
                .font(.headline.weight(.semibold))
        }
    }

    func macSettingsRow<Content: View>(
        title: String,
        systemImage: String,
        tint: Color,
        @ViewBuilder content: () -> Content
    ) -> some View {
        HStack(alignment: .center, spacing: 16) {
            SettingsRowLabel(
                title: title,
                systemImage: systemImage,
                tint: tint
            )
            .frame(minWidth: 190, alignment: .leading)

            Spacer(minLength: 12)

            content()
        }
        .frame(minHeight: Self.macRowHeight)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    func macSettingsButtonRow(
        title: String,
        systemImage: String,
        tint: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(alignment: .center, spacing: 16) {
                SettingsRowLabel(
                    title: title,
                    systemImage: systemImage,
                    tint: tint
                )
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(minHeight: Self.macRowHeight)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
