import FlightsFeature
import Foundation
import SharedKernel
import SharedNavigation
import Testing

@MainActor
@Suite("FlightListViewModel")
struct FlightListViewModelTests {

    @Test("When logout is requested, the view model delegates to the session controller")
    func logoutDelegatesToSessionController() async {
        let bus = NavigationEventBusSpy()
        let listUseCase = ListFlightsUseCaseSpy()
        let sessionController = FlightListSessionControllerSpy()
        let sut = FlightListViewModel(
            listUseCase: listUseCase,
            sessionController: sessionController,
            eventBus: bus,
            passengerID: PassengerID("PAX-001")
        )

        await sut.logout()

        #expect(sessionController.logoutCallCount == 1)
        let loadCallCount = await listUseCase.executePages.count
        #expect(loadCallCount == 0)
    }

    @Test("Given expired session, when loading, then SessionExpired is published")
    func loadPublishesSessionExpiredWhenSessionHasExpired() async {
        let bus = NavigationEventBusSpy()
        let listUseCase = ListFlightsUseCaseSpy()
        let logoutUseCase = LogoutUseCaseSpy()
        let sut = FlightListViewModel(
            listUseCase: listUseCase,
            logoutUseCase: logoutUseCase,
            eventBus: bus,
            passengerID: PassengerID("PAX-001"),
            sessionExpiresAt: .distantPast
        )

        await sut.load()

        let publishedEvent = await bus.lastPublishedEvent
        #expect(publishedEvent == .sessionEnded(.expired))
        let endSessionCallCount = await logoutUseCase.endSessionCallCount
        #expect(endSessionCallCount == 1)
        let loadCallCount = await listUseCase.executePages.count
        #expect(loadCallCount == 0)
    }

    @Test("Given stale cache result, when loading, then stale warning is exposed")
    func loadExposesStaleWarning() async {
        let bus = NavigationEventBusSpy()
        let listUseCase = ListFlightsUseCaseSpy()
        let logoutUseCase = LogoutUseCaseSpy()
        await listUseCase.stubPage(
            result: FlightListResult(
                flights: [Flight.stub(id: FlightID("IB3456"), passengerID: PassengerID("PAX-001"))],
                source: .cache,
                isStale: true,
                page: 1,
                hasMorePages: false
            ),
            for: 1
        )
        let sut = FlightListViewModel(
            listUseCase: listUseCase,
            logoutUseCase: logoutUseCase,
            eventBus: bus,
            passengerID: PassengerID("PAX-001"),
            sessionExpiresAt: .distantFuture
        )

        await sut.load()

        #expect(sut.flights.count == 1)
        #expect(sut.staleMessage == AppStrings.localized("flights.list.staleWarning"))
    }

    @Test("Given first page is still loading, when state is observed, then the initial skeleton state is exposed")
    func loadExposesInitialSkeletonStateWhileFirstPageIsPending() async {
        let bus = NavigationEventBusSpy()
        let listUseCase = SlowListFlightsUseCaseSpy(
            result: FlightListResult(
                flights: [Flight.stub(id: FlightID("IB1001"), passengerID: PassengerID("PAX-001"))],
                source: .remote,
                isStale: false,
                page: 1,
                hasMorePages: true
            )
        )
        let logoutUseCase = LogoutUseCaseSpy()
        let sut = FlightListViewModel(
            listUseCase: listUseCase,
            logoutUseCase: logoutUseCase,
            eventBus: bus,
            passengerID: PassengerID("PAX-001"),
            sessionExpiresAt: .distantFuture
        )

        let task = Task {
            await sut.load()
        }
        await Task.yield()

        #expect(sut.isShowingInitialSkeleton)

        await task.value

        #expect(sut.isShowingInitialSkeleton == false)
    }

    @Test("Given configured minimum skeleton duration, when first page resolves immediately, then the skeleton remains visible until the minimum time elapses")
    func loadKeepsSkeletonVisibleForMinimumDuration() async {
        let bus = NavigationEventBusSpy()
        let listUseCase = InstantListFlightsUseCaseSpy(
            result: FlightListResult(
                flights: [Flight.stub(id: FlightID("IB1001"), passengerID: PassengerID("PAX-001"))],
                source: .remote,
                isStale: false,
                page: 1,
                hasMorePages: true
            )
        )
        let logoutUseCase = LogoutUseCaseSpy()
        let sut = FlightListViewModel(
            listUseCase: listUseCase,
            logoutUseCase: logoutUseCase,
            eventBus: bus,
            passengerID: PassengerID("PAX-001"),
            sessionExpiresAt: .distantFuture,
            minimumInitialSkeletonNanoseconds: 250_000_000
        )
        let clock = ContinuousClock()
        let startedAt = clock.now

        let task = Task {
            await sut.load()
        }

        await task.value
        let elapsed = startedAt.duration(to: clock.now)

        #expect(elapsed >= .milliseconds(200))
        #expect(sut.isShowingInitialSkeleton == false)
    }

