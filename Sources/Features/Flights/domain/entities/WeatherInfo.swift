import Foundation

public struct WeatherInfo: Sendable, Equatable {
    public let description: String
    public let temperatureCelsius: Int

    public init(description: String, temperatureCelsius: Int) {
        self.description = description
        self.temperatureCelsius = temperatureCelsius
    }
}
