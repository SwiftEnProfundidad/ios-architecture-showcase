import SharedKernel

public struct Flight: Sendable, Equatable, Identifiable {
    public enum Status: String, Sendable, Equatable {
        case onTime = "En hora"
        case delayed = "Retrasado"
        case boarding = "Embarcando"
        case departed = "Despegado"
        case cancelled = "Cancelado"
    }

    public let id: FlightID
    public let passengerID: PassengerID
    public let number: String
    public let origin: String
    public let destination: String
    public let status: Status
    public let scheduledDeparture: String
    public let gate: String

    public init(
        id: FlightID,
        passengerID: PassengerID,
        number: String,
        origin: String,
        destination: String,
        status: Status,
        scheduledDeparture: String,
        gate: String
    ) {
        self.id = id
        self.passengerID = passengerID
        self.number = number
        self.origin = origin
        self.destination = destination
        self.status = status
        self.scheduledDeparture = scheduledDeparture
        self.gate = gate
    }
}

public extension Flight {
    static func stub(id: FlightID, passengerID: PassengerID) -> Flight {
        Flight(
            id: id,
            passengerID: passengerID,
            number: id.value,
            origin: "MAD",
            destination: "BCN",
            status: .onTime,
            scheduledDeparture: "10:30",
            gate: "A12"
        )
    }
}
