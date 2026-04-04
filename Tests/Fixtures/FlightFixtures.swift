import FlightsFeature
import Foundation
import SharedKernel

extension Flight {
    static func stub(
        id: FlightID,
        passengerID: PassengerID,
        status: Status = .onTime,
        scheduledDeparture: Date = fixedDate(hour: 10, minute: 30),
        departureTimeZoneIdentifier: String = "Europe/Madrid"
    ) -> Flight {
        Flight(
            id: id,
            passengerID: passengerID,
            number: id.value,
            origin: "MAD",
            destination: "BCN",
            status: status,
            scheduledDeparture: scheduledDeparture,
            departureTimeZoneIdentifier: departureTimeZoneIdentifier,
            gate: "A12"
        )
    }
}

extension WeatherInfo {
    static func stub(description: String, temperatureCelsius: Int) -> WeatherInfo {
        WeatherInfo(description: description, temperatureCelsius: temperatureCelsius)
    }
}
