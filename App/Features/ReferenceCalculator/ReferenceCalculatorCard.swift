import AnyTimeCore
import SwiftUI

struct ReferenceCalculatorCard: View {
    @Bindable var store: WorldClockStore
    @State private var pasteFeedback: PasteFeedback?
    @State private var isResolvingPaste = false
    #if os(iOS)
    @State private var showingDateEditor = false
    @State private var didApplyScreenshotScenario = false
    #endif

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top, spacing: 16) {
                VStack(alignment: .leading, spacing: 5) {
                    Text("Timezone Calculator")
                        .font(.system(.title3, design: .rounded).weight(.bold))
                        .foregroundStyle(.primary)

                    Text("Tap the date or time to change it quickly.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 0)

                hourFormatToggle
            }

            if let presentation = store.referencePresentation {
                VStack(alignment: .leading, spacing: 8) {
                    formattedTimeLabel(for: presentation.formattedTime)

                    referenceZoneMenu {
                        HStack(spacing: 6) {
                            Text("\(presentation.title) • \(presentation.utcOffsetText)")
                            Image(systemName: "chevron.up.chevron.down")
                                .font(.caption.weight(.semibold))
                        }
                        .font(.body.weight(.medium))
                        .foregroundStyle(.secondary)
                    }
                    .padding(.leading, 4)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            referenceDateControl

            VStack(spacing: 10) {
                HStack(spacing: 10) {
                    ForEach(Self.topRowActions) { action in
                        quickActionButton(action)
                    }
                }

                HStack(spacing: 10) {
                    ForEach(Self.bottomRowActions) { action in
                        quickActionButton(action)
                    }
                }
            }

            if let pasteFeedback {
                Text(pasteFeedback.message)
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(pasteFeedback.isError ? .secondary : AppTheme.accent)
                    .lineLimit(2)
                    .transition(.opacity)
            }
        }
        .padding(20)
        .background(AppTheme.calculatorSurface, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(AppTheme.calculatorStroke, lineWidth: 1)
        }
        .shadow(color: AppTheme.shadow, radius: 12, y: 5)
        #if os(iOS)
        .sheet(isPresented: $showingDateEditor) {
            dateEditorSheet
        }
        .task {
            guard didApplyScreenshotScenario == false else {
                return
            }

            didApplyScreenshotScenario = true

            if AppStoreScreenshotScenario.current == .referenceTime {
                showingDateEditor = true
            }
        }
        #endif
    }

    @ViewBuilder
    private func formattedTimeLabel(for time: String) -> some View {
        #if os(iOS)
        Button {
            showingDateEditor = true
        } label: {
            formattedTimeText(for: time)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Edit reference time \(time)")
        #else
        formattedTimeText(for: time)
        #endif
    }

    private func formattedTimeText(for time: String) -> some View {
        Text(time)
            .font(.system(size: 36, weight: .bold, design: .rounded))
            .monospacedDigit()
            .lineLimit(1)
            .minimumScaleFactor(0.85)
            .foregroundStyle(.primary)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    #if os(iOS)
    private var dateEditorSheet: some View {
        NavigationStack {
            ReferenceDateEditorView(store: store)
        }
        .presentationDetents([.medium])
    }
    #endif

    @ViewBuilder
    private var referenceDateControl: some View {
        #if os(macOS)
        HStack(spacing: 12) {
            Image(systemName: "calendar.badge.clock")
                .foregroundStyle(AppTheme.accent)

            DatePicker(
                "Reference time",
                selection: $store.referenceDate,
                displayedComponents: [.date, .hourAndMinute]
            )
            .datePickerStyle(.field)
            .labelsHidden()
            .environment(\.timeZone, store.referenceTimeZone)
            .environment(\.locale, store.hourFormat.pickerLocale())
            .frame(maxWidth: .infinity, alignment: .leading)

            Text(store.referenceTimeZone.identifier.replacingOccurrences(of: "_", with: " "))
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .appChrome(in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        #else
        HStack(spacing: 10) {
            DatePicker(
                "Reference time",
                selection: $store.referenceDate,
                displayedComponents: [.hourAndMinute, .date]
            )
            .datePickerStyle(.compact)
            .labelsHidden()
            .environment(\.timeZone, store.referenceTimeZone)
            .environment(\.locale, store.hourFormat.pickerLocale())
            .tint(AppTheme.accent)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        #endif
    }

    private var hourFormatToggle: some View {
        Picker("Hour format", selection: $store.hourFormat) {
            Text("24h").tag(ClockHourFormat.twentyFourHour)
            Text("12h").tag(ClockHourFormat.twelveHour)
        }
        .pickerStyle(.segmented)
        .frame(width: 116)
        .controlSize(.small)
        .labelsHidden()
        .accessibilityLabel("Hour format")
    }

    private func referenceZoneMenu<Label: View>(
        @ViewBuilder label: () -> Label
    ) -> some View {
        Menu {
            ForEach(store.presentations) { presentation in
                Button(presentation.selectionTitle) {
                    withAnimation(.snappy) {
                        store.setReferenceTimeZone(id: presentation.timeZoneID)
                    }
                }
            }
        } label: {
            label()
                .foregroundStyle(.primary)
                .contentShape(Rectangle())
        }
    }

    @MainActor
    private func pasteReferenceDate() async {
        guard let clipboard = PlatformClipboard.string else {
            pasteFeedback = PasteFeedback(message: "Clipboard is empty.", isError: true)
            return
        }

        isResolvingPaste = true
        pasteFeedback = PasteFeedback(message: "Analyzing clipboard…", isError: false)

        let result = await ReferencePasteResolver.resolve(from: clipboard)

        isResolvingPaste = false

        switch result {
        case let .success(resolution):
            withAnimation(.snappy) {
                if let timeZoneID = resolution.timeZoneID {
                    store.selectTimeZone(
                        id: timeZoneID,
                        preferredCityName: resolution.preferredCityName
                    )
                    store.setReferenceTimeZone(id: timeZoneID)
                }

                if let date = resolution.date {
                    store.referenceDate = date
                }

                pasteFeedback = PasteFeedback(
                    message: resolution.message,
                    isError: false
                )
            }

        case let .failure(message):
            pasteFeedback = PasteFeedback(message: message, isError: true)
        }
    }

    private static let quickActions = [
        QuickShift(label: "+1h", systemImage: "plus.circle", role: .cool, action: { $0.shiftReference(hours: 1) }),
        QuickShift(label: "-1h", systemImage: "minus.circle", role: .cool, action: { $0.shiftReference(hours: -1) }),
        QuickShift(label: "Now", systemImage: "arrow.clockwise", role: .warm, action: { $0.resetReferenceDate() })
    ]

    private static let bottomRowActions = [
        QuickShift(label: "+1d", systemImage: "forward.end", role: .cool, action: { $0.shiftReference(days: 1) }),
        QuickShift(label: "-1d", systemImage: "backward.end", role: .cool, action: { $0.shiftReference(days: -1) }),
        QuickShift(label: "Paste", systemImage: "wand.and.stars", role: .magic, performsPaste: true, action: { _ in })
    ]

    private static let topRowActions = quickActions

    private func quickActionButton(_ action: QuickShift) -> some View {
        Button {
            if action.performsPaste {
                Task {
                    await pasteReferenceDate()
                }
            } else {
                action.action(store)
            }
        } label: {
            Label(action.label, systemImage: action.systemImage)
                .font(.subheadline.weight(.semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.82)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(QuickActionButtonStyle(role: action.role))
        .disabled(action.performsPaste && isResolvingPaste)
    }
}
