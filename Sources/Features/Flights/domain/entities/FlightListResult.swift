public enum FlightDataSource: Sendable, Equatable {
    case remote
    case cache
}

public struct FlightListResult: Sendable, Equatable {
    public let flights: [Flight]
    public let source: FlightDataSource
    public let isStale: Bool
    public let page: Int
    public let hasMorePages: Bool

    public init(flights: [Flight], source: FlightDataSource, isStale: Bool, page: Int, hasMorePages: Bool) {
        self.flights = flights
        self.source = source
        self.isStale = isStale
        self.page = page
        self.hasMorePages = hasMorePages
    }
}
