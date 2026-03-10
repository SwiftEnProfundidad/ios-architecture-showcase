import SharedKernel

public struct BoardingPassData: Sendable, Equatable {
    public let flightID: FlightID
    public let passengerID: PassengerID
    public let passengerName: String
    public let seat: String
    public let gate: String
    public let boardingDeadline: String
    public let qrPayload: String

    public init(
        flightID: FlightID,
        passengerID: PassengerID,
        passengerName: String,
        seat: String,
        gate: String,
        boardingDeadline: String,
        qrPayload: String
    ) {
        self.flightID = flightID
        self.passengerID = passengerID
        self.passengerName = passengerName
        self.seat = seat
        self.gate = gate
        self.boardingDeadline = boardingDeadline
        self.qrPayload = qrPayload
    }
}

public extension BoardingPassData {
    static func stub(flightID: FlightID, passengerID: PassengerID) -> BoardingPassData {
        BoardingPassData(
            flightID: flightID,
            passengerID: passengerID,
            passengerName: "Carlos Merlos",
            seat: "12A",
            gate: "B7",
            boardingDeadline: "09:45",
            qrPayload: "\(flightID.value)-\(passengerID.value)"
        )
    }
}
