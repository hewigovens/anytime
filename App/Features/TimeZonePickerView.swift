import SwiftUI
import AnyTimeCore

struct TimeZonePickerView: View {
    @Bindable var store: WorldClockStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @State private var searchText = ""
    @State private var remoteMatches: [RemoteCityMatch] = []
    @State private var isLookingUpCities = false
    @State private var didRequestInitialFocus = false
    @State private var didApplyScreenshotScenario = false
    @FocusState private var isSearchFieldFocused: Bool

    private var localSections: [TimeZoneSection] {
        store.searchSections(matching: searchText)
    }

    private var selectedIDs: Set<String> {
        Set(store.favoriteTimeZoneIDs)
    }

    private var trimmedQuery: String {
        searchText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var hasSearchQuery: Bool {
        trimmedQuery.isEmpty == false
    }

    var body: some View {
        Group {
            #if os(macOS)
            macOSBody
            #else
            iOSBody
            #endif
        }
        .navigationTitle("Add Clock")
        .inlineNavigationTitleDisplayMode()
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Close") {
                    dismiss()
                }
            }
        }
        .task {
            guard AppStoreScreenshotScenario.current != .search else {
                return
            }

            guard didRequestInitialFocus == false else {
                return
            }
            didRequestInitialFocus = true
            try? await Task.sleep(for: .milliseconds(250))
            guard Task.isCancelled == false else {
                return
            }
            isSearchFieldFocused = true
        }
        .task(id: trimmedQuery) {
            await loadRemoteMatches(for: trimmedQuery)
        }
        .task {
            guard didApplyScreenshotScenario == false else {
                return
            }

            didApplyScreenshotScenario = true

            if AppStoreScreenshotScenario.current == .search,
               let searchText = AppStoreScreenshotScenario.searchText,
               searchText.isEmpty == false {
                self.searchText = searchText
                isSearchFieldFocused = false
            }
        }
    }

    private var iOSBody: some View {
        VStack(spacing: 12) {
            searchField
                .padding(.horizontal, 16)
                .padding(.top, 8)

            resultsList
        }
        .background(AppTheme.background.opacity(0.2))
    }

    private var macOSBody: some View {
        ScrollViewReader { proxy in
            VStack(spacing: 0) {
                searchField
                    .padding(20)

                Divider()

                resultsList
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .onAppear {
                        proxy.scrollTo(Self.resultsTopID, anchor: .top)
                    }
                    .onChange(of: trimmedQuery) { _, _ in
                        withAnimation(.snappy) {
                            proxy.scrollTo(Self.resultsTopID, anchor: .top)
                        }
                    }
                    .onChange(of: remoteMatches) { _, _ in
                        withAnimation(.snappy) {
                            proxy.scrollTo(Self.resultsTopID, anchor: .top)
                        }
                    }
            }
            .background(AppTheme.background.opacity(0.28))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private var resultsList: some View {
        List {
            #if os(macOS)
            Color.clear
                .frame(height: 1)
                .listRowInsets(EdgeInsets())
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
                .id(Self.resultsTopID)
            #endif

            if hasSearchQuery, isLookingUpCities, remoteMatches.isEmpty {
                Section {
                    HStack(spacing: 10) {
                        ProgressView()
                            .controlSize(.small)
                        Text("Searching cities…")
                            .font(.footnote.weight(.medium))
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 4)
                }
            }

            if hasSearchQuery, remoteMatches.isEmpty == false {
                Section("Suggested Cities") {
                    ForEach(remoteMatches) { match in
                        resultRow(
                            title: match.title,
                            subtitle: match.subtitle,
                            identifier: match.timeZoneID,
                            preferredCityName: match.title
                        )
                    }
                }
            }

            ForEach(localSections) { section in
                Section(section.title) {
                    ForEach(section.items) { descriptor in
                        resultRow(
                            title: descriptor.city,
                            subtitle: descriptor.locationLine,
                            identifier: descriptor.identifier
                        )
                    }
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(AppTheme.background.opacity(0.2))
        .overlay {
            if localSections.isEmpty, remoteMatches.isEmpty, hasSearchQuery, isLookingUpCities == false {
                ContentUnavailableView.search(text: searchText)
            }
        }
    }

    @ViewBuilder
    private func statusBadge(for timeZoneID: String) -> some View {
        if timeZoneID == store.referenceTimeZoneID {
            badge(
                "Reference",
                foreground: AppTheme.warm,
                background: AppTheme.warm.opacity(0.18)
            )
        } else if selectedIDs.contains(timeZoneID) {
            badge(
                "Added",
                foreground: AppTheme.ink.opacity(0.82),
                background: Color.secondary.opacity(0.14)
            )
        } else {
            let title = TimeZoneDescriptor(identifier: timeZoneID)?.abbreviation(at: .now)
                ?? (TimeZone(identifier: timeZoneID)?.abbreviation(for: .now) ?? "TZ")
            badge(
                title,
                foreground: AppTheme.accent,
                background: AppTheme.accent.opacity(0.12)
            )
        }
    }

    private var searchField: some View {
        HStack(spacing: 10) {
            #if os(iOS)
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            #endif

            TextField("Search any city, region, abbreviation, or UTC", text: $searchText)
                #if os(iOS)
                .textInputAutocapitalization(.words)
                .submitLabel(.search)
                #else
                .textFieldStyle(.plain)
                #endif
                .autocorrectionDisabled()
                .focused($isSearchFieldFocused)
                .foregroundStyle(.primary)

            if searchText.isEmpty == false {
                Button {
                    searchText = ""
                    remoteMatches = []
                    isSearchFieldFocused = true
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.tertiary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(AppTheme.searchFieldSurface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(AppTheme.searchFieldStroke, lineWidth: 1)
        }
        .shadow(color: AppTheme.shadow.opacity(colorScheme == .dark ? 0.9 : 0.5), radius: 14, y: 6)
    }

    private func selectTimeZone(id: String, preferredCityName: String? = nil) {
        isSearchFieldFocused = false
        withAnimation(.snappy) {
            store.selectTimeZone(id: id, preferredCityName: preferredCityName)
        }
        dismiss()
    }

    private func resultRow(
        title: String,
        subtitle: String,
        identifier: String,
        preferredCityName: String? = nil
    ) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.body.weight(.medium))
                    .foregroundStyle(.primary)

                Text(subtitle)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                Text(identifier)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
            }

            Spacer(minLength: 8)

            statusBadge(for: identifier)
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture {
            selectTimeZone(id: identifier, preferredCityName: preferredCityName)
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
    }

    @MainActor
    private func loadRemoteMatches(for query: String) async {
        guard query.count >= 2 else {
            remoteMatches = []
            isLookingUpCities = false
            return
        }

        isLookingUpCities = true

        do {
            try await Task.sleep(for: .milliseconds(280))
            try Task.checkCancellation()

            let matches = try await RemoteCityLookup.lookup(matching: query)
            try Task.checkCancellation()

            let localKeys = Set(localSections.flatMap(\.items).map(\.searchDeduplicationKey))
            remoteMatches = matches.filter { localKeys.contains($0.searchDeduplicationKey) == false }
            isLookingUpCities = false
        } catch is CancellationError {
        } catch {
            remoteMatches = []
            isLookingUpCities = false
        }
    }

    private func badge(
        _ title: String,
        foreground: Color,
        background: Color
    ) -> some View {
        Text(title)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(background.opacity(colorScheme == .dark ? 1 : 0.92), in: Capsule())
            .foregroundStyle(foreground)
    }
}

private extension TimeZonePickerView {
    static let resultsTopID = "timezone-results-top"
}

private extension TimeZoneDescriptor {
    var searchDeduplicationKey: String {
        "\(identifier.lowercased())|\(city.normalizedPickerSearchText)"
    }
}
