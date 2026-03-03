import AnyTimeCore
import SwiftUI
#if os(macOS)
import AppKit
#endif

struct ReferenceDateEditorView: View {
    @Bindable var store: WorldClockStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Group {
            #if os(macOS)
            macOSBody
            #else
            iOSBody
            #endif
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

private extension ReferenceDateEditorView {
    var iOSBody: some View {
        Form {
            Section("Time") {
                DatePicker(
                    "Reference time",
                    selection: $store.referenceDate,
                    displayedComponents: [.date, .hourAndMinute]
                )
                #if os(iOS)
                .datePickerStyle(.wheel)
                #else
                .datePickerStyle(.compact)
                #endif
                .labelsHidden()
            }
        }
    }

    var macOSBody: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 18) {
                Text("Update the reference time in \(store.referenceCityName).")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                GroupBox("Date") {
                    #if os(macOS)
                    HStack {
                        Spacer(minLength: 0)

                        MacCalendarDatePicker(
                            date: $store.referenceDate,
                            timeZone: store.referenceTimeZone
                        )
                        .frame(width: 280, height: 240)

                        Spacer(minLength: 0)
                    }
                    .padding(.vertical, 4)
                    #else
                    DatePicker(
                        "Reference date",
                        selection: $store.referenceDate,
                        displayedComponents: .date
                    )
                    .datePickerStyle(.graphical)
                    .labelsHidden()
                    #endif
                }

                GroupBox("Time") {
                    HStack(spacing: 12) {
                        DatePicker(
                            "Reference time",
                            selection: $store.referenceDate,
                            displayedComponents: .hourAndMinute
                        )
                        #if os(macOS)
                        .datePickerStyle(.field)
                        #else
                        .datePickerStyle(.compact)
                        #endif
                        .labelsHidden()

                        Spacer(minLength: 8)

                        Text(store.referenceTimeZone.abbreviation(for: store.referenceDate) ?? store.referenceTimeZone.identifier)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .frame(width: 360, alignment: .leading)
            .padding(24)

            Spacer(minLength: 0)
        }
        .background(AppTheme.background.opacity(0.32))
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
}

#if os(macOS)
private struct MacCalendarDatePicker: NSViewRepresentable {
    @Binding var date: Date
    let timeZone: TimeZone

    func makeCoordinator() -> Coordinator {
        Coordinator(date: $date, timeZone: timeZone)
    }

    func makeNSView(context: Context) -> NSDatePicker {
        let picker = NSDatePicker()
        picker.datePickerStyle = .clockAndCalendar
        picker.datePickerElements = .yearMonthDay
        picker.datePickerMode = .single
        picker.controlSize = .large
        var calendar = Calendar.autoupdatingCurrent
        calendar.timeZone = timeZone
        picker.calendar = calendar
        picker.locale = .autoupdatingCurrent
        picker.timeZone = timeZone
        picker.target = context.coordinator
        picker.action = #selector(Coordinator.dateChanged(_:))
        picker.dateValue = date
        return picker
    }

    func updateNSView(_ nsView: NSDatePicker, context: Context) {
        var calendar = Calendar.autoupdatingCurrent
        calendar.timeZone = timeZone
        nsView.calendar = calendar
        nsView.timeZone = timeZone
        context.coordinator.timeZone = timeZone
        if calendar.isDate(nsView.dateValue, equalTo: date, toGranularity: .day) == false {
            nsView.dateValue = date
        }
    }

    final class Coordinator: NSObject {
        @Binding private var date: Date
        var timeZone: TimeZone

        init(date: Binding<Date>, timeZone: TimeZone) {
            _date = date
            self.timeZone = timeZone
        }

        @MainActor
        @objc
        func dateChanged(_ sender: NSDatePicker) {
            var calendar = Calendar.autoupdatingCurrent
            calendar.timeZone = timeZone
            let currentTime = calendar.dateComponents([.hour, .minute], from: date)
            var pickedDate = calendar.dateComponents([.year, .month, .day], from: sender.dateValue)
            pickedDate.hour = currentTime.hour
            pickedDate.minute = currentTime.minute
            pickedDate.second = 0
            date = calendar.date(from: pickedDate) ?? sender.dateValue
        }
    }
}
#endif
