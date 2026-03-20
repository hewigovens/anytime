import AnyTimeCore
import SwiftUI

#if os(iOS)
struct ReferenceDateEditorView: View {
    @Bindable var store: WorldClockStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    var body: some View {
        Group {
            if horizontalSizeClass == .regular {
                regularWidthBody
            } else {
                compactWidthBody
            }
        }
        .environment(\.timeZone, store.referenceTimeZone)
        .navigationTitle("Reference Time")
        .inlineNavigationTitleDisplayMode()
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Close") {
                    dismiss()
                }
            }

            ToolbarItem(placement: .confirmationAction) {
                Button("Now") {
                    store.resetReferenceDate()
                }
            }
        }
    }

    private var compactWidthBody: some View {
        Form {
            Section("Time") {
                referencePicker
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        }
    }

    private var regularWidthBody: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 16) {
                Text("Time")
                    .font(.headline)
                    .foregroundStyle(.secondary)

                HStack {
                    Spacer(minLength: 0)
                    referencePicker
                        .fixedSize()
                        .frame(width: 340, alignment: .center)
                    Spacer(minLength: 0)
                }
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity)
                .appChrome(in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            }
            .frame(maxWidth: 520, alignment: .leading)
            .padding(.horizontal, 28)
            .padding(.top, 24)

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(AppTheme.background.opacity(0.18))
    }

    private var referencePicker: some View {
        WheelDatePicker(
            date: $store.referenceDate,
            timeZone: store.referenceTimeZone,
            locale: store.hourFormat.pickerLocale()
        )
        .frame(width: 340, height: 216)
    }
}
#endif
