import Foundation
import SharedKernel

public struct BoardingPassData: Sendable, Equatable {
    public let flightID: FlightID
    public let passengerID: PassengerID
    public let passengerName: String
    public let seat: String
    public let gate: String
    public let boardingDeadline: Date
    public let boardingTimeZoneIdentifier: String
    public let qrPayload: String

    public init(
        flightID: FlightID,
        passengerID: PassengerID,
        passengerName: String,
        seat: String,
        gate: String,
        boardingDeadline: Date,
        boardingTimeZoneIdentifier: String,
        qrPayload: String
    ) {
        self.flightID = flightID
        self.passengerID = passengerID
        self.passengerName = passengerName
        self.seat = seat
        self.gate = gate
        self.boardingDeadline = boardingDeadline
        self.boardingTimeZoneIdentifier = boardingTimeZoneIdentifier
        self.qrPayload = qrPayload
    }
}
