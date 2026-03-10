import SharedKernel

public struct GetFlightDetailUseCase<
    FlightRepo: FlightRepositoryProtocol,
    WeatherRepo: WeatherRepositoryProtocol
>: Sendable {
    private let flightRepository: FlightRepo
    private let weatherRepository: WeatherRepo

    public init(flightRepository: FlightRepo, weatherRepository: WeatherRepo) {
        self.flightRepository = flightRepository
        self.weatherRepository = weatherRepository
    }

    public func execute(flightID: FlightID) async throws -> FlightDetail {
        async let flight = flightRepository.fetchByID(flightID)
        async let weather = fetchWeatherIgnoringFailure(flightID: flightID)
        return FlightDetail(flight: try await flight, weather: await weather)
    }

    private func fetchWeatherIgnoringFailure(flightID: FlightID) async -> WeatherInfo? {
        try? await weatherRepository.fetchWeather(forFlightID: flightID)
    }
}
