import FlightsFeature
import SharedKernel
import Testing

@Suite("GetFlightDetailUseCase")
struct GetFlightDetailUseCaseTests {

    @Test("When loading detail, flight and weather are loaded concurrently with async let")
    func detailLoadsFlightAndWeatherConcurrently() async throws {
        let tracked = makeGetFlightDetailUseCaseSUT()
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
        let tracked = makeGetFlightDetailUseCaseSUT()
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
}
