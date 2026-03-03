import AnyTimeCore
import SwiftUI

#if os(iOS)
struct ReferenceDateEditorView: View {
    @Bindable var store: WorldClockStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Form {
            Section("Time") {
                DatePicker(
                    "Reference time",
                    selection: $store.referenceDate,
                    displayedComponents: [.date, .hourAndMinute]
                )
                .datePickerStyle(.wheel)
                .labelsHidden()
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
}
#endif
