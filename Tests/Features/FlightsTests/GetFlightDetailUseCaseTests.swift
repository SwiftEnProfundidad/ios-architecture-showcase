import FlightsFeature
import SharedKernel
import Testing

private typealias SUT = GetFlightDetailUseCase<FlightDetailReadingSpy, WeatherRepositorySpy>

@Suite("GetFlightDetailUseCase")
struct GetFlightDetailUseCaseTests {

    @Test("When loading detail, flight and weather are loaded concurrently with async let")
    func detailLoadsFlightAndWeatherConcurrently() async throws {
        let tracked = makeSUT()
        defer { tracked.assertNoLeaks() }
        let context = tracked.context
        let flightID = FlightID("IB3456")
        let flight = Flight.stub(id: flightID, passengerID: PassengerID("PAX-001"))
        let weather = WeatherInfo.stub(description: "Sunny", temperatureCelsius: 22)
        await context.flightRepository.stub(flights: [flight])
        await context.weatherRepository.stub(weather: weather, forFlightID: flightID)

        let detail = try await context.sut.execute(flightID: flightID)

        #expect(detail.flight.id == flightID)
        #expect(detail.weather?.description == "Sunny")
    }

    @Test("When weather fails, the detail is returned anyway without weather")
    func detailReturnsWithoutWeatherIfWeatherFails() async throws {
        let tracked = makeSUT()
        defer { tracked.assertNoLeaks() }
        let context = tracked.context
        let flightID = FlightID("IB3456")
        let flight = Flight.stub(id: flightID, passengerID: PassengerID("PAX-001"))
        await context.flightRepository.stub(flights: [flight])
        await context.weatherRepository.stubError(forFlightID: flightID)

        let detail = try await context.sut.execute(flightID: flightID)

        #expect(detail.flight.id == flightID)
        #expect(detail.weather == nil)
    }

    private func makeSUT(
        sourceLocation: SourceLocation = #_sourceLocation
    ) -> TrackedTestContext<GetFlightDetailUseCaseTestContext> {
        let flightRepository = FlightDetailReadingSpy()
        let weatherRepository = WeatherRepositorySpy()
        let sut = SUT(flightRepository: flightRepository, weatherRepository: weatherRepository)
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
}

private struct GetFlightDetailUseCaseTestContext {
    let sut: SUT
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
