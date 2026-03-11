import Foundation
import OSLog
import SharedKernel

public actor CatalogFlightRepository: FlightRepositoryProtocol {
    private let logger = Logger(subsystem: "com.swiftenprofundidad.iOSArchitectureShowcase", category: "flights.repository")
    private let dataSource: CatalogFlightDataSource
    private let cacheStore: FlightCacheStore
    private let refreshMutator: EvaluationFlightRefreshMutator
    private let pageProjector = FlightPageProjector()
    private var state = CatalogFlightRepositoryState()

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
            let flights = try state.loadCatalogFlights(using: dataSource)
            persistCacheIfPossible(flights)
            return pageProjector.page(
                flights: flights,
                passengerID: passengerID,
                page: page,
                pageSize: pageSize,
                source: .remote,
                isStale: false
            )
        } catch {
            let cachedFlights = try loadCachedFlights()
            let result = pageProjector.page(
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
            let flights = try state.loadCatalogFlights(using: dataSource)
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
        let flights = try state.refreshFlights(
            for: id,
            using: dataSource,
            refreshMutator: refreshMutator
        )
        persistCacheIfPossible(flights)
        guard let refreshedFlight = flights.first(where: { $0.id == id }) else {
            logger.error("Refresh failed because flight \(id.value, privacy: .public) does not exist")
            throw FlightError.notFound
        }
        return refreshedFlight
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
}
