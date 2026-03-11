import SharedKernel

struct CatalogFlightRepositoryState: Sendable {
    private var catalogSnapshot: [Flight]?
    private var didApplyRefreshMutation = false

    mutating func loadCatalogFlights(using dataSource: CatalogFlightDataSource) throws -> [Flight] {
        if let catalogSnapshot {
            return catalogSnapshot
        }
        let flights = try dataSource.loadFlights()
        catalogSnapshot = flights
        return flights
    }

    mutating func refreshFlights(
        for id: FlightID,
        using dataSource: CatalogFlightDataSource,
        refreshMutator: EvaluationFlightRefreshMutator
    ) throws -> [Flight] {
        let catalogFlights = try loadCatalogFlights(using: dataSource)
        let refreshResult = refreshMutator.applyRefresh(
            to: catalogFlights,
            for: id,
            didApplyMutation: didApplyRefreshMutation
        )
        didApplyRefreshMutation = refreshResult.didApplyMutation
        catalogSnapshot = refreshResult.flights
        return refreshResult.flights
    }
}
