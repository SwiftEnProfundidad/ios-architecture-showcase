import Foundation
import OSLog
import SharedKernel

public actor CatalogFlightRepository: FlightRepositoryProtocol {
    private let logger = Logger(subsystem: "com.swiftenprofundidad.iOSArchitectureShowcase", category: "flights.repository")
    private let dataSource: CatalogFlightDataSource
    private let cacheStore: FlightCacheStore
    private let refreshMutator: EvaluationFlightRefreshMutator
    private var catalogSnapshot: [Flight]?
    private var didApplyRefreshMutation = false

    public init(
        fileManager: FileManager = .default,
        cacheDirectoryURL: URL? = nil
    ) {
        let cacheDirectory = cacheDirectoryURL ?? {
            let appSupportURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first ?? fileManager.temporaryDirectory
            return appSupportURL
                .appendingPathComponent("iOSArchitectureShowcase", isDirectory: true)
                .appendingPathComponent("Flights", isDirectory: true)
        }()
        self.dataSource = CatalogFlightDataSource(bundle: .module)
        self.cacheStore = FlightCacheStore(
            fileManager: fileManager,
            cacheURL: cacheDirectory.appendingPathComponent("flight-cache.json", isDirectory: false)
        )
        self.refreshMutator = EvaluationFlightRefreshMutator()
    }

    public func fetchPage(passengerID: PassengerID, page: Int, pageSize: Int) async throws -> FlightListResult {
        do {
            let flights = try loadCatalogFlights()
            persistCacheIfPossible(flights)
            return pagedResult(
                flights: flights,
                passengerID: passengerID,
                page: page,
                pageSize: pageSize,
                source: .remote,
                isStale: false
            )
        } catch {
            let cachedFlights = try loadCachedFlights()
            let result = pagedResult(
                flights: cachedFlights,
                passengerID: passengerID,
                page: page,
                pageSize: pageSize,
                source: .cache,
                isStale: true
            )
            guard result.flights.isEmpty == false else {
                logger.error("Remote catalog unavailable and no cached flights for passenger \(passengerID.value, privacy: .public)")
                throw FlightError.network
            }
            return result
        }
    }

    public func fetchByID(_ id: FlightID) async throws -> Flight {
        do {
            let flights = try loadCatalogFlights()
            persistCacheIfPossible(flights)
            guard let flight = flights.first(where: { $0.id == id }) else {
                logger.error("Flight detail not found for \(id.value, privacy: .public)")
                throw FlightError.notFound
            }
            return flight
        } catch let error as FlightError {
            throw error
        } catch {
            let cachedFlights = try loadCachedFlights()
            if let flight = cachedFlights.first(where: { $0.id == id }) {
                return flight
            }
            logger.error("Flight detail unavailable for \(id.value, privacy: .public)")
            throw FlightError.network
        }
    }

    public func refresh(_ id: FlightID) async throws -> Flight {
        let catalogFlights = try loadCatalogFlights()
        let refreshResult = refreshMutator.applyRefresh(
            to: catalogFlights,
            for: id,
            didApplyMutation: didApplyRefreshMutation
        )
        let flights = refreshResult.flights
        didApplyRefreshMutation = refreshResult.didApplyMutation
        catalogSnapshot = flights
        persistCacheIfPossible(flights)
        guard let refreshedFlight = flights.first(where: { $0.id == id }) else {
            logger.error("Refresh failed because flight \(id.value, privacy: .public) does not exist")
            throw FlightError.notFound
        }
        return refreshedFlight
    }

    private func loadCatalogFlights() throws -> [Flight] {
        if let catalogSnapshot {
            return catalogSnapshot
        }
        let flights = try dataSource.loadFlights()
        catalogSnapshot = flights
        return flights
    }

    private func loadCachedFlights() throws -> [Flight] {
        try cacheStore.loadFlights()
    }

    private func persistCacheIfPossible(_ flights: [Flight]) {
        do {
            try cacheStore.persist(flights)
        } catch {
            logger.error("Failed to persist local flight cache")
        }
    }

    private func pagedResult(
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
