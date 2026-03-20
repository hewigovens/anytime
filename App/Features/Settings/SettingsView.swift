import AnyTimeCore
import StoreKit
import SwiftUI

struct SettingsView: View {
    @Bindable var store: WorldClockStore
    @Environment(\.dismiss) var dismiss
    @Environment(\.openURL) var openURL
    @Environment(\.requestReview) var requestReview

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

extension SettingsView {
    var iOSBody: some View {
        Form {
            displaySection
            aboutSection
            resetSection
        }
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

            Picker(selection: $store.hourFormat) {
                ForEach(ClockHourFormat.allCases) { format in
                    Text(format.title).tag(format)
                }
            } label: {
                SettingsRowLabel(
                    title: "Hour format",
                    systemImage: "clock",
                    tint: AppTheme.warm
                )
            }

            LabeledContent {
                Text(
                    store.dateStyle.formatted(
                        date: store.referenceDate,
                        in: store.referenceTimeZone,
                        hourFormat: store.hourFormat
                    )
                )
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
}

extension SettingsView {
    static let aboutURL = "https://fourplexlabs.github.io/AnyTime"
    static let appStoreReviewURL = "https://apps.apple.com/us/app/anytime-timezone-calculator/id1291735859?action=write-review"
}
