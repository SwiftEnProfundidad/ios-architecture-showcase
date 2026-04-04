import FlightsFeature
import SharedKernel
import Testing

@Suite("CatalogWeatherRepository")
struct CatalogWeatherRepositoryTests {
    @Test("Given a flight that exists in the catalog, when weather is fetched, then weather is returned")
    func fetchesWeather() async throws {
        let tracked = makeCatalogWeatherRepositorySUT()
        defer { tracked.assertNoLeaks() }
        let context = tracked.context

        let weather = try await context.sut.fetchWeather(forFlightID: FlightID("IB3456"))

        #expect(weather.description.isEmpty == false)
    }

    @Test("Given an unknown flight id, when weather is fetched, then not found is thrown")
    func throwsWhenMissing() async {
        let tracked = makeCatalogWeatherRepositorySUT()
        defer { tracked.assertNoLeaks() }
        let context = tracked.context

        await #expect(throws: FlightError.notFound) {
            try await context.sut.fetchWeather(forFlightID: FlightID("IB9999"))
        }
    }
}
