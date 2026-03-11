import SharedKernel

public protocol FlightPageReading: Sendable {
    func fetchPage(passengerID: PassengerID, page: Int, pageSize: Int) async throws -> FlightListResult
}

public protocol FlightDetailReading: Sendable {
    func fetchByID(_ id: FlightID) async throws -> Flight
}

public protocol FlightRefreshing: Sendable {
    func refresh(_ id: FlightID) async throws -> Flight
}

public typealias FlightRepositoryProtocol = FlightPageReading & FlightDetailReading & FlightRefreshing
