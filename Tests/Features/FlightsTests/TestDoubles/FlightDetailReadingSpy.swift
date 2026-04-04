import FlightsFeature
import SharedKernel

actor FlightDetailReadingSpy: FlightDetailReading {
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

    func fetchByID(_ id: FlightID) async throws -> Flight {
        fetchByIDCallCount += 1
        if let stubbedError {
            throw stubbedError
        }
        guard let flight = stubbedFlights.first(where: { $0.id == id }) else {
            throw FlightError.notFound
        }
        return flight
    }
}
