import SharedKernel

struct FlightPageProjector: Sendable {
    func page(
        flights: [Flight],
        passengerID: PassengerID,
        page: Int,
        pageSize: Int,
        source: FlightDataSource,
        isStale: Bool
    ) -> FlightListResult {
        let filteredFlights = flights
            .filter { $0.passengerID == passengerID }
            .sorted { $0.scheduledDeparture < $1.scheduledDeparture }
        let safePage = max(page, 1)
        let safePageSize = max(pageSize, 1)
        let startIndex = (safePage - 1) * safePageSize
        guard startIndex < filteredFlights.count else {
            return FlightListResult(
                flights: [],
                source: source,
                isStale: isStale,
                page: safePage,
                hasMorePages: false
            )
        }
        let endIndex = min(startIndex + safePageSize, filteredFlights.count)
        return FlightListResult(
            flights: Array(filteredFlights[startIndex..<endIndex]),
            source: source,
            isStale: isStale,
            page: safePage,
            hasMorePages: endIndex < filteredFlights.count
        )
    }
}
