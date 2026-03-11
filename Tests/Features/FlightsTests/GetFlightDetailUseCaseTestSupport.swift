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
