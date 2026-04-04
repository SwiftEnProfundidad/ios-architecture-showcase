import BoardingPassFeature
import SharedKernel

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
