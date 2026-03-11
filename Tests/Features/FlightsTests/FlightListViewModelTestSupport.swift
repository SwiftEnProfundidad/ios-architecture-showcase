import FlightsFeature
import Foundation
import SharedKernel
import SharedNavigation
import Testing

let defaultFlightListPassengerID = PassengerID("PAX-001")

@MainActor
struct ControlledFlightListViewModelTestContext<ListUseCase: ListFlightsExecuting> {
    let sut: FlightListViewModel<ListUseCase, FlightListSessionControllerSpy>
    let listUseCase: ListUseCase
    let sessionController: FlightListSessionControllerSpy
    let eventBus: NavigationEventBusSpy
}

@MainActor
struct SessionBoundFlightListViewModelTestContext<
    ListUseCase: ListFlightsExecuting,
    LogoutUseCase: SessionEnding
> {
    let sut: FlightListViewModel<ListUseCase, FlightListSessionController<LogoutUseCase>>
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
) -> TrackedTestContext<ControlledFlightListViewModelTestContext<ListUseCase>> {
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
) -> TrackedTestContext<SessionBoundFlightListViewModelTestContext<ListUseCase, LogoutUseCase>> {
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
) async -> TrackedTestContext<SessionBoundFlightListViewModelTestContext<ListFlightsUseCaseSpy, LogoutUseCaseSpy>> {
    let listUseCase = ListFlightsUseCaseSpy()
    await configure(listUseCase)
    return makeSessionBoundFlightListViewModelSUT(
        listUseCase: listUseCase,
        logoutUseCase: LogoutUseCaseSpy(),
        passengerID: passengerID,
        sessionExpiresAt: sessionExpiresAt,
        minimumInitialSkeletonNanoseconds: minimumInitialSkeletonNanoseconds,
        minimumNextPageSpinnerNanoseconds: minimumNextPageSpinnerNanoseconds,
        currentDateProvider: currentDateProvider,
        sourceLocation: sourceLocation
    )
}

actor SlowListFlightsUseCaseSpy: ListFlightsExecuting {
    private let result: FlightListResult

    init(result: FlightListResult) {
        self.result = result
    }

    func execute(passengerID: PassengerID, page: Int) async throws -> FlightListResult {
        try await Task.sleep(nanoseconds: 150_000_000)
        return result
    }

    func refreshAll(flightIDs: [FlightID]) async throws -> [Flight] {
        []
    }
}

actor InstantListFlightsUseCaseSpy: ListFlightsExecuting {
    private let result: FlightListResult

    init(result: FlightListResult) {
        self.result = result
    }

    func execute(passengerID: PassengerID, page: Int) async throws -> FlightListResult {
        result
    }

    func refreshAll(flightIDs: [FlightID]) async throws -> [Flight] {
        []
    }
}

actor ListFlightsUseCaseSpy: ListFlightsExecuting {
    private var pageResults: [Int: FlightListResult] = [:]
    private var refreshResult: [Flight] = []
    private var refreshError: Error?
    private(set) var executePages: [Int] = []
    private(set) var lastRefreshFlightIDs: [FlightID]?

    func stubPage(result: FlightListResult, for page: Int) {
        pageResults[page] = result
    }

    func stubRefreshResult(_ flights: [Flight]) {
        refreshResult = flights
    }

    func stubRefreshError(_ error: Error) {
        refreshError = error
    }

    func execute(passengerID: PassengerID, page: Int) async throws -> FlightListResult {
        executePages.append(page)
        return pageResults[page] ?? FlightListResult(
            flights: [],
            source: .remote,
            isStale: false,
            page: page,
            hasMorePages: false
        )
    }

    func refreshAll(flightIDs: [FlightID]) async throws -> [Flight] {
        lastRefreshFlightIDs = flightIDs
        if let refreshError {
            throw refreshError
        }
        return refreshResult.isEmpty ? flightIDs.map { Flight.stub(id: $0, passengerID: defaultFlightListPassengerID) } : refreshResult
    }
}

actor LogoutUseCaseSpy: SessionEnding {
    private(set) var endSessionCallCount = 0

    func endSession() async {
        endSessionCallCount += 1
    }
}

