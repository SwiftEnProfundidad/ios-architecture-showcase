import BoardingPassFeature
import SharedKernel
import Testing

@MainActor
func makeBoardingPassViewModelSUT(
    flightID: FlightID = FlightID("IB3456"),
    sourceLocation: SourceLocation = #_sourceLocation
) -> TrackedTestContext<BoardingPassViewModelTestContext<BoardingPassRepositorySpy>> {
    let repository = BoardingPassRepositorySpy()
    let sut = BoardingPassViewModel(
        useCase: GetBoardingPassUseCase(repository: repository),
        flightID: flightID
    )
    return makeLeakTrackedTestContext(
        BoardingPassViewModelTestContext(sut: sut, repository: repository),
        trackedInstances: repository,
        sut,
        sourceLocation: sourceLocation
    )
}

@MainActor
func makeReloadingBoardingPassViewModelSUT(
    flightID: FlightID = FlightID("IB3456"),
    sourceLocation: SourceLocation = #_sourceLocation
) -> TrackedTestContext<BoardingPassViewModelTestContext<BoardingPassReloadingRepositorySpy>> {
    let repository = BoardingPassReloadingRepositorySpy()
    let sut = BoardingPassViewModel(
        useCase: GetBoardingPassUseCase(repository: repository),
        flightID: flightID
    )
    return makeLeakTrackedTestContext(
        BoardingPassViewModelTestContext(sut: sut, repository: repository),
        trackedInstances: repository,
        sut,
        sourceLocation: sourceLocation
    )
}

struct BoardingPassViewModelTestContext<Repository: BoardingPassRepositoryProtocol> {
    let sut: BoardingPassViewModel<GetBoardingPassUseCase<Repository>>
    let repository: Repository
}

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
