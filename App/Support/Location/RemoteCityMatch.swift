struct RemoteCityMatch: Identifiable, Hashable {
    let title: String
    let subtitle: String
    let timeZoneID: String

    var id: String {
        "\(timeZoneID)|\(title)|\(subtitle)"
    }

    var searchDeduplicationKey: String {
        "\(timeZoneID.lowercased())|\(title.normalizedPickerSearchText)"
    }
}
