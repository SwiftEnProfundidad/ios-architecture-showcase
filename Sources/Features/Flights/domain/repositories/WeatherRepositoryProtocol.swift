import SharedKernel

public protocol WeatherRepositoryProtocol: Sendable {
    func fetchWeather(forFlightID flightID: FlightID) async throws -> WeatherInfo
}
