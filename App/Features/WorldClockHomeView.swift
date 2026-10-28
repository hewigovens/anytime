import SwiftUI
import AnyTimeCore

struct WorldClockHomeView: View {
    @Bindable var store: WorldClockStore
    @Binding var showingSettings: Bool
    let currentLocationTimeZoneID: String?
    let currentLocationCityName: String?
    let requestCurrentLocation: () -> Void
    @State private var calendarEventStore = CalendarEventStore()
    @State private var calendarFeedback: CalendarFeedback?
    @State private var calendarDraft: CalendarDraft?
    @State private var eventTitle = ""
    @State private var showingPicker = false
    @State private var pullDownMonitor = PullDownMonitor()
    @State private var postureMonitor = DevicePostureMonitor()
    @State private var headerHeight: CGFloat = 0
    @State private var didApplyScreenshotScenario = false

    private let layoutPolicy = WorldClockLayoutPolicy()

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .top) {
                AppTheme.background
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    headerBlock(safeAreaTop: proxy.safeAreaInsets.top)
                        .onGeometryChange(for: CGFloat.self, of: \.size.height) { newHeight in
                            headerHeight = newHeight
                        }
                    contentArea(displaySize: proxy.size, headerHeight: headerHeight)
                }

                PullDownEasterEggView(monitor: pullDownMonitor)
                    .zIndex(1)
            }
            .ignoresSafeArea(edges: .top)
            .overlay(alignment: .topLeading) {
                postureReader
            }
        }
        #if os(iOS)
        .toolbar(.hidden, for: .navigationBar)
        #endif
        .toolbar {
            #if os(macOS)
            ToolbarItemGroup {
                searchButton

                Button {
                    showingSettings = true
                } label: {
                    Label("Settings", systemImage: "gearshape")
                }
                .accessibilityLabel("Settings")
            }
            #else
            ToolbarItem(placement: .bottomBar) {
                Button {
                    showingSettings = true
                } label: {
                    Label("Settings", systemImage: "gearshape")
                }
                .labelStyle(.iconOnly)
                .accessibilityLabel("Settings")
            }

            if #available(iOS 26.0, *) {
                ToolbarSpacer(.flexible, placement: .bottomBar)

                ToolbarItem(placement: .bottomBar) {
                    searchButton
                        .labelStyle(.iconOnly)
                }
            } else {
                ToolbarItem(placement: .status) {
                    searchButton
                }
            }
            #endif
        }
        .sheet(isPresented: $showingPicker) {
            pickerSheet
        }
        .sheet(isPresented: $showingSettings) {
            settingsSheet
        }
        .alert("Add to Calendar", isPresented: showingCalendarDraft) {
            TextField("Title", text: $eventTitle)

            Button("Cancel", role: .cancel) {
                dismissCalendarDraft()
            }

            Button("Save") {
                guard let calendarDraft else {
                    return
                }

                let title = eventTitle
                dismissCalendarDraft()

                Task {
                    await createCalendarEvent(for: calendarDraft.presentation, title: title)
                }
            }
        } message: {
            if let calendarDraft {
                Text("Create an event for \(calendarDraft.presentation.formattedTime) in \(calendarDraft.presentation.title).")
            }
        }
        .alert(item: $calendarFeedback) { feedback in
            Alert(
                title: Text(feedback.title),
                message: Text(feedback.message),
                dismissButton: .default(Text("OK"))
            )
        }
        .animation(.snappy, value: store.favoriteTimeZoneIDs)
        .task {
            guard didApplyScreenshotScenario == false else {
                return
            }

            didApplyScreenshotScenario = true

            switch AppStoreScreenshotScenario.current {
            case .search:
                showingPicker = true
            case .settings:
                showingSettings = true
            default:
                break
            }
        }
    }

    @ViewBuilder
    private var pickerSheet: some View {
        NavigationStack {
            TimeZonePickerView(
                store: store,
                currentLocationTimeZoneID: currentLocationTimeZoneID,
                currentLocationCityName: currentLocationCityName,
                requestCurrentLocation: requestCurrentLocation
            )
        }
        #if os(macOS)
        .frame(minWidth: 680, minHeight: 520)
        #endif
        #if os(iOS)
        .presentationDetents([.large])
        #endif
    }

    @ViewBuilder
    private var settingsSheet: some View {
        NavigationStack {
            SettingsView(store: store)
        }
        #if os(macOS)
        .frame(minWidth: 560, minHeight: 460)
        #endif
        #if os(iOS)
        .presentationDetents([.medium, .large])
        #endif
    }

    private var header: some View {
        Text("AnyTime")
            .font(.system(.title2, design: .rounded).weight(.bold))
            .foregroundStyle(AppTheme.ink)
            .lineLimit(1)
            .minimumScaleFactor(0.8)
    }

    private func headerBlock(safeAreaTop: CGFloat) -> some View {
        header
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 16)
            .padding(.top, safeAreaTop + 10)
            .padding(.bottom, 12)
            .background(AppTheme.headerSurface)
    }

    /// A zero-sized bridge that keeps the posture monitor in sync with the hinge.
    @ViewBuilder
    private var postureReader: some View {
        #if os(iOS)
        HingePostureReader(monitor: postureMonitor)
            .frame(width: 0, height: 0)
            .accessibilityHidden(true)
        #endif
    }

    /// The layout is chosen from the display size, while the stacked panes are
    /// sized from the height left below the header. Passing the display height as
    /// the content height makes the panes and gutter overflow by the header's
    /// height.
    private func contentArea(displaySize: CGSize, headerHeight: CGFloat) -> some View {
        let contentHeight = max(0, displaySize.height - headerHeight)
        let contentSize = CGSize(width: displaySize.width, height: contentHeight)
        // The crease runs through the middle of the display, measured from the
        // top of the content area.
        let creaseOffset = max(0, (displaySize.height / 2) - headerHeight)

        return WorldClockLayoutViews(
            store: store,
            layout: layoutPolicy.layout(posture: postureMonitor.posture, size: contentSize),
            policy: layoutPolicy,
            size: contentSize,
            creaseOffset: creaseOffset,
            pullDownMonitor: pullDownMonitor,
            clockRows: { clockRows }
        )
    }

    @ViewBuilder
    private var clockRows: some View {
        ForEach(store.displayedPresentations) { presentation in
            clockRow(for: presentation)
        }
        .onMove(perform: store.moveDisplayedTimeZones)
    }

    private func clockRow(for presentation: ClockPresentation) -> some View {
        ClockCardView(
            presentation: presentation,
            isCurrentLocation: presentation.timeZoneID == currentLocationTimeZoneID,
            currentLocationCityName: currentLocationCityName
        )
            .equatable()
            .contentShape(Rectangle())
            .onTapGesture {
                guard presentation.isReference == false else {
                    return
                }
                withAnimation(.snappy) {
                    store.setReferenceTimeZone(id: presentation.timeZoneID)
                }
            }
            .swipeActions(edge: .leading, allowsFullSwipe: false) {
                if presentation.isReference == false {
                    Button("Reference", systemImage: "arrow.up.to.line") {
                        withAnimation(.snappy) {
                            store.setReferenceTimeZone(id: presentation.timeZoneID)
                        }
                    }
                    .tint(AppTheme.accent)
                }
            }
            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                Button("Calendar", systemImage: "calendar.badge.plus") {
                    presentCalendarDraft(for: presentation)
                }
                .tint(AppTheme.accent)

                if store.hasMultipleFavorites {
                    Button("Remove", systemImage: "trash") {
                        withAnimation(.snappy) {
                            store.removeTimeZone(id: presentation.timeZoneID)
                        }
                    }
                    .tint(.red)
                }
            }
            #if os(macOS)
            .contextMenu {
                Button("Calendar", systemImage: "calendar.badge.plus") {
                    presentCalendarDraft(for: presentation)
                }

                if presentation.isReference == false {
                    Button("Reference", systemImage: "arrow.up.to.line") {
                        withAnimation(.snappy) {
                            store.setReferenceTimeZone(id: presentation.timeZoneID)
                        }
                    }
                }

                if store.hasMultipleFavorites {
                    Divider()

                    Button("Remove", systemImage: "trash", role: .destructive) {
                        withAnimation(.snappy) {
                            store.removeTimeZone(id: presentation.timeZoneID)
                        }
                    }
                }
            }
            #endif
            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
    }

    @MainActor
    private func createCalendarEvent(for presentation: ClockPresentation, title: String) async {
        do {
            let message = try await calendarEventStore.createEvent(
                title: title,
                for: presentation,
                referenceDate: store.referenceDate
            )
            calendarFeedback = CalendarFeedback(title: "Calendar Event Added", message: message)
        } catch {
            calendarFeedback = CalendarFeedback(
                title: "Couldn’t Add Calendar Event",
                message: (error as? LocalizedError)?.errorDescription ?? "Something went wrong."
            )
        }
    }

    private func presentCalendarDraft(for presentation: ClockPresentation) {
        calendarDraft = CalendarDraft(presentation: presentation)
        eventTitle = calendarEventStore.defaultTitle(for: presentation)
    }

    private func dismissCalendarDraft() {
        calendarDraft = nil
        eventTitle = ""
    }

    private var showingCalendarDraft: Binding<Bool> {
        Binding(
            get: { calendarDraft != nil },
            set: { isPresented in
                if isPresented == false {
                    dismissCalendarDraft()
                }
            }
        )
    }

    private var searchButton: some View {
        Button {
            showingPicker = true
        } label: {
            Label("Search", systemImage: "magnifyingglass")
        }
        .accessibilityLabel("Search time zones")
    }
}

private struct CalendarFeedback: Identifiable {
    let title: String
    let message: String

    var id: String {
        "\(title)|\(message)"
    }
}

private struct CalendarDraft: Identifiable {
    let presentation: ClockPresentation

    var id: String {
        presentation.id
    }
}
