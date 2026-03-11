import FlightsFeature
import SharedKernel
import SharedNavigation
import Testing

@MainActor
@Suite("FlightListViewRender")
struct FlightListViewRenderTests {
    @Test("Flight list renders the initial skeleton while the first page is pending")
    func rendersInitialSkeleton() async throws {
        let executor = ListRenderExecutor(
            suspendedPage: (
                1,
                FlightListResult(
                    flights: [Flight.stub(id: FlightID("IB1001"), passengerID: passengerID)],
                    source: .remote,
                    isStale: false,
                    page: 1,
                    hasMorePages: true
                )
            )
        )
        let viewModel = FlightListViewModel(
            listUseCase: executor,
            logoutUseCase: LogoutRenderExecutor(),
            eventBus: NavigationEventBusSpy(),
            passengerID: passengerID,
            sessionExpiresAt: .distantFuture
        )

        let task = Task {
            await viewModel.load()
        }
        await Task.yield()

        let data = try renderedPNG(from: FlightListView(viewModel: viewModel))

        #expect(viewModel.isShowingInitialSkeleton)
        #expect(data.count > 1_000)

        await executor.resumePage()
        await task.value
    }

    @Test("Flight list renders rows and stale banner")
    func rendersContentAndStaleBanner() async throws {
        let executor = ListRenderExecutor(
            pageResults: [
                1: FlightListResult(
                    flights: makeFlights(range: 1...10),
                    source: .cache,
                    isStale: true,
                    page: 1,
                    hasMorePages: true
                )
            ]
        )
        let viewModel = FlightListViewModel(
            listUseCase: executor,
            logoutUseCase: LogoutRenderExecutor(),
            eventBus: NavigationEventBusSpy(),
            passengerID: passengerID,
            sessionExpiresAt: .distantFuture
        )

        await viewModel.load()
        let data = try renderedPNG(
            from: FlightListView(viewModel: viewModel),
            colorScheme: .dark
        )

        #expect(viewModel.flights.count == 10)
        #expect(viewModel.staleMessage == AppStrings.localized("flights.list.staleWarning"))
        #expect(data.count > 1_000)
    }

    @Test("Flight list renders the inline pagination spinner")
    func rendersPaginationSpinner() async throws {
        let executor = ListRenderExecutor(
            pageResults: [
                1: FlightListResult(
                    flights: makeFlights(range: 1...10),
                    source: .remote,
                    isStale: false,
                    page: 1,
                    hasMorePages: true
                )
            ],
            suspendedPage: (
                2,
                FlightListResult(
                    flights: makeFlights(range: 11...20),
                    source: .remote,
                    isStale: false,
                    page: 2,
                    hasMorePages: true
                )
            )
        )
        let viewModel = FlightListViewModel(
            listUseCase: executor,
            logoutUseCase: LogoutRenderExecutor(),
            eventBus: NavigationEventBusSpy(),
            passengerID: passengerID,
            sessionExpiresAt: .distantFuture
        )

        await viewModel.load()
        let task = Task {
            await viewModel.loadNextPage()
        }
        await Task.yield()

        let data = try renderedPNG(from: FlightListView(viewModel: viewModel))

        #expect(viewModel.isLoadingNextPage)
        #expect(data.count > 1_000)

        await executor.resumePage()
        await task.value
    }

    @Test("Flight list renders the empty error state")
    func rendersEmptyErrorState() async throws {
        let executor = ListRenderExecutor(executeError: FlightError.network)
        let viewModel = FlightListViewModel(
            listUseCase: executor,
            logoutUseCase: LogoutRenderExecutor(),
            eventBus: NavigationEventBusSpy(),
            passengerID: passengerID,
            sessionExpiresAt: .distantFuture
        )

        await viewModel.load()
        let data = try renderedPNG(from: FlightListView(viewModel: viewModel))

        #expect(viewModel.errorMessage == AppStrings.localized("flights.error.load"))
        #expect(viewModel.flights.isEmpty)
        #expect(data.count > 1_000)
    }

    @Test("Flight list renders the non-empty refresh error banner")
    func rendersRefreshErrorBanner() async throws {
        let executor = ListRenderExecutor(
            pageResults: [
                1: FlightListResult(
                    flights: makeFlights(range: 1...10),
                    source: .remote,
                    isStale: false,
                    page: 1,
                    hasMorePages: false
                )
            ],
            refreshError: FlightError.network
        )
        let viewModel = FlightListViewModel(
            listUseCase: executor,
            logoutUseCase: LogoutRenderExecutor(),
            eventBus: NavigationEventBusSpy(),
            passengerID: passengerID,
            sessionExpiresAt: .distantFuture
        )

        await viewModel.load()
        await viewModel.refresh()
        let data = try renderedPNG(from: FlightListView(viewModel: viewModel))

        #expect(viewModel.errorMessage == AppStrings.localized("flights.error.load"))
        #expect(viewModel.flights.isEmpty == false)
        #expect(data.count > 1_000)
    }

    private let passengerID = PassengerID("PAX-001")

    private func makeFlights(range: ClosedRange<Int>) -> [Flight] {
        range.map { index in
            let status: Flight.Status
            switch index % 3 {
            case 0:
                status = .delayed
            case 1:
                status = .onTime
            default:
                status = .boarding
            }
            return Flight.stub(
                id: FlightID("IB\(1000 + index)"),
                passengerID: passengerID,
                status: status
            )
        }
    }
}

private actor ListRenderExecutor: ListFlightsExecuting {
    private let pageResults: [Int: FlightListResult]
    private let executeError: Error?
    private let refreshResult: [Flight]
    private let refreshError: Error?
    private let suspendedPageNumber: Int?
    private let suspendedPageResult: FlightListResult?
    private var continuation: CheckedContinuation<FlightListResult, Error>?

    init(
        pageResults: [Int: FlightListResult] = [:],
        executeError: Error? = nil,
        refreshResult: [Flight] = [],
        refreshError: Error? = nil,
        suspendedPage: (Int, FlightListResult)? = nil
    ) {
        self.pageResults = pageResults
        self.executeError = executeError
        self.refreshResult = refreshResult
        self.refreshError = refreshError
        self.suspendedPageNumber = suspendedPage?.0
        self.suspendedPageResult = suspendedPage?.1
    }

    func execute(passengerID: PassengerID, page: Int) async throws -> FlightListResult {
        if suspendedPageNumber == page {
            return try await withCheckedThrowingContinuation { continuation in
                self.continuation = continuation
            }
        }
        if let executeError {
            throw executeError
        }
        guard let result = pageResults[page] else {
            preconditionFailure("Missing page result for page \(page)")
        }
        return result
    }

    func refreshAll(flightIDs: [FlightID]) async throws -> [Flight] {
        if let refreshError {
            throw refreshError
        }
        return refreshResult.isEmpty ? flightIDs.map {
            Flight.stub(id: $0, passengerID: PassengerID("PAX-001"))
        } : refreshResult
    }

    func resumePage() {
        guard let suspendedPageResult else {
            return
        }
        continuation?.resume(returning: suspendedPageResult)
        continuation = nil
    }
}

private actor LogoutRenderExecutor: SessionEnding {
    func endSession() async {}
}