    @Test("Given long list, when loading first page, then exposes first block and pagination state")
    func loadUsesFirstPageAndPaginationState() async {
        let bus = NavigationEventBusSpy()
        let listUseCase = ListFlightsUseCaseSpy()
        let logoutUseCase = LogoutUseCaseSpy()
        let passengerID = PassengerID("PAX-001")
        await listUseCase.stubPage(
            result: FlightListResult(
                flights: makeFlights(range: 1...10, passengerID: passengerID),
                source: .remote,
                isStale: false,
                page: 1,
                hasMorePages: true
            ),
            for: 1
        )
        let sut = FlightListViewModel(
            listUseCase: listUseCase,
            logoutUseCase: logoutUseCase,
            eventBus: bus,
            passengerID: passengerID,
            sessionExpiresAt: .distantFuture
        )

        await sut.load()

        #expect(sut.flights.map(\.id.value) == makeFlightIDs(range: 1...10))
        #expect(sut.canLoadMorePages)
        let requestedPages = await listUseCase.executePages
        #expect(requestedPages == [1])
    }

    @Test("Given additional cached page, when loading next page, then appends the next ten flights without duplicates")
    func loadNextPageAppendsFlightsWithoutDuplicates() async {
        let bus = NavigationEventBusSpy()
        let listUseCase = ListFlightsUseCaseSpy()
        let logoutUseCase = LogoutUseCaseSpy()
        let passengerID = PassengerID("PAX-001")
        await listUseCase.stubPage(
            result: FlightListResult(
                flights: makeFlights(range: 1...10, passengerID: passengerID),
                source: .remote,
                isStale: false,
                page: 1,
                hasMorePages: true
            ),
            for: 1
        )
        await listUseCase.stubPage(
            result: FlightListResult(
                flights: makeFlights(range: 11...20, passengerID: passengerID),
                source: .cache,
                isStale: true,
                page: 2,
                hasMorePages: true
            ),
            for: 2
        )
        let sut = FlightListViewModel(
            listUseCase: listUseCase,
            logoutUseCase: logoutUseCase,
            eventBus: bus,
            passengerID: passengerID,
            sessionExpiresAt: .distantFuture
        )

        await sut.load()
        await sut.loadNextPage()

        #expect(sut.flights.map(\.id.value) == makeFlightIDs(range: 1...20))
        #expect(sut.canLoadMorePages)
        #expect(sut.staleMessage == AppStrings.localized("flights.list.staleWarning"))
        let requestedPages = await listUseCase.executePages
        #expect(requestedPages == [1, 2])
    }

    @Test("Given the passenger has not reached the pagination footer, when the next page is not requested explicitly, then only the first page stays visible")
    func loadDoesNotRequestTheNextPageBeforeThePaginationFooter() async {
        let bus = NavigationEventBusSpy()
        let listUseCase = ListFlightsUseCaseSpy()
        let logoutUseCase = LogoutUseCaseSpy()
        let passengerID = PassengerID("PAX-001")
        await listUseCase.stubPage(
            result: FlightListResult(
                flights: makeFlights(range: 1...10, passengerID: passengerID),
                source: .remote,
                isStale: false,
                page: 1,
                hasMorePages: true
            ),
            for: 1
        )
        await listUseCase.stubPage(
            result: FlightListResult(
                flights: makeFlights(range: 11...12, passengerID: passengerID),
                source: .remote,
                isStale: false,
                page: 2,
                hasMorePages: false
            ),
            for: 2
        )
        let sut = FlightListViewModel(
            listUseCase: listUseCase,
            logoutUseCase: logoutUseCase,
            eventBus: bus,
            passengerID: passengerID,
            sessionExpiresAt: .distantFuture
        )

        await sut.load()

        #expect(sut.flights.map(\.id.value) == makeFlightIDs(range: 1...10))
        let requestedPages = await listUseCase.executePages
        #expect(requestedPages == [1])
    }

