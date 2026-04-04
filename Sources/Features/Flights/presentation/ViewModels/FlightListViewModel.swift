import Observation
import Foundation
import SharedKernel
import SharedNavigation

@MainActor
@Observable
public final class FlightListViewModel<
    ListExecutor: ListFlightsExecuting,
    SessionController: FlightListSessionControlling,
    FeedbackClock: Clock<Duration>
> {
    public private(set) var flights: [Flight] = []
    public private(set) var isLoading = false
    public private(set) var isLoadingNextPage = false
    public private(set) var canLoadMorePages = false
    public private(set) var errorMessage: String?
    public private(set) var staleMessage: String?
    public var isShowingInitialSkeleton: Bool {
        screenState.isShowingInitialSkeleton
    }

    private let listUseCase: ListExecutor
    private let sessionController: SessionController
    private let eventBus: NavigationEventPublishing
    private let passengerID: PassengerID
    private let clock: FeedbackClock
    private let loadingFeedbackPolicy: FlightListLoadingFeedbackPolicy
    private var screenState = FlightListScreenState()

    public init(
        listUseCase: ListExecutor,
        sessionController: SessionController,
        eventBus: NavigationEventPublishing,
        passengerID: PassengerID,
        clock: FeedbackClock,
        minimumInitialSkeletonNanoseconds: UInt64 = 0,
        minimumNextPageSpinnerNanoseconds: UInt64 = 0
    ) {
        self.listUseCase = listUseCase
        self.sessionController = sessionController
        self.eventBus = eventBus
        self.passengerID = passengerID
        self.clock = clock
        self.loadingFeedbackPolicy = FlightListLoadingFeedbackPolicy(
            minimumInitialSkeletonNanoseconds: minimumInitialSkeletonNanoseconds,
            minimumNextPageSpinnerNanoseconds: minimumNextPageSpinnerNanoseconds
        )
    }

    public func load() async {
        await loadPage(1, reset: true)
    }

    public func loadNextPage() async {
        await loadPage(screenState.nextPage, reset: false)
    }

    public func refresh() async {
        guard !isLoading else { return }
        guard !isLoadingNextPage else { return }
        guard await sessionController.ensureActiveSession() else { return }
        guard flights.isEmpty == false else {
            await load()
            return
        }
        let previousStaleMessage = screenState.beginRefresh()
        syncPublishedState()
        defer {
            screenState.finishRefresh()
            syncPublishedState()
        }
        do {
            let refreshedFlights = try await listUseCase.refreshAll(flightIDs: flights.map(\.id))
            guard await sessionController.ensureActiveSession() else { return }
            screenState.applyRefresh(refreshedFlights)
            syncPublishedState()
        } catch is CancellationError {
            screenState.restoreStaleMessage(previousStaleMessage)
            syncPublishedState()
            return
        } catch {
            screenState.restoreStaleMessage(previousStaleMessage)
            screenState.applyLoadFailure()
            syncPublishedState()
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
            guard screenState.beginInitialLoad() else { return }
        } else {
            guard screenState.beginNextPageLoad() else { return }
        }
        syncPublishedState()
        defer {
            screenState.finishLoad(reset: reset)
            syncPublishedState()
        }
        let loadStartedAt = clock.now
        do {
            let result = try await listUseCase.execute(passengerID: passengerID, page: page)
            try await loadingFeedbackPolicy.awaitMinimumFeedback(
                isInitialPresentation: isInitialPresentation,
                isNextPageLoad: reset == false,
                clock: clock,
                loadStartedAt: loadStartedAt
            )
            guard await sessionController.ensureActiveSession() else { return }
            screenState.applyPage(result, reset: reset)
            syncPublishedState()
        } catch is CancellationError {
            return
        } catch {
            if isInitialPresentation {
                do {
                    try await loadingFeedbackPolicy.awaitMinimumFeedback(
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
            screenState.applyLoadFailure()
            syncPublishedState()
        }
    }

    private func syncPublishedState() {
        flights = screenState.flights
        isLoading = screenState.isLoading
        isLoadingNextPage = screenState.isLoadingNextPage
        canLoadMorePages = screenState.canLoadMorePages
        errorMessage = screenState.errorMessage
        staleMessage = screenState.staleMessage
    }
}

extension FlightListViewModel where FeedbackClock == ContinuousClock {
    public convenience init(
        listUseCase: ListExecutor,
        sessionController: SessionController,
        eventBus: NavigationEventPublishing,
        passengerID: PassengerID,
        minimumInitialSkeletonNanoseconds: UInt64 = 0,
        minimumNextPageSpinnerNanoseconds: UInt64 = 0
    ) {
        self.init(
            listUseCase: listUseCase,
            sessionController: sessionController,
            eventBus: eventBus,
            passengerID: passengerID,
            clock: ContinuousClock(),
            minimumInitialSkeletonNanoseconds: minimumInitialSkeletonNanoseconds,
            minimumNextPageSpinnerNanoseconds: minimumNextPageSpinnerNanoseconds
        )
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
            clock: ContinuousClock(),
            minimumInitialSkeletonNanoseconds: minimumInitialSkeletonNanoseconds,
            minimumNextPageSpinnerNanoseconds: minimumNextPageSpinnerNanoseconds
        )
    }
}
