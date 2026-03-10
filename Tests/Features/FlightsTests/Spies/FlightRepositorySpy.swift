@testable import iOSArchitectureShowcase

actor FlightRepositorySpy: FlightRepositoryProtocol {
    private var stubbedFlights: [Flight] = []
    private var stubbedError: FlightError?
    private(set) var fetchByIDCallCount = 0

    func stub(flights: [Flight]) {
        stubbedFlights = flights
        stubbedError = nil
    }

    func stubError(_ error: FlightError) {
        stubbedError = error
    }

    func fetchAll(passengerID: PassengerID) async throws -> [Flight] {
        if let error = stubbedError { throw error }
        return stubbedFlights.filter { $0.passengerID == passengerID }
    }

    func fetchByID(_ id: FlightID) async throws -> Flight {
        fetchByIDCallCount += 1
        if let error = stubbedError { throw error }
        guard let flight = stubbedFlights.first(where: { $0.id == id }) else {
            throw FlightError.notFound
        }
        return flight
    }
}
