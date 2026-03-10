public struct FlightID: Sendable, Hashable {
    public let value: String

    public init(_ value: String) {
        self.value = value
    }
}