    @Test("Given the next page is still loading, when the request is in flight, then the inline pagination spinner state is exposed")
    func loadNextPageExposesInlineSpinnerState() async {
        let bus = NavigationEventBusSpy()
        let listUseCase = SuspendedNextPageListFlightsUseCaseSpy(
            firstPage: FlightListResult(
                flights: makeFlights(range: 1...10, passengerID: PassengerID("PAX-001")),
                source: .remote,
                isStale: false,
                page: 1,
                hasMorePages: true
            ),
            secondPage: FlightListResult(
                flights: makeFlights(range: 11...20, passengerID: PassengerID("PAX-001")),
                source: .remote,
                isStale: false,
                page: 2,
                hasMorePages: false
            )
        )
        let logoutUseCase = LogoutUseCaseSpy()
        let sut = FlightListViewModel(
            listUseCase: listUseCase,
            logoutUseCase: logoutUseCase,
            eventBus: bus,
            passengerID: PassengerID("PAX-001"),
            sessionExpiresAt: .distantFuture,
            minimumNextPageSpinnerNanoseconds: 180_000_000
        )

        await sut.load()

        let task = Task {
            await sut.loadNextPage()
        }
        await listUseCase.awaitSecondPageRequest()
        await Task.yield()

        #expect(sut.isLoadingNextPage)
        #expect(sut.flights.map(\.id.value) == makeFlightIDs(range: 1...10))

        await listUseCase.finishSecondPageRequest()
        await task.value

        #expect(sut.isLoadingNextPage == false)
        #expect(sut.flights.map(\.id.value) == makeFlightIDs(range: 1...20))
    }

    @Test("Given paginated list, when refreshing, then visible flights are refreshed and length is preserved")
    func refreshPreservesLoadedLength() async {
        let bus = NavigationEventBusSpy()
        let listUseCase = ListFlightsUseCaseSpy()
        let logoutUseCase = LogoutUseCaseSpy()
        let passengerID = PassengerID("PAX-001")
        await listUseCase.stubPage(
            result: FlightListResult(
                flights: [
                    Flight.stub(id: FlightID("IB1001"), passengerID: passengerID),
                    Flight.stub(id: FlightID("IB1002"), passengerID: passengerID)
                ],
                source: .remote,
                isStale: false,
                page: 1,
                hasMorePages: true
            ),
            for: 1
        )
        await listUseCase.stubPage(
            result: FlightListResult(
                flights: [
                    Flight.stub(id: FlightID("IB1003"), passengerID: passengerID),
                    Flight.stub(id: FlightID("IB1004"), passengerID: passengerID)
                ],
                source: .remote,
                isStale: false,
                page: 2,
                hasMorePages: false
            ),
            for: 2
        )
        await listUseCase.stubRefreshResult([
            Flight.stub(id: FlightID("IB1001"), passengerID: passengerID, status: .boarding),
            Flight.stub(id: FlightID("IB1002"), passengerID: passengerID),
            Flight.stub(id: FlightID("IB1003"), passengerID: passengerID),
            Flight.stub(id: FlightID("IB1004"), passengerID: passengerID, status: .delayed)
        ])
        let sut = FlightListViewModel(
            listUseCase: listUseCase,
            logoutUseCase: logoutUseCase,
            eventBus: bus,
            passengerID: passengerID,
            sessionExpiresAt: .distantFuture
        )

        await sut.load()
        await sut.loadNextPage()
        await sut.refresh()

        #expect(sut.flights.count == 4)
        #expect(sut.flights.first?.status == .boarding)
        #expect(sut.flights.last?.status == .delayed)
        let refreshedIDs = await listUseCase.lastRefreshFlightIDs
        #expect(refreshedIDs?.map(\.value) == ["IB1001", "IB1002", "IB1003", "IB1004"])
    }

    @Test("Given stale cached flights, when refresh fails, then the stale warning remains visible")
    func refreshPreservesStaleWarningAfterFailure() async {
        let bus = NavigationEventBusSpy()
        let listUseCase = ListFlightsUseCaseSpy()
        let logoutUseCase = LogoutUseCaseSpy()
        let passengerID = PassengerID("PAX-001")
        await listUseCase.stubPage(
            result: FlightListResult(
                flights: [Flight.stub(id: FlightID("IB1001"), passengerID: passengerID)],
                source: .cache,
                isStale: true,
                page: 1,
                hasMorePages: false
            ),
            for: 1
        )
        await listUseCase.stubRefreshError(FlightListFailure())
        let sut = FlightListViewModel(
            listUseCase: listUseCase,
            logoutUseCase: logoutUseCase,
            eventBus: bus,
            passengerID: passengerID,
            sessionExpiresAt: .distantFuture
        )

        await sut.load()
        await sut.refresh()

        #expect(sut.flights.map(\.id.value) == ["IB1001"])
        #expect(sut.errorMessage == AppStrings.localized("flights.error.load"))
        #expect(sut.staleMessage == AppStrings.localized("flights.list.staleWarning"))
    }

