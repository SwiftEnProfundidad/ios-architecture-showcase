import FlightsFeature
import Foundation
import SharedKernel
import SharedNavigation
import Testing

let defaultFlightListPassengerID = PassengerID("PAX-001")

@MainActor
struct ControlledFlightListViewModelTestContext<ListUseCase: ListFlightsExecuting, FeedbackClock: Clock<Duration>> {
    let sut: FlightListViewModel<ListUseCase, FlightListSessionControllerSpy, FeedbackClock>
    let listUseCase: ListUseCase
    let sessionController: FlightListSessionControllerSpy
    let eventBus: NavigationEventBusSpy
}

@MainActor
struct SessionBoundFlightListViewModelTestContext<
    ListUseCase: ListFlightsExecuting,
    LogoutUseCase: SessionEnding,
    FeedbackClock: Clock<Duration>
> {
    let sut: FlightListViewModel<ListUseCase, FlightListSessionController<LogoutUseCase>, FeedbackClock>
    let listUseCase: ListUseCase
    let logoutUseCase: LogoutUseCase
    let eventBus: NavigationEventBusSpy
}

@MainActor
func makeControlledFlightListViewModelSUT<ListUseCase: ListFlightsExecuting>(
    listUseCase: ListUseCase,
    sessionController: FlightListSessionControllerSpy = FlightListSessionControllerSpy(),
    eventBus: NavigationEventBusSpy = NavigationEventBusSpy(),
    passengerID: PassengerID = defaultFlightListPassengerID,
    minimumInitialSkeletonNanoseconds: UInt64 = 0,
    minimumNextPageSpinnerNanoseconds: UInt64 = 0,
    sourceLocation: SourceLocation = #_sourceLocation
) -> TrackedTestContext<ControlledFlightListViewModelTestContext<ListUseCase, ContinuousClock>> {
    let sut = FlightListViewModel(
        listUseCase: listUseCase,
        sessionController: sessionController,
        eventBus: eventBus,
        passengerID: passengerID,
        minimumInitialSkeletonNanoseconds: minimumInitialSkeletonNanoseconds,
        minimumNextPageSpinnerNanoseconds: minimumNextPageSpinnerNanoseconds
    )
    return makeLeakTrackedTestContext(
        ControlledFlightListViewModelTestContext(
            sut: sut,
            listUseCase: listUseCase,
            sessionController: sessionController,
            eventBus: eventBus
        ),
        trackedInstances: [sessionController, eventBus, sut],
        sourceLocation: sourceLocation
    )
}

@MainActor
func makeSessionBoundFlightListViewModelSUT<ListUseCase: ListFlightsExecuting, LogoutUseCase: SessionEnding>(
    listUseCase: ListUseCase,
    logoutUseCase: LogoutUseCase,
    eventBus: NavigationEventBusSpy = NavigationEventBusSpy(),
    passengerID: PassengerID = defaultFlightListPassengerID,
    sessionExpiresAt: Date,
    minimumInitialSkeletonNanoseconds: UInt64 = 0,
    minimumNextPageSpinnerNanoseconds: UInt64 = 0,
    currentDateProvider: @escaping () -> Date = { .now },
    sourceLocation: SourceLocation = #_sourceLocation
) -> TrackedTestContext<SessionBoundFlightListViewModelTestContext<ListUseCase, LogoutUseCase, ContinuousClock>> {
    let sut = FlightListViewModel(
        listUseCase: listUseCase,
        logoutUseCase: logoutUseCase,
        eventBus: eventBus,
        passengerID: passengerID,
        sessionExpiresAt: sessionExpiresAt,
        minimumInitialSkeletonNanoseconds: minimumInitialSkeletonNanoseconds,
        minimumNextPageSpinnerNanoseconds: minimumNextPageSpinnerNanoseconds,
        currentDateProvider: currentDateProvider
    )
    return makeLeakTrackedTestContext(
        SessionBoundFlightListViewModelTestContext(
            sut: sut,
            listUseCase: listUseCase,
            logoutUseCase: logoutUseCase,
            eventBus: eventBus
        ),
        trackedInstances: [eventBus, sut],
        sourceLocation: sourceLocation
    )
}

