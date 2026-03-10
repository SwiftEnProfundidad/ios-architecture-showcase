@testable import iOSArchitectureShowcase

actor WeatherRepositorySpy: WeatherRepositoryProtocol {
    private var stubbedWeather: [FlightID: WeatherInfo] = [:]
    private var failingFlightIDs: Set<FlightID> = []

    func stub(weather: WeatherInfo, forFlightID flightID: FlightID) {
        stubbedWeather[flightID] = weather
    }

    func stubError(forFlightID flightID: FlightID) {
        failingFlightIDs.insert(flightID)
    }

    func fetchWeather(forFlightID flightID: FlightID) async throws -> WeatherInfo {
        if failingFlightIDs.contains(flightID) { throw FlightError.network }
        guard let weather = stubbedWeather[flightID] else { throw FlightError.notFound }
        return weather
    }
}
