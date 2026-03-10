public struct FlightDetail: Sendable, Equatable {
    public let flight: Flight
    public let weather: WeatherInfo?

    public init(flight: Flight, weather: WeatherInfo?) {
        self.flight = flight
        self.weather = weather
    }
}
