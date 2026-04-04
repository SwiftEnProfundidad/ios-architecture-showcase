import FlightsFeature
import SharedKernel
import Testing

typealias ListFlightsUseCaseSUT = ListFlightsUseCase<FlightPageRefreshingSpy, FlightPageRefreshingSpy>

struct ListFlightsUseCaseTestContext {
    let sut: ListFlightsUseCaseSUT
    let repository: FlightPageRefreshingSpy
}

func makeListFlightsUseCaseSUT(
    sourceLocation: SourceLocation = #_sourceLocation
) -> TrackedTestContext<ListFlightsUseCaseTestContext> {
    let repository = FlightPageRefreshingSpy()
    let sut = ListFlightsUseCaseSUT(pageReader: repository, refresher: repository)
    return makeLeakTrackedTestContext(
        ListFlightsUseCaseTestContext(
            sut: sut,
            repository: repository
        ),
        trackedInstances: repository,
        sourceLocation: sourceLocation
    )
}
