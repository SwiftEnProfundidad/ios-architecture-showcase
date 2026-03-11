import BoardingPassFeature
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

extension BoardingPassData {
    static func stub(
        flightID: FlightID,
        passengerID: PassengerID,
        boardingTimeZoneIdentifier: String = "Europe/Madrid"
    ) -> BoardingPassData {
        BoardingPassData(
            flightID: flightID,
            passengerID: passengerID,
            passengerName: "Carlos Iberia",
            seat: "12A",
            gate: "B7",
            boardingDeadline: fixedDate(hour: 9, minute: 45),
            boardingTimeZoneIdentifier: boardingTimeZoneIdentifier,
            qrPayload: "\(flightID.value)-\(passengerID.value)"
        )
    }
}

func fixedDate(hour: Int, minute: Int) -> Date {
    Calendar(identifier: .gregorian).date(
        from: DateComponents(
            timeZone: TimeZone(secondsFromGMT: 0),
            year: 2030,
            month: 3,
            day: 10,
            hour: hour,
            minute: minute
        )
    ) ?? .now
}
