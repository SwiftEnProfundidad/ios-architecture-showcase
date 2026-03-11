import FlightsFeature
import SharedKernel
import Testing

@Suite("CatalogWeatherRepository")
struct CatalogWeatherRepositoryTests {
    @Test("Weather repository returns weather for an existing flight")
    func fetchesWeather() async throws {
        let repository = CatalogWeatherRepository()

        let weather = try await repository.fetchWeather(forFlightID: FlightID("IB3456"))

        #expect(weather.description.isEmpty == false)
    }

    @Test("Weather repository throws not found for an unknown flight")
    func throwsWhenMissing() async {
        let repository = CatalogWeatherRepository()

        await #expect(throws: FlightError.notFound) {
            try await repository.fetchWeather(forFlightID: FlightID("IB9999"))
        }
    }
}
