import FlightsFeature
import SharedKernel
import Testing

private typealias SUT = GetFlightDetailUseCase<FlightDetailReadingSpy, WeatherRepositorySpy>

@Suite("GetFlightDetailUseCase")
struct GetFlightDetailUseCaseTests {

    @Test("When loading detail, flight and weather are loaded concurrently with async let")
    func detailLoadsFlightAndWeatherConcurrently() async throws {
        let (token, sut, flightRepository, weatherRepository) = makeSUT()
        let flightID = FlightID("IB3456")
        let flight = Flight.stub(id: flightID, passengerID: PassengerID("PAX-001"))
        let weather = WeatherInfo.stub(description: "Sunny", temperatureCelsius: 22)
        await flightRepository.stub(flights: [flight])
        await weatherRepository.stub(weather: weather, forFlightID: flightID)

        let detail = try await sut.execute(flightID: flightID)

        #expect(detail.flight.id == flightID)
        #expect(detail.weather?.description == "Sunny")
        _ = token
    }

    @Test("When weather fails, the detail is returned anyway without weather")
    func detailReturnsWithoutWeatherIfWeatherFails() async throws {
        let (token, sut, flightRepository, weatherRepository) = makeSUT()
        let flightID = FlightID("IB3456")
        let flight = Flight.stub(id: flightID, passengerID: PassengerID("PAX-001"))
        await flightRepository.stub(flights: [flight])
        await weatherRepository.stubError(forFlightID: flightID)

        let detail = try await sut.execute(flightID: flightID)

        #expect(detail.flight.id == flightID)
        #expect(detail.weather == nil)
        _ = token
    }

    private func makeSUT(
        sourceLocation: SourceLocation = #_sourceLocation
    ) -> (MemoryLeakToken, SUT, FlightDetailReadingSpy, WeatherRepositorySpy) {
        let token = MemoryLeakToken()
        let flightRepository = FlightDetailReadingSpy()
        let weatherRepository = WeatherRepositorySpy()
        let sut = SUT(flightRepository: flightRepository, weatherRepository: weatherRepository)
        trackForMemoryLeaks(flightRepository, token: token, sourceLocation: sourceLocation)
        trackForMemoryLeaks(weatherRepository, token: token, sourceLocation: sourceLocation)
        return (token, sut, flightRepository, weatherRepository)
    }
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
