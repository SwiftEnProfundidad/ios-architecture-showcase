
public struct InMemoryWeatherRepository: WeatherRepositoryProtocol {
    public init() {}

    public func fetchWeather(forFlightID flightID: FlightID) async throws -> WeatherInfo {
        try await Task.sleep(nanoseconds: 150_000_000)
        return WeatherInfo(description: "Soleado", temperatureCelsius: 22)
    }
}
