import BoardingPassFeature
import SharedKernel

actor BoardingPassReloadingRepositorySpy: BoardingPassRepositoryProtocol {
    private var resultsByFlightID: [FlightID: [Result<BoardingPassData, Error>]] = [:]

    func stub(
        results: [Result<BoardingPassData, Error>],
        forFlightID flightID: FlightID
    ) {
        resultsByFlightID[flightID] = results
    }

    func fetch(forFlightID flightID: FlightID) async throws -> BoardingPassData {
        guard var results = resultsByFlightID[flightID], results.isEmpty == false else {
            throw BoardingPassError.notFound
        }
        let nextResult = results.removeFirst()
        resultsByFlightID[flightID] = results
        return try nextResult.get()
    }
}