@MainActor
func makeConfiguredSessionBoundFlightListViewModelSUT(
    passengerID: PassengerID = defaultFlightListPassengerID,
    sessionExpiresAt: Date = .distantFuture,
    minimumInitialSkeletonNanoseconds: UInt64 = 0,
    minimumNextPageSpinnerNanoseconds: UInt64 = 0,
    currentDateProvider: @escaping () -> Date = { .now },
    sourceLocation: SourceLocation = #_sourceLocation,
    configure: (ListFlightsUseCaseSpy) async -> Void
) async -> TrackedTestContext<SessionBoundFlightListViewModelTestContext<ListFlightsUseCaseSpy, SessionEndingSpy, ContinuousClock>> {
    let listUseCase = ListFlightsUseCaseSpy()
    await configure(listUseCase)
    return makeSessionBoundFlightListViewModelSUT(
        listUseCase: listUseCase,
        logoutUseCase: SessionEndingSpy(),
        passengerID: passengerID,
        sessionExpiresAt: sessionExpiresAt,
        minimumInitialSkeletonNanoseconds: minimumInitialSkeletonNanoseconds,
        minimumNextPageSpinnerNanoseconds: minimumNextPageSpinnerNanoseconds,
        currentDateProvider: currentDateProvider,
        sourceLocation: sourceLocation
    )
}

struct FlightListFailure: Error {}

func makeFlights(range: ClosedRange<Int>, passengerID: PassengerID) -> [Flight] {
    range.map { index in
        Flight.stub(
            id: FlightID("IB\(1000 + index)"),
            passengerID: passengerID
        )
    }
}

func makeFlightIDs(range: ClosedRange<Int>) -> [String] {
    range.map { "IB\(1000 + $0)" }
}

func makePageResult(
    flightIDs: [String],
    passengerID: PassengerID,
    source: FlightDataSource,
    isStale: Bool,
    page: Int,
    hasMorePages: Bool
) -> FlightListResult {
    FlightListResult(
        flights: flightIDs.map { Flight.stub(id: FlightID($0), passengerID: passengerID) },
        source: source,
        isStale: isStale,
        page: page,
        hasMorePages: hasMorePages
    )
}

func makeRangePageResult(
    range: ClosedRange<Int>,
    passengerID: PassengerID,
    source: FlightDataSource,
    isStale: Bool,
    page: Int,
    hasMorePages: Bool
) -> FlightListResult {
    FlightListResult(
        flights: makeFlights(range: range, passengerID: passengerID),
        source: source,
        isStale: isStale,
        page: page,
        hasMorePages: hasMorePages
    )
}

func makeFlights(
    idsAndStatuses: [(String, Flight.Status)],
    passengerID: PassengerID
) -> [Flight] {
    idsAndStatuses.map { identifier, status in
        Flight.stub(id: FlightID(identifier), passengerID: passengerID, status: status)
    }
}

@MainActor
func makeStaleCacheFlightListLoadingSUT(
    passengerID: PassengerID = defaultFlightListPassengerID,
    sourceLocation: SourceLocation = #_sourceLocation
) async -> TrackedTestContext<SessionBoundFlightListViewModelTestContext<ListFlightsUseCaseSpy, SessionEndingSpy, ContinuousClock>> {
    await makeConfiguredSessionBoundFlightListViewModelSUT(
        passengerID: passengerID,
        sourceLocation: sourceLocation,
        configure: { listUseCase in
            await listUseCase.stubPage(
                result: makePageResult(
                    flightIDs: ["IB3456"],
                    passengerID: passengerID,
                    source: .cache,
                    isStale: true,
                    page: 1,
                    hasMorePages: false
                ),
                for: 1
            )
        }
    )
}

@MainActor
func makePendingFirstPageFlightListLoadingSUT(
    passengerID: PassengerID = defaultFlightListPassengerID,
    sourceLocation: SourceLocation = #_sourceLocation
) -> TrackedTestContext<SessionBoundFlightListViewModelTestContext<SlowListFlightsUseCaseSpy, SessionEndingSpy, ContinuousClock>> {
    makeSessionBoundFlightListViewModelSUT(
        listUseCase: SlowListFlightsUseCaseSpy(
            result: makePageResult(
                flightIDs: ["IB1001"],
                passengerID: passengerID,
                source: .remote,
                isStale: false,
                page: 1,
                hasMorePages: true
            )
        ),
        logoutUseCase: SessionEndingSpy(),
        passengerID: passengerID,
        sessionExpiresAt: .distantFuture,
        sourceLocation: sourceLocation
    )
}

