extension String {
    var normalizedPickerSearchText: String {
        folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .autoupdatingCurrent)
            .lowercased()
    }
}
