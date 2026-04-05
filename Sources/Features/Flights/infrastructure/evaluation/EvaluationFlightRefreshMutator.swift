import SharedKernel

struct EvaluationFlightRefreshMutator {
    private let targetFlightID: FlightID

    init(targetFlightID: FlightID) {
        self.targetFlightID = targetFlightID
    }

    func applyRefresh(
        to flights: [Flight],
        for id: FlightID,
        didApplyMutation: Bool
    ) -> (flights: [Flight], didApplyMutation: Bool) {
        guard didApplyMutation == false else {
            return (flights, true)
        }
        guard id == targetFlightID,
              let index = flights.firstIndex(where: { $0.id == targetFlightID })
        else {
            return (flights, false)
        }
        var refreshedFlights = flights
        let current = refreshedFlights[index]
        refreshedFlights[index] = Flight(
            id: current.id,
            passengerID: current.passengerID,
            number: current.number,
            origin: current.origin,
            destination: current.destination,
            status: .delayed,
            scheduledDeparture: current.scheduledDeparture,
            departureTimeZoneIdentifier: current.departureTimeZoneIdentifier,
            gate: current.gate
        )
        return (refreshedFlights, true)
    }
}