@MainActor
func makeMinimumSkeletonFlightListLoadingSUT<C: Clock<Duration>>(
    clock: C,
    passengerID: PassengerID = defaultFlightListPassengerID,
    sourceLocation: SourceLocation = #_sourceLocation
) -> TrackedTestContext<SessionBoundFlightListViewModelTestContext<InstantListFlightsUseCaseSpy, SessionEndingSpy, C>> {
    let listUseCase = InstantListFlightsUseCaseSpy(
        result: makePageResult(
            flightIDs: ["IB1001"],
            passengerID: passengerID,
            source: .remote,
            isStale: false,
            page: 1,
            hasMorePages: true
        )
    )
    let logoutUseCase = SessionEndingSpy()
    let eventBus = NavigationEventBusSpy()
    let sut = FlightListViewModel(
        listUseCase: listUseCase,
        sessionController: FlightListSessionController(
            logoutUseCase: logoutUseCase,
            eventBus: eventBus,
            sessionExpiresAt: .distantFuture
        ),
        eventBus: eventBus,
        passengerID: passengerID,
        clock: clock,
        minimumInitialSkeletonNanoseconds: 250_000_000
    )
    return makeLeakTrackedTestContext(
        SessionBoundFlightListViewModelTestContext(
            sut: sut,
            listUseCase: listUseCase,
            logoutUseCase: logoutUseCase,
            eventBus: eventBus
        ),
        trackedInstances: [eventBus, sut],
        sourceLocation: sourceLocation
    )
}

@MainActor
func makeFirstPagePaginationFlightListLoadingSUT(
    passengerID: PassengerID = defaultFlightListPassengerID,
    sourceLocation: SourceLocation = #_sourceLocation
) async -> TrackedTestContext<SessionBoundFlightListViewModelTestContext<ListFlightsUseCaseSpy, SessionEndingSpy, ContinuousClock>> {
    await makeConfiguredSessionBoundFlightListViewModelSUT(
        passengerID: passengerID,
        sourceLocation: sourceLocation,
        configure: { listUseCase in
            await listUseCase.stubPage(
                result: makeRangePageResult(
                    range: 1...10,
                    passengerID: passengerID,
                    source: .remote,
                    isStale: false,
                    page: 1,
                    hasMorePages: true
                ),
                for: 1
            )
        }
    )
}

@MainActor
func makePaginatedRefreshFlightListViewModelSUT(
    passengerID: PassengerID = defaultFlightListPassengerID,
    sourceLocation: SourceLocation = #_sourceLocation
) async -> TrackedTestContext<SessionBoundFlightListViewModelTestContext<ListFlightsUseCaseSpy, SessionEndingSpy, ContinuousClock>> {
    await makeConfiguredSessionBoundFlightListViewModelSUT(
        passengerID: passengerID,
        sourceLocation: sourceLocation,
        configure: { listUseCase in
            await listUseCase.stubPage(
                result: makePageResult(
                    flightIDs: ["IB1001", "IB1002"],
                    passengerID: passengerID,
                    source: .remote,
                    isStale: false,
                    page: 1,
                    hasMorePages: true
                ),
                for: 1
            )
            await listUseCase.stubPage(
                result: makePageResult(
                    flightIDs: ["IB1003", "IB1004"],
                    passengerID: passengerID,
                    source: .remote,
                    isStale: false,
                    page: 2,
                    hasMorePages: false
                ),
                for: 2
            )
            await listUseCase.stubRefreshResult(
                makeFlights(
                    idsAndStatuses: [
                        ("IB1001", .boarding),
                        ("IB1002", .onTime),
                        ("IB1003", .onTime),
                        ("IB1004", .delayed)
                    ],
                    passengerID: passengerID
                )
            )
        }
    )
}

