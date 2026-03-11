import BoardingPassFeature
import Foundation
import SharedKernel
import Testing

@Suite("BoardingPassOperationalTime")
struct BoardingPassOperationalTimeTests {

    @Test("Boarding deadline is formatted in the operational airport timezone")
    func boardingDeadlineUsesOperationalTimezone() {
        let sut = makeSUT(
            flightID: FlightID("IB3456"),
            passengerID: PassengerID("PAX-001"),
            boardingTimeZoneIdentifier: "Europe/London"
        )

        let renderedTime = sut.formattedBoardingDeadline(locale: Locale(identifier: "en_GB"))

        #expect(renderedTime == "09:45")
    }

    private func makeSUT(
        flightID: FlightID,
        passengerID: PassengerID,
        boardingTimeZoneIdentifier: String
    ) -> BoardingPassData {
        BoardingPassData.stub(
            flightID: flightID,
            passengerID: passengerID,
            boardingTimeZoneIdentifier: boardingTimeZoneIdentifier
        )
    }
}