    @Test("Given session expires while page load is suspended, when the page returns, then flights are discarded and SessionExpired is published")
    func loadDiscardsFlightsIfSessionExpiresDuringSuspendedPageLoad() async {
        let bus = NavigationEventBusSpy()
        let listUseCase = SlowExpiringListFlightsUseCaseSpy(
            result: FlightListResult(
                flights: [Flight.stub(id: FlightID("IB1001"), passengerID: PassengerID("PAX-001"))],
                source: .remote,
                isStale: false,
                page: 1,
                hasMorePages: false
            ),
            delayNanoseconds: 150_000_000
        )
        let logoutUseCase = LogoutUseCaseSpy()
        let sut = FlightListViewModel(
            listUseCase: listUseCase,
            logoutUseCase: logoutUseCase,
            eventBus: bus,
            passengerID: PassengerID("PAX-001"),
            sessionExpiresAt: Date().addingTimeInterval(0.05)
        )

        await sut.load()

        #expect(sut.flights.isEmpty)
        #expect(await bus.lastPublishedEvent == .sessionEnded(.expired))
        #expect(await logoutUseCase.endSessionCallCount == 1)
    }

    @Test("Given session expires while refresh is suspended, when the refresh returns, then refreshed flights are discarded and SessionExpired is published")
    func refreshDiscardsFlightsIfSessionExpiresDuringSuspendedRefresh() async {
        let currentDate = CurrentDateStub(value: .now)
        let bus = NavigationEventBusSpy()
        let listUseCase = RefreshDelayListFlightsUseCaseSpy(
            pageResult: FlightListResult(
                flights: [Flight.stub(id: FlightID("IB1001"), passengerID: PassengerID("PAX-001"), status: .onTime)],
                source: .remote,
                isStale: false,
                page: 1,
                hasMorePages: false
            ),
            refreshedFlights: [Flight.stub(id: FlightID("IB1001"), passengerID: PassengerID("PAX-001"), status: .delayed)],
            delayNanoseconds: 300_000_000
        )
        let logoutUseCase = LogoutUseCaseSpy()
        let sut = FlightListViewModel(
            listUseCase: listUseCase,
            logoutUseCase: logoutUseCase,
            eventBus: bus,
            passengerID: PassengerID("PAX-001"),
            sessionExpiresAt: currentDate.value.addingTimeInterval(0.15),
            currentDateProvider: { currentDate.value }
        )

        await sut.load()
        #expect(sut.flights.first?.status == .onTime)
        currentDate.value = currentDate.value.addingTimeInterval(0.2)

        await sut.refresh()

        #expect(sut.flights.first?.status == .onTime)
        #expect(await bus.lastPublishedEvent == .sessionEnded(.expired))
        #expect(await logoutUseCase.endSessionCallCount == 1)
    }
}

private actor SlowListFlightsUseCaseSpy: ListFlightsExecuting {
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

private actor InstantListFlightsUseCaseSpy: ListFlightsExecuting {
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

private actor ListFlightsUseCaseSpy: ListFlightsExecuting {
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
        return refreshResult.isEmpty ? flightIDs.map { Flight.stub(id: $0, passengerID: PassengerID("PAX-001")) } : refreshResult
    }
}

private actor LogoutUseCaseSpy: SessionEnding {
    private(set) var endSessionCallCount = 0

    func endSession() async {
        endSessionCallCount += 1
    }
}

@MainActor
private final class FlightListSessionControllerSpy: FlightListSessionControlling {
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

private actor SlowExpiringListFlightsUseCaseSpy: ListFlightsExecuting {
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

private actor RefreshDelayListFlightsUseCaseSpy: ListFlightsExecuting {
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

private struct FlightListFailure: Error {}

@MainActor
private final class CurrentDateStub {
    var value: Date

    init(value: Date) {
        self.value = value
    }
}

private actor SuspendedNextPageListFlightsUseCaseSpy: ListFlightsExecuting {
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

private func makeFlights(range: ClosedRange<Int>, passengerID: PassengerID) -> [Flight] {
    range.map { index in
        Flight.stub(
            id: FlightID("IB\(1000 + index)"),
            passengerID: passengerID
        )
    }
}

private func makeFlightIDs(range: ClosedRange<Int>) -> [String] {
    range.map { "IB\(1000 + $0)" }
}
