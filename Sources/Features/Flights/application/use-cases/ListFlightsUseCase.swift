import SharedKernel

public protocol FlightPageListing: Sendable {
    func execute(passengerID: PassengerID, page: Int) async throws -> FlightListResult
}

public protocol VisibleFlightsRefreshing: Sendable {
    func refreshAll(flightIDs: [FlightID]) async throws -> [Flight]
}

public typealias ListFlightsExecuting = FlightPageListing & VisibleFlightsRefreshing

public struct ListFlightsUseCase<PageReader: FlightPageReading, Refresher: FlightRefreshing>: Sendable {
    private let pageReader: PageReader
    private let refresher: Refresher
    private let pageSize: Int

    public init(pageReader: PageReader, refresher: Refresher, pageSize: Int = 10) {
        self.pageReader = pageReader
        self.refresher = refresher
        self.pageSize = pageSize
    }

    public func execute(passengerID: PassengerID, page: Int) async throws -> FlightListResult {
        try await pageReader.fetchPage(passengerID: passengerID, page: page, pageSize: pageSize)
    }

    public func refreshAll(flightIDs: [FlightID]) async throws -> [Flight] {
        try await withThrowingTaskGroup(of: (Int, Flight).self) { group in
            for (index, flightID) in flightIDs.enumerated() {
                group.addTask {
                    (index, try await refresher.refresh(flightID))
                }
            }
            var results: [(Int, Flight)] = []
            for try await result in group {
                results.append(result)
            }
            return results
                .sorted { $0.0 < $1.0 }
                .map(\.1)
        }
    }
}

extension ListFlightsUseCase: ListFlightsExecuting {}

public extension ListFlightsUseCase where PageReader == Refresher, PageReader: FlightRefreshing {
    init(repository: PageReader, pageSize: Int = 10) {
        self.init(pageReader: repository, refresher: repository, pageSize: pageSize)
    }
}
