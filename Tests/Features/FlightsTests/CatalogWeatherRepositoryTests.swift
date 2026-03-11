import FlightsFeature
import SharedKernel
import Testing

@Suite("CatalogWeatherRepository")
struct CatalogWeatherRepositoryTests {
    @Test("Weather repository returns weather for an existing flight")
    func fetchesWeather() async throws {
        let tracked = makeSUT()
        defer { tracked.assertNoLeaks() }
        let context = tracked.context

        let weather = try await context.sut.fetchWeather(forFlightID: FlightID("IB3456"))

        #expect(weather.description.isEmpty == false)
    }

    @Test("Weather repository throws not found for an unknown flight")
    func throwsWhenMissing() async {
        let tracked = makeSUT()
        defer { tracked.assertNoLeaks() }
        let context = tracked.context

        await #expect(throws: FlightError.notFound) {
            try await context.sut.fetchWeather(forFlightID: FlightID("IB9999"))
        }
    }

    private func makeSUT(
    ) -> TrackedTestContext<CatalogWeatherRepositoryTestContext> {
        let sut = CatalogWeatherRepository()
        return makeTestContext(
            CatalogWeatherRepositoryTestContext(sut: sut),
        )
    }
}

private struct CatalogWeatherRepositoryTestContext {
    let sut: CatalogWeatherRepository
}
