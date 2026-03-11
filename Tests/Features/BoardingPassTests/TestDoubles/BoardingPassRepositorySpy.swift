import BoardingPassFeature
import SharedKernel

actor BoardingPassRepositorySpy: BoardingPassRepositoryProtocol {
    private var stubbedPasses: [FlightID: BoardingPassData] = [:]
    private var stubbedErrors: [FlightID: BoardingPassError] = [:]

    func stub(pass: BoardingPassData, forFlightID flightID: FlightID) {
        stubbedPasses[flightID] = pass
    }

    func stubError(_ error: BoardingPassError, forFlightID flightID: FlightID) {
        stubbedErrors[flightID] = error
    }

    func fetch(forFlightID flightID: FlightID) async throws -> BoardingPassData {
        if let error = stubbedErrors[flightID] { throw error }
        guard let pass = stubbedPasses[flightID] else { throw BoardingPassError.notFound }
        return pass
    }
}
