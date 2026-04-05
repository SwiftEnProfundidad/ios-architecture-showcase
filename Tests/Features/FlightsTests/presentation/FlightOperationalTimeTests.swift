import FlightsFeature
import Foundation
import SharedKernel
import Testing

@Suite("FlightOperationalTime")
struct FlightOperationalTimeTests {

    @Test("Given a flight timestamp and operational airport timezone, when departure time is formatted, then the string uses that timezone")
    func flightDepartureUsesOperationalTimezone() {
        let flight = Flight.stub(
            id: FlightID("IB3456"),
            passengerID: PassengerID("PAX-001"),
            scheduledDeparture: fixedDate(hour: 10, minute: 30),
            departureTimeZoneIdentifier: "Europe/Madrid"
        )

        let renderedTime = OperationalTimeFormatter.hourMinute(
            from: flight.scheduledDeparture,
            timeZoneIdentifier: flight.departureTimeZoneIdentifier,
            locale: Locale(identifier: "en_GB")
        )

        #expect(renderedTime == "11:30")
    }
}
