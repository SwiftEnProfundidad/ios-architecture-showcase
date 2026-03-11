import SharedKernel

public protocol FlightDetailGetting: Sendable {
    func execute(flightID: FlightID) async throws -> FlightDetail
}

public struct GetFlightDetailUseCase<
    FlightRepo: FlightDetailReading,
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
        async let weather = fetchWeatherIgnoringRecoverableFailure(flightID: flightID)
        return FlightDetail(flight: try await flight, weather: try await weather)
    }

    private func fetchWeatherIgnoringRecoverableFailure(flightID: FlightID) async throws -> WeatherInfo? {
        do {
            return try await weatherRepository.fetchWeather(forFlightID: flightID)
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            return nil
        }
    }
}

extension GetFlightDetailUseCase: FlightDetailGetting {}
