import SwiftUI
import AnyTimeCore

struct WorldClockHomeView: View {
    @Bindable var store: WorldClockStore
    @Binding var showingSettings: Bool
    @State private var showingPicker = false
    @State private var pullDownMonitor = PullDownMonitor()

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .top) {
                AppTheme.background
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    headerBlock(safeAreaTop: proxy.safeAreaInsets.top)
                    contentList
                }

                PullDownEasterEggView(monitor: pullDownMonitor)
                    .zIndex(1)
            }
            .ignoresSafeArea(edges: .top)
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
        .animation(.snappy, value: store.favoriteTimeZoneIDs)
    }

    @ViewBuilder
    private var pickerSheet: some View {
        NavigationStack {
            TimeZonePickerView(store: store)
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

    @ViewBuilder
    private var contentList: some View {
        let list = List {
            Section {
                ReferenceCalculatorCard(store: store)
                    .listRowInsets(EdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 16))
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
            }

            Section {
                ForEach(store.displayedPresentations) { presentation in
                    clockRow(for: presentation)
                }
                .onMove(perform: store.moveDisplayedTimeZones)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(Color.clear)

        if #available(iOS 18.0, macOS 15.0, *) {
            list.onScrollGeometryChange(for: CGFloat.self, of: { geometry in
                geometry.contentOffset.y + geometry.contentInsets.top
            }, action: { _, newValue in
                pullDownMonitor.contentOffset = newValue
            })
        } else {
            list.background {
                ScrollViewOffsetObserver { offset in
                    pullDownMonitor.contentOffset = offset
                }
            }
        }
    }

    private func clockRow(for presentation: ClockPresentation) -> some View {
        ClockCardView(presentation: presentation)
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
                Button("Copy", systemImage: "doc.on.doc") {
                    PlatformClipboard.string = presentation.copyText
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
                Button("Copy", systemImage: "doc.on.doc") {
                    PlatformClipboard.string = presentation.copyText
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

    private var searchButton: some View {
        Button {
            showingPicker = true
        } label: {
            Label("Search", systemImage: "magnifyingglass")
        }
        .accessibilityLabel("Search time zones")
    }
}
