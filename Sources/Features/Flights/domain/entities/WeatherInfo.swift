public struct WeatherInfo: Sendable, Equatable {
    public let description: String
    public let temperatureCelsius: Int

    public init(description: String, temperatureCelsius: Int) {
        self.description = description
        self.temperatureCelsius = temperatureCelsius
    }
}

public extension WeatherInfo {
    static func stub(description: String, temperatureCelsius: Int) -> WeatherInfo {
        WeatherInfo(description: description, temperatureCelsius: temperatureCelsius)
    }
}
