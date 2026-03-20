import SwiftUI

#if os(iOS)
import UIKit

struct WheelDatePicker: UIViewRepresentable {
    @Binding var date: Date
    let timeZone: TimeZone
    let locale: Locale

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
        picker.locale = locale
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

        picker.locale = locale
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
