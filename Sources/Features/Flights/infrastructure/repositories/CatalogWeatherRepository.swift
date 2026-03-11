import Foundation
import OSLog
import SharedKernel

public struct CatalogWeatherRepository: WeatherRepositoryProtocol {
    private let logger = Logger(subsystem: "com.swiftenprofundidad.iOSArchitectureShowcase", category: "weather.repository")
    private let bundle: Bundle
    private let decoder = JSONDecoder()

    public init() {
        self.bundle = .module
    }

    public func fetchWeather(forFlightID flightID: FlightID) async throws -> WeatherInfo {
        try await Task.sleep(nanoseconds: 150_000_000)
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