@MainActor
func makeStaleRefreshFailureFlightListViewModelSUT(
    passengerID: PassengerID = defaultFlightListPassengerID,
    sourceLocation: SourceLocation = #_sourceLocation
) async -> TrackedTestContext<SessionBoundFlightListViewModelTestContext<ListFlightsUseCaseSpy, SessionEndingSpy, ContinuousClock>> {
    await makeConfiguredSessionBoundFlightListViewModelSUT(
        passengerID: passengerID,
        sourceLocation: sourceLocation,
        configure: { listUseCase in
            await listUseCase.stubPage(
                result: makePageResult(
                    flightIDs: ["IB1001"],
                    passengerID: passengerID,
                    source: .cache,
                    isStale: true,
                    page: 1,
                    hasMorePages: false
                ),
                for: 1
            )
            await listUseCase.stubRefreshError(FlightListFailure())
        }
    )
}

@MainActor
func makeExpiredSessionFlightListViewModelSUT(
    passengerID: PassengerID = defaultFlightListPassengerID,
    sourceLocation: SourceLocation = #_sourceLocation
) -> TrackedTestContext<SessionBoundFlightListViewModelTestContext<ListFlightsUseCaseSpy, SessionEndingSpy, ContinuousClock>> {
    makeSessionBoundFlightListViewModelSUT(
        listUseCase: ListFlightsUseCaseSpy(),
        logoutUseCase: SessionEndingSpy(),
        passengerID: passengerID,
        sessionExpiresAt: .distantPast,
        sourceLocation: sourceLocation
    )
}

@MainActor
func makeExpiringDuringLoadFlightListViewModelSUT(
    passengerID: PassengerID = defaultFlightListPassengerID,
    sourceLocation: SourceLocation = #_sourceLocation
) -> TrackedTestContext<SessionBoundFlightListViewModelTestContext<SlowExpiringListFlightsUseCaseSpy, SessionEndingSpy, ContinuousClock>> {
    makeSessionBoundFlightListViewModelSUT(
        listUseCase: SlowExpiringListFlightsUseCaseSpy(
            result: FlightListResult(
                flights: [Flight.stub(id: FlightID("IB1001"), passengerID: passengerID)],
                source: .remote,
                isStale: false,
                page: 1,
                hasMorePages: false
            ),
            delayNanoseconds: 150_000_000
        ),
        logoutUseCase: SessionEndingSpy(),
        passengerID: passengerID,
        sessionExpiresAt: Date().addingTimeInterval(0.05),
        sourceLocation: sourceLocation
    )
}

@MainActor
struct ExpiringRefreshFlightListViewModelScenario {
    let tracked: TrackedTestContext<
        SessionBoundFlightListViewModelTestContext<RefreshDelayListFlightsUseCaseSpy, SessionEndingSpy, ContinuousClock>
    >
    let currentDate: CurrentDateStub
}

@MainActor
func makeExpiringDuringRefreshFlightListViewModelSUT(
    passengerID: PassengerID = defaultFlightListPassengerID,
    sourceLocation: SourceLocation = #_sourceLocation
) -> ExpiringRefreshFlightListViewModelScenario {
    let currentDate = CurrentDateStub(value: .now)
    let tracked = makeSessionBoundFlightListViewModelSUT(
        listUseCase: RefreshDelayListFlightsUseCaseSpy(
            pageResult: FlightListResult(
                flights: [Flight.stub(id: FlightID("IB1001"), passengerID: passengerID, status: .onTime)],
                source: .remote,
                isStale: false,
                page: 1,
                hasMorePages: false
            ),
            refreshedFlights: [Flight.stub(id: FlightID("IB1001"), passengerID: passengerID, status: .delayed)],
            delayNanoseconds: 300_000_000
        ),
        logoutUseCase: SessionEndingSpy(),
        passengerID: passengerID,
        sessionExpiresAt: currentDate.value.addingTimeInterval(0.15),
        currentDateProvider: { currentDate.value },
        sourceLocation: sourceLocation
    )
    return ExpiringRefreshFlightListViewModelScenario(tracked: tracked, currentDate: currentDate)
}

