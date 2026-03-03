import AnyTimeCore
import SwiftUI

#if os(iOS)
import UIKit
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
                .background(AppTheme.searchFieldSurface, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(AppTheme.searchFieldStroke, lineWidth: 1)
                }
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
            timeZone: store.referenceTimeZone
        )
        .frame(width: 340, height: 216)
    }
}

private struct WheelDatePicker: UIViewRepresentable {
    @Binding var date: Date
    let timeZone: TimeZone

    func makeCoordinator() -> Coordinator {
        Coordinator(date: $date)
    }

    func makeUIView(context: Context) -> UIView {
        let container = UIView()
        container.backgroundColor = .clear

        let picker = UIDatePicker()
        picker.translatesAutoresizingMaskIntoConstraints = false
        picker.datePickerMode = .dateAndTime
        picker.preferredDatePickerStyle = .wheels
        picker.locale = .autoupdatingCurrent
        picker.timeZone = timeZone
        picker.date = date
        picker.addTarget(context.coordinator, action: #selector(Coordinator.dateChanged(_:)), for: .valueChanged)

        container.addSubview(picker)

        NSLayoutConstraint.activate([
            picker.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            picker.centerYAnchor.constraint(equalTo: container.centerYAnchor)
        ])

        context.coordinator.picker = picker
        return container
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        guard let picker = context.coordinator.picker else {
            return
        }

        picker.timeZone = timeZone
        if picker.date != date {
            picker.date = date
        }
    }

    final class Coordinator: NSObject {
        @Binding private var date: Date
        weak var picker: UIDatePicker?

        init(date: Binding<Date>) {
            _date = date
        }

        @MainActor
        @objc
        func dateChanged(_ sender: UIDatePicker) {
            date = sender.date
        }
    }
}
#endif
