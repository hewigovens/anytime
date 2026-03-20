public protocol WorldClockPersisting {
    func loadConfiguration() -> WorldClockConfiguration?
    func saveConfiguration(_ configuration: WorldClockConfiguration)
}
