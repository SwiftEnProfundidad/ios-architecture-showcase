import Foundation
import OSLog
import SharedKernel

public actor CatalogFlightRepository: FlightRepositoryProtocol {
    private let logger = Logger(subsystem: LoggerSubsystem.app, category: "flights.repository")
    private let dataSource: CatalogFlightDataSource
    private let cacheStore: FlightCacheStore
    private let refreshMutator: EvaluationFlightRefreshMutator
    private let pageProjector = FlightPageProjector()
    private var state = CatalogFlightRepositoryState()

    init(
        dataSource: CatalogFlightDataSource,
        cacheStore: FlightCacheStore,
        refreshMutator: EvaluationFlightRefreshMutator
    ) {
        self.dataSource = dataSource
        self.cacheStore = cacheStore
        self.refreshMutator = refreshMutator
    }

    public static func catalog(
        fileManager: FileManager = .default,
        cacheDirectoryURL: URL? = nil
    ) -> CatalogFlightRepository {
        let cacheDirectory = cacheDirectoryURL ?? {
            let appSupportURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first ?? fileManager.temporaryDirectory
            return appSupportURL
                .appendingPathComponent("iOSArchitectureShowcase", isDirectory: true)
                .appendingPathComponent("Flights", isDirectory: true)
        }()
        return CatalogFlightRepository(
            dataSource: CatalogFlightDataSource(bundle: .module),
            cacheStore: FlightCacheStore(
                fileManager: fileManager,
                cacheURL: cacheDirectory.appendingPathComponent("flight-cache.json", isDirectory: false)
            ),
            refreshMutator: EvaluationFlightRefreshMutator(targetFlightID: FlightID("IB3456"))
        )
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
            let cachedFlights: [Flight]
            do {
                cachedFlights = try loadCachedFlights()
            } catch {
                logger.error("Remote catalog unavailable and no cached flights for passenger \(passengerID.value, privacy: .public)")
                throw FlightError.network
            }
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
            let cachedFlights: [Flight]
            do {
                cachedFlights = try loadCachedFlights()
            } catch {
                logger.error("Flight detail unavailable for \(id.value, privacy: .public)")
                throw FlightError.network
            }
            guard let flight = cachedFlights.first(where: { $0.id == id }) else {
                logger.error("Flight detail unavailable for \(id.value, privacy: .public)")
                throw FlightError.network
            }
            return flight
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