@MainActor
final class FlightListSessionControllerSpy: FlightListSessionControlling {
    private(set) var ensureActiveSessionCallCount = 0
    private(set) var logoutCallCount = 0
    var isSessionActive = true

    func ensureActiveSession() async -> Bool {
        ensureActiveSessionCallCount += 1
        return isSessionActive
    }

    func logoutUser() async {
        logoutCallCount += 1
    }
}

actor SlowExpiringListFlightsUseCaseSpy: ListFlightsExecuting {
    private let result: FlightListResult
    private let delayNanoseconds: UInt64

    init(result: FlightListResult, delayNanoseconds: UInt64) {
        self.result = result
        self.delayNanoseconds = delayNanoseconds
    }

    func execute(passengerID: PassengerID, page: Int) async throws -> FlightListResult {
        try await Task.sleep(nanoseconds: delayNanoseconds)
        return result
    }

    func refreshAll(flightIDs: [FlightID]) async throws -> [Flight] {
        []
    }
}

actor RefreshDelayListFlightsUseCaseSpy: ListFlightsExecuting {
    private let pageResult: FlightListResult
    private let refreshedFlights: [Flight]
    private let delayNanoseconds: UInt64

    init(pageResult: FlightListResult, refreshedFlights: [Flight], delayNanoseconds: UInt64) {
        self.pageResult = pageResult
        self.refreshedFlights = refreshedFlights
        self.delayNanoseconds = delayNanoseconds
    }

    func execute(passengerID: PassengerID, page: Int) async throws -> FlightListResult {
        pageResult
    }

    func refreshAll(flightIDs: [FlightID]) async throws -> [Flight] {
        try await Task.sleep(nanoseconds: delayNanoseconds)
        return refreshedFlights
    }
}

struct FlightListFailure: Error {}

@MainActor
final class CurrentDateStub {
    var value: Date

    init(value: Date) {
        self.value = value
    }
}

actor SuspendedNextPageListFlightsUseCaseSpy: ListFlightsExecuting {
    private let firstPage: FlightListResult
    private let secondPage: FlightListResult
    private var secondPageRequested = false
    private var continuation: CheckedContinuation<Void, Never>?

    init(firstPage: FlightListResult, secondPage: FlightListResult) {
        self.firstPage = firstPage
        self.secondPage = secondPage
    }

    func execute(passengerID: PassengerID, page: Int) async throws -> FlightListResult {
        if page == 1 {
            return firstPage
        }
        secondPageRequested = true
        await withCheckedContinuation { continuation in
            self.continuation = continuation
        }
        return secondPage
    }

    func refreshAll(flightIDs: [FlightID]) async throws -> [Flight] {
        []
    }

    func awaitSecondPageRequest() async {
        while secondPageRequested == false {
            await Task.yield()
        }
    }

    func finishSecondPageRequest() {
        continuation?.resume()
        continuation = nil
    }
}

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
) async -> TrackedTestContext<SessionBoundFlightListViewModelTestContext<ListFlightsUseCaseSpy, LogoutUseCaseSpy>> {
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
) -> TrackedTestContext<SessionBoundFlightListViewModelTestContext<SlowListFlightsUseCaseSpy, LogoutUseCaseSpy>> {
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
        logoutUseCase: LogoutUseCaseSpy(),
        passengerID: passengerID,
        sessionExpiresAt: .distantFuture,
        sourceLocation: sourceLocation
    )
}

@MainActor
func makeMinimumSkeletonFlightListLoadingSUT(
    passengerID: PassengerID = defaultFlightListPassengerID,
    sourceLocation: SourceLocation = #_sourceLocation
) -> TrackedTestContext<SessionBoundFlightListViewModelTestContext<InstantListFlightsUseCaseSpy, LogoutUseCaseSpy>> {
    makeSessionBoundFlightListViewModelSUT(
        listUseCase: InstantListFlightsUseCaseSpy(
            result: makePageResult(
                flightIDs: ["IB1001"],
                passengerID: passengerID,
                source: .remote,
                isStale: false,
                page: 1,
                hasMorePages: true
            )
        ),
        logoutUseCase: LogoutUseCaseSpy(),
        passengerID: passengerID,
        sessionExpiresAt: .distantFuture,
        minimumInitialSkeletonNanoseconds: 250_000_000,
        sourceLocation: sourceLocation
    )
}

