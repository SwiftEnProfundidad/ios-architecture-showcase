import Observation
import Foundation
import SharedKernel
import SharedNavigation

@MainActor
@Observable
public final class FlightListViewModel<ListExecutor: ListFlightsExecuting, SessionController: FlightListSessionControlling> {
    public private(set) var flights: [Flight] = []
    public private(set) var isLoading = false
    public private(set) var isLoadingNextPage = false
    public private(set) var canLoadMorePages = false
    public private(set) var errorMessage: String?
    public private(set) var staleMessage: String?
    public var isShowingInitialSkeleton: Bool {
        isLoading && flights.isEmpty && errorMessage == nil
    }

    private let listUseCase: ListExecutor
    private let sessionController: SessionController
    private let eventBus: NavigationEventPublishing
    private let passengerID: PassengerID
    private let minimumInitialSkeletonNanoseconds: UInt64
    private let minimumNextPageSpinnerNanoseconds: UInt64
    private var nextPage = 1

    public init(
        listUseCase: ListExecutor,
        sessionController: SessionController,
        eventBus: NavigationEventPublishing,
        passengerID: PassengerID,
        minimumInitialSkeletonNanoseconds: UInt64 = 0,
        minimumNextPageSpinnerNanoseconds: UInt64 = 0
    ) {
        self.listUseCase = listUseCase
        self.sessionController = sessionController
        self.eventBus = eventBus
        self.passengerID = passengerID
        self.minimumInitialSkeletonNanoseconds = minimumInitialSkeletonNanoseconds
        self.minimumNextPageSpinnerNanoseconds = minimumNextPageSpinnerNanoseconds
    }

    public convenience init<LogoutExecutor: SessionEnding>(
        listUseCase: ListExecutor,
        logoutUseCase: LogoutExecutor,
        eventBus: NavigationEventPublishing,
        passengerID: PassengerID,
        sessionExpiresAt: Date,
        minimumInitialSkeletonNanoseconds: UInt64 = 0,
        minimumNextPageSpinnerNanoseconds: UInt64 = 0,
        currentDateProvider: @escaping () -> Date = { .now }
    ) where SessionController == FlightListSessionController<LogoutExecutor> {
        self.init(
            listUseCase: listUseCase,
            sessionController: FlightListSessionController(
                logoutUseCase: logoutUseCase,
                eventBus: eventBus,
                sessionExpiresAt: sessionExpiresAt,
                currentDateProvider: currentDateProvider
            ),
            eventBus: eventBus,
            passengerID: passengerID,
            minimumInitialSkeletonNanoseconds: minimumInitialSkeletonNanoseconds,
            minimumNextPageSpinnerNanoseconds: minimumNextPageSpinnerNanoseconds
        )
    }

    public func load() async {
        await loadPage(1, reset: true)
    }

    public func loadNextPage() async {
        await loadPage(nextPage, reset: false)
    }

    public func refresh() async {
        guard !isLoading else { return }
        guard !isLoadingNextPage else { return }
        guard await sessionController.ensureActiveSession() else { return }
        guard flights.isEmpty == false else {
            await load()
            return
        }
        let previousStaleMessage = staleMessage
        isLoading = true
        errorMessage = nil
        staleMessage = nil
        defer { isLoading = false }
        do {
            let refreshedFlights = try await listUseCase.refreshAll(flightIDs: flights.map(\.id))
            guard await sessionController.ensureActiveSession() else { return }
            flights = refreshedFlights
            staleMessage = nil
        } catch is CancellationError {
            staleMessage = previousStaleMessage
            return
        } catch {
            staleMessage = previousStaleMessage
            errorMessage = AppStrings.localized("flights.error.load")
        }
    }

    public func logout() async {
        guard !isLoading else { return }
        guard !isLoadingNextPage else { return }
        isLoading = true
        defer { isLoading = false }
        await sessionController.logoutUser()
    }

    public func selectFlight(_ flight: Flight) async {
        await eventBus.publish(
            .requestProtectedPath([.primaryDetail(contextID: flight.id.value)])
        )
    }

    private func loadPage(_ page: Int, reset: Bool) async {
        guard await sessionController.ensureActiveSession() else { return }
        let isInitialPresentation = reset && flights.isEmpty
        if reset {
            guard !isLoading else { return }
            isLoading = true
        } else {
            guard !isLoading else { return }
            guard !isLoadingNextPage else { return }
            guard canLoadMorePages else { return }
            isLoadingNextPage = true
        }
        defer {
            if reset {
                isLoading = false
            } else {
                isLoadingNextPage = false
            }
        }
        errorMessage = nil
        if reset {
            staleMessage = nil
        }
        let clock = ContinuousClock()
        let loadStartedAt = clock.now
        do {
            let result = try await listUseCase.execute(passengerID: passengerID, page: page)
            try await awaitMinimumLoadingFeedbackIfNeeded(
                isInitialPresentation: isInitialPresentation,
                isNextPageLoad: reset == false,
                clock: clock,
                loadStartedAt: loadStartedAt
            )
            guard await sessionController.ensureActiveSession() else { return }
            flights = reset ? result.flights : mergedFlights(existing: flights, incoming: result.flights)
            nextPage = result.page + 1
            canLoadMorePages = result.hasMorePages
            if result.isStale {
                staleMessage = AppStrings.localized("flights.list.staleWarning")
            } else if reset {
                staleMessage = nil
            }
        } catch is CancellationError {
            return
        } catch {
            if isInitialPresentation {
                do {
                    try await awaitMinimumLoadingFeedbackIfNeeded(
                        isInitialPresentation: true,
                        isNextPageLoad: false,
                        clock: clock,
                        loadStartedAt: loadStartedAt
                    )
                } catch is CancellationError {
                    return
                } catch {
                    return
                }
            }
            errorMessage = AppStrings.localized("flights.error.load")
        }
    }

    private func awaitMinimumLoadingFeedbackIfNeeded(
        isInitialPresentation: Bool,
        isNextPageLoad: Bool,
        clock: ContinuousClock,
        loadStartedAt: ContinuousClock.Instant
    ) async throws {
        let minimumNanoseconds: UInt64
        if isInitialPresentation {
            minimumNanoseconds = minimumInitialSkeletonNanoseconds
        } else if isNextPageLoad {
            minimumNanoseconds = minimumNextPageSpinnerNanoseconds
        } else {
            minimumNanoseconds = 0
        }
        guard minimumNanoseconds > 0 else { return }
        let minimumDuration = Duration.nanoseconds(Int64(minimumNanoseconds))
        let elapsed = loadStartedAt.duration(to: clock.now)
        guard elapsed < minimumDuration else { return }
        try await Task.sleep(for: minimumDuration - elapsed)
    }

    private func mergedFlights(existing: [Flight], incoming: [Flight]) -> [Flight] {
        var merged = existing
        for flight in incoming {
            if let index = merged.firstIndex(where: { $0.id == flight.id }) {
                merged[index] = flight
            } else {
                merged.append(flight)
            }
        }
        return merged
    }
}
