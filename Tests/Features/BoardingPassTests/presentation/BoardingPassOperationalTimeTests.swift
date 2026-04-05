import BoardingPassFeature
import Foundation
import SharedKernel
import Testing

@Suite("BoardingPassOperationalTime")
struct BoardingPassOperationalTimeTests {

    @Test("Given a boarding deadline and operational airport timezone, when formatted, then the string uses that timezone")
    func boardingDeadlineUsesOperationalTimezone() {
        let boardingPass = BoardingPassData.stub(
            flightID: FlightID("IB3456"),
            passengerID: PassengerID("PAX-001"),
            boardingTimeZoneIdentifier: "Europe/London"
        )

        let renderedTime = OperationalTimeFormatter.hourMinute(
            from: boardingPass.boardingDeadline,
            timeZoneIdentifier: boardingPass.boardingTimeZoneIdentifier,
            locale: Locale(identifier: "en_GB")
        )

        #expect(renderedTime == "09:45")
    }
}