@MainActor
func makeFirstPagePaginationFlightListLoadingSUT(
    passengerID: PassengerID = defaultFlightListPassengerID,
    sourceLocation: SourceLocation = #_sourceLocation
) async -> TrackedTestContext<SessionBoundFlightListViewModelTestContext<ListFlightsUseCaseSpy, LogoutUseCaseSpy>> {
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
) async -> TrackedTestContext<SessionBoundFlightListViewModelTestContext<ListFlightsUseCaseSpy, LogoutUseCaseSpy>> {
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
) async -> TrackedTestContext<SessionBoundFlightListViewModelTestContext<ListFlightsUseCaseSpy, LogoutUseCaseSpy>> {
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
) -> TrackedTestContext<SessionBoundFlightListViewModelTestContext<ListFlightsUseCaseSpy, LogoutUseCaseSpy>> {
    makeSessionBoundFlightListViewModelSUT(
        listUseCase: ListFlightsUseCaseSpy(),
        logoutUseCase: LogoutUseCaseSpy(),
        passengerID: passengerID,
        sessionExpiresAt: .distantPast,
        sourceLocation: sourceLocation
    )
}

@MainActor
func makeExpiringDuringLoadFlightListViewModelSUT(
    passengerID: PassengerID = defaultFlightListPassengerID,
    sourceLocation: SourceLocation = #_sourceLocation
) -> TrackedTestContext<SessionBoundFlightListViewModelTestContext<SlowExpiringListFlightsUseCaseSpy, LogoutUseCaseSpy>> {
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
        logoutUseCase: LogoutUseCaseSpy(),
        passengerID: passengerID,
        sessionExpiresAt: Date().addingTimeInterval(0.05),
        sourceLocation: sourceLocation
    )
}

@MainActor
struct ExpiringRefreshFlightListViewModelScenario {
    let tracked: TrackedTestContext<
        SessionBoundFlightListViewModelTestContext<RefreshDelayListFlightsUseCaseSpy, LogoutUseCaseSpy>
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
        logoutUseCase: LogoutUseCaseSpy(),
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
) async -> TrackedTestContext<SessionBoundFlightListViewModelTestContext<ListFlightsUseCaseSpy, LogoutUseCaseSpy>> {
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
) async -> TrackedTestContext<SessionBoundFlightListViewModelTestContext<ListFlightsUseCaseSpy, LogoutUseCaseSpy>> {
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
) -> TrackedTestContext<SessionBoundFlightListViewModelTestContext<SuspendedNextPageListFlightsUseCaseSpy, LogoutUseCaseSpy>> {
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
) async -> TrackedTestContext<SessionBoundFlightListViewModelTestContext<ListFlightsUseCaseSpy, LogoutUseCaseSpy>> {
    let listUseCase = ListFlightsUseCaseSpy()
    await listUseCase.stubPage(result: firstPage, for: 1)
    await listUseCase.stubPage(result: secondPage, for: 2)
    return makeSessionBoundFlightListViewModelSUT(
        listUseCase: listUseCase,
        logoutUseCase: LogoutUseCaseSpy(),
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
) -> TrackedTestContext<SessionBoundFlightListViewModelTestContext<SuspendedNextPageListFlightsUseCaseSpy, LogoutUseCaseSpy>> {
    let listUseCase = SuspendedNextPageListFlightsUseCaseSpy(
        firstPage: firstPage,
        secondPage: secondPage
    )
    return makeSessionBoundFlightListViewModelSUT(
        listUseCase: listUseCase,
        logoutUseCase: LogoutUseCaseSpy(),
        passengerID: passengerID,
        sessionExpiresAt: .distantFuture,
        minimumNextPageSpinnerNanoseconds: 180_000_000,
        sourceLocation: sourceLocation
    )
}
