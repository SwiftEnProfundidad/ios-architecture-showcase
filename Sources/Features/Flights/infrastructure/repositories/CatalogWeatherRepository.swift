import Foundation
import OSLog
import SharedKernel

public struct CatalogWeatherRepository: WeatherRepositoryProtocol {
    public static let defaultSimulatedLatency: UInt64 = 150_000_000
    private let logger = Logger(subsystem: LoggerSubsystem.app, category: "weather.repository")
    private let bundle: Bundle
    private let decoder = JSONDecoder()
    private let simulatedLatencyNanoseconds: UInt64

    public init(simulatedLatencyNanoseconds: UInt64 = defaultSimulatedLatency) {
        self.bundle = .module
        self.simulatedLatencyNanoseconds = simulatedLatencyNanoseconds
    }

    public func fetchWeather(forFlightID flightID: FlightID) async throws -> WeatherInfo {
        try await Task.sleep(nanoseconds: simulatedLatencyNanoseconds)
        guard let url = bundle.url(forResource: "weather-catalog", withExtension: "json") else {
            logger.error("Weather catalog is not available")
            throw FlightError.network
        }
        let data = try Data(contentsOf: url)
        let records = try decoder.decode([WeatherRecord].self, from: data)
        guard let record = records.first(where: { $0.flightID == flightID.value }) else {
            logger.error("Weather not found for flight \(flightID.value, privacy: .public)")
            throw FlightError.notFound
        }
        return WeatherInfo(description: record.description, temperatureCelsius: record.temperatureCelsius)
    }
}

private struct WeatherRecord: Codable {
    let flightID: String
    let description: String
    let temperatureCelsius: Int
}
