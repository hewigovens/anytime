import AnyTimeCore
import StoreKit
import SwiftUI

struct SettingsView: View {
    @Bindable var store: WorldClockStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @Environment(\.requestReview) private var requestReview

    var body: some View {
        Group {
            #if os(macOS)
            macOSBody
            #else
            iOSBody
            #endif
        }
        .navigationTitle("Settings")
        .inlineNavigationTitleDisplayMode()
        .toolbar {
            #if os(macOS)
            ToolbarItem(placement: .cancellationAction) {
                Button("Close") {
                    dismiss()
                }
            }
            #endif
        }
    }
}

private struct SettingsRowLabel: View {
    let title: String
    let systemImage: String
    let tint: Color

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .fill(tint.opacity(0.14))

                Image(systemName: systemImage)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(tint)
                    .frame(width: 16, height: 16, alignment: .center)
            }
            .frame(width: 28, height: 28)

            Text(title)
        }
    }
}

private extension SettingsView {
    static let macRowHeight: CGFloat = 54

    var iOSBody: some View {
        Form {
            displaySection
            aboutSection
            resetSection
        }
    }

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
                            title: "Preview",
                            systemImage: "eye",
                            tint: AppTheme.magic
                        ) {
                            Text(store.dateStyle.formatted(date: store.referenceDate, in: store.referenceTimeZone))
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

    var displaySection: some View {
        Section("Display") {
            Picker(selection: $store.labelStyle) {
                ForEach(ClockLabelStyle.allCases) { style in
                    Text(style.title).tag(style)
                }
            } label: {
                SettingsRowLabel(
                    title: "Primary label",
                    systemImage: "textformat.alt",
                    tint: AppTheme.actionBlue
                )
            }

            Picker(selection: $store.dateStyle) {
                ForEach(ClockDateStyle.allCases) { style in
                    Text(style.title).tag(style)
                }
            } label: {
                SettingsRowLabel(
                    title: "Clock format",
                    systemImage: "clock.arrow.trianglehead.counterclockwise.rotate.90",
                    tint: AppTheme.accent
                )
            }

            LabeledContent {
                Text(store.dateStyle.formatted(date: store.referenceDate, in: store.referenceTimeZone))
                    .font(.subheadline.weight(.medium))
                    .monospacedDigit()
            } label: {
                SettingsRowLabel(
                    title: "Preview",
                    systemImage: "eye",
                    tint: AppTheme.magic
                )
            }
        }
    }

    var aboutSection: some View {
        Section("About") {
            LabeledContent {
                Text(Bundle.main.releaseVersion)
            } label: {
                SettingsRowLabel(
                    title: "Version",
                    systemImage: "app.badge",
                    tint: AppTheme.actionBlue
                )
            }

            Button {
                guard let aboutURL = URL(string: Self.aboutURL) else {
                    return
                }
                openURL(aboutURL)
            } label: {
                SettingsRowLabel(
                    title: "About",
                    systemImage: "info.circle",
                    tint: AppTheme.magic
                )
            }

            Button {
                guard let reviewURL = URL(string: Self.appStoreReviewURL) else {
                    requestReview()
                    return
                }
                openURL(reviewURL)
            } label: {
                SettingsRowLabel(
                    title: "Rate on App Store",
                    systemImage: "star.bubble",
                    tint: AppTheme.warm
                )
            }
        }
    }

    var resetSection: some View {
        Section("Reset") {
            Button(role: .destructive) {
                store.restoreDefaults()
            } label: {
                SettingsRowLabel(
                    title: "Restore Default",
                    systemImage: "arrow.counterclockwise.circle",
                    tint: .red
                )
            }
        }
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

private extension Bundle {
    var releaseVersion: String {
        let version = object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
        let build = object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
        return "\(version) (\(build))"
    }
}

private extension SettingsView {
    static let aboutURL = "https://fourplexlabs.github.io/AnyTime"
    static let appStoreReviewURL = "https://apps.apple.com/us/app/anytime-timezone-calculator/id1291735859?action=write-review"
}
