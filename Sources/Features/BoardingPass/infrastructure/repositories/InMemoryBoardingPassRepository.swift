import SharedKernel

public struct InMemoryBoardingPassRepository: BoardingPassRepositoryProtocol {
    public init() {}

    public func fetch(forFlightID flightID: FlightID) async throws -> BoardingPassData {
        try await Task.sleep(nanoseconds: 150_000_000)
        return BoardingPassData(
            flightID: flightID,
            passengerID: PassengerID("PAX-001"),
            passengerName: "Juan Carlos Merlos Albarracín",
            seat: "12A",
            gate: "B7",
            boardingDeadline: "09:45",
            qrPayload: "\(flightID.value)-PAX001-IBERIA"
        )
    }
}