@MainActor
func makeCachedSecondPageFlightListViewModelSUT(
    passengerID: PassengerID = defaultFlightListPassengerID,
    sourceLocation: SourceLocation = #_sourceLocation
) async -> TrackedTestContext<SessionBoundFlightListViewModelTestContext<ListFlightsUseCaseSpy, SessionEndingSpy, ContinuousClock>> {
    await makePaginatedFlightListViewModelSUT(
        passengerID: passengerID,
        firstPage: makeRangePageResult(
            range: 1...10,
            passengerID: passengerID,
            source: .remote,
            isStale: false,
            page: 1,
            hasMorePages: true
        ),
        secondPage: makeRangePageResult(
            range: 11...20,
            passengerID: passengerID,
            source: .cache,
            isStale: true,
            page: 2,
            hasMorePages: true
        ),
        sourceLocation: sourceLocation
    )
}

@MainActor
func makeFirstPageOnlyFlightListViewModelSUT(
    passengerID: PassengerID = defaultFlightListPassengerID,
    sourceLocation: SourceLocation = #_sourceLocation
) async -> TrackedTestContext<SessionBoundFlightListViewModelTestContext<ListFlightsUseCaseSpy, SessionEndingSpy, ContinuousClock>> {
    await makePaginatedFlightListViewModelSUT(
        passengerID: passengerID,
        firstPage: makeRangePageResult(
            range: 1...10,
            passengerID: passengerID,
            source: .remote,
            isStale: false,
            page: 1,
            hasMorePages: true
        ),
        secondPage: makeRangePageResult(
            range: 11...12,
            passengerID: passengerID,
            source: .remote,
            isStale: false,
            page: 2,
            hasMorePages: false
        ),
        sourceLocation: sourceLocation
    )
}

@MainActor
func makeInlineSpinnerPaginationFlightListViewModelSUT(
    passengerID: PassengerID = defaultFlightListPassengerID,
    sourceLocation: SourceLocation = #_sourceLocation
) -> TrackedTestContext<SessionBoundFlightListViewModelTestContext<SuspendedNextPageListFlightsUseCaseSpy, SessionEndingSpy, ContinuousClock>> {
    makeSuspendedPaginationFlightListViewModelSUT(
        passengerID: passengerID,
        firstPage: makeRangePageResult(
            range: 1...10,
            passengerID: passengerID,
            source: .remote,
            isStale: false,
            page: 1,
            hasMorePages: true
        ),
        secondPage: makeRangePageResult(
            range: 11...20,
            passengerID: passengerID,
            source: .remote,
            isStale: false,
            page: 2,
            hasMorePages: false
        ),
        sourceLocation: sourceLocation
    )
}

@MainActor
func makePaginatedFlightListViewModelSUT(
    passengerID: PassengerID = defaultFlightListPassengerID,
    firstPage: FlightListResult,
    secondPage: FlightListResult,
    sourceLocation: SourceLocation = #_sourceLocation
) async -> TrackedTestContext<SessionBoundFlightListViewModelTestContext<ListFlightsUseCaseSpy, SessionEndingSpy, ContinuousClock>> {
    let listUseCase = ListFlightsUseCaseSpy()
    await listUseCase.stubPage(result: firstPage, for: 1)
    await listUseCase.stubPage(result: secondPage, for: 2)
    return makeSessionBoundFlightListViewModelSUT(
        listUseCase: listUseCase,
        logoutUseCase: SessionEndingSpy(),
        passengerID: passengerID,
        sessionExpiresAt: .distantFuture,
        sourceLocation: sourceLocation
    )
}

@MainActor
func makeSuspendedPaginationFlightListViewModelSUT(
    passengerID: PassengerID = defaultFlightListPassengerID,
    firstPage: FlightListResult,
    secondPage: FlightListResult,
    sourceLocation: SourceLocation = #_sourceLocation
) -> TrackedTestContext<SessionBoundFlightListViewModelTestContext<SuspendedNextPageListFlightsUseCaseSpy, SessionEndingSpy, ContinuousClock>> {
    let listUseCase = SuspendedNextPageListFlightsUseCaseSpy(
        firstPage: firstPage,
        secondPage: secondPage
    )
    return makeSessionBoundFlightListViewModelSUT(
        listUseCase: listUseCase,
        logoutUseCase: SessionEndingSpy(),
        passengerID: passengerID,
        sessionExpiresAt: .distantFuture,
        minimumNextPageSpinnerNanoseconds: 180_000_000,
        sourceLocation: sourceLocation
    )
}
