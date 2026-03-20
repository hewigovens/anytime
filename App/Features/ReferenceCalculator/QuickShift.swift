import AnyTimeCore

struct QuickShift: Identifiable {
    let label: String
    let systemImage: String
    let role: QuickActionRole
    let performsPaste: Bool
    let action: (WorldClockStore) -> Void

    init(
        label: String,
        systemImage: String,
        role: QuickActionRole,
        performsPaste: Bool = false,
        action: @escaping (WorldClockStore) -> Void
    ) {
        self.label = label
        self.systemImage = systemImage
        self.role = role
        self.performsPaste = performsPaste
        self.action = action
    }

    var id: String {
        label
    }
}
