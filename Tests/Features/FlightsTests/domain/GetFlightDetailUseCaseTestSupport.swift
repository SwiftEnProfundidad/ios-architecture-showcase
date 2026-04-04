import FlightsFeature
import SharedKernel
import Testing

typealias GetFlightDetailUseCaseSUT = GetFlightDetailUseCase<FlightDetailReadingSpy, WeatherRepositorySpy>

func makeGetFlightDetailUseCaseSUT(
    sourceLocation: SourceLocation = #_sourceLocation
) -> TrackedTestContext<GetFlightDetailUseCaseTestContext> {
    let flightRepository = FlightDetailReadingSpy()
    let weatherRepository = WeatherRepositorySpy()
    let sut = GetFlightDetailUseCaseSUT(
        flightRepository: flightRepository,
        weatherRepository: weatherRepository
    )
    return makeLeakTrackedTestContext(
        GetFlightDetailUseCaseTestContext(
            sut: sut,
            flightRepository: flightRepository,
            weatherRepository: weatherRepository
        ),
        trackedInstances: flightRepository,
        weatherRepository,
        sourceLocation: sourceLocation
    )
}

struct GetFlightDetailUseCaseTestContext {
    let sut: GetFlightDetailUseCaseSUT
    let flightRepository: FlightDetailReadingSpy
    let weatherRepository: WeatherRepositorySpy
}
