import Testing
@testable import Flights
@testable import SharedKernel

@Suite("GetFlightDetailUseCase")
struct GetFlightDetailUseCaseTests {

    @Test("Cuando carga detalle, flight y weather se cargan en paralelo con async let")
    func detailLoadsFlightAndWeatherConcurrently() async throws {
        let flightID = FlightID("IB3456")
        let flight = Flight.stub(id: flightID, passengerID: PassengerID("PAX-001"))
        let weather = WeatherInfo.stub(description: "Soleado", temperatureCelsius: 22)

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
        #expect(detail.weather?.description == "Soleado")
    }

    @Test("Cuando weather falla, el detalle se devuelve igualmente sin weather")
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
