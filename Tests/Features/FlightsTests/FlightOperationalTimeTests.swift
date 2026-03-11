import FlightsFeature
import Foundation
import SharedKernel
import Testing

@Suite("FlightOperationalTime")
struct FlightOperationalTimeTests {

    @Test("Flight departure time is formatted in the operational airport timezone")
    func flightDepartureUsesOperationalTimezone() {
        let flight = Flight.stub(
            id: FlightID("IB3456"),
            passengerID: PassengerID("PAX-001"),
            scheduledDeparture: fixedDate(hour: 10, minute: 30),
            departureTimeZoneIdentifier: "Europe/Madrid"
        )

        let renderedTime = flight.formattedScheduledDeparture(locale: Locale(identifier: "en_GB"))

        #expect(renderedTime == "11:30")
    }
}
