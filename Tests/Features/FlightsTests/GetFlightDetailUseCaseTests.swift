import Testing
@testable import Flights
@testable import SharedKernel

@Suite("GetFlightDetailUseCase")
struct GetFlightDetailUseCaseTests {

    @Test("When loading detail, flight and weather are loaded concurrently with async let")
    func detailLoadsFlightAndWeatherConcurrently() async throws {
        let flightID = FlightID("IB3456")
        let flight = Flight.stub(id: flightID, passengerID: PassengerID("PAX-001"))
        let weather = WeatherInfo.stub(description: "Sunny", temperatureCelsius: 22)

        let flightRepository = FlightRepositorySpy()
        await flightRepository.stub(flights: [flight])
        let weatherRepository = WeatherRepositorySpy()
        await weatherRepository.stub(weather: weather, forFlightID: flightID)

        let sut = GetFlightDetailUseCase(
            flightRepository: flightRepository,
            weatherRepository: weatherRepository
        )

        let detail = try await sut.execute(flightID: flightID)

        #expect(detail.flight.id == flightID)
        #expect(detail.weather?.description == "Sunny")
    }

    @Test("When weather fails, the detail is returned anyway without weather")
    func detailReturnsWithoutWeatherIfWeatherFails() async throws {
        let flightID = FlightID("IB3456")
        let flight = Flight.stub(id: flightID, passengerID: PassengerID("PAX-001"))

        let flightRepository = FlightRepositorySpy()
        await flightRepository.stub(flights: [flight])
        let weatherRepository = WeatherRepositorySpy()
        await weatherRepository.stubError(forFlightID: flightID)

        let sut = GetFlightDetailUseCase(
            flightRepository: flightRepository,
            weatherRepository: weatherRepository
        )

        let detail = try await sut.execute(flightID: flightID)

        #expect(detail.flight.id == flightID)
        #expect(detail.weather == nil)
    }
}
