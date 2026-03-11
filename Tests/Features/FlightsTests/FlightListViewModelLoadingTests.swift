import FlightsFeature
import Foundation
import SharedKernel
import Testing

@MainActor
@Suite("FlightListViewModel.Loading")
struct FlightListViewModelLoadingTests {

    @Test("Given stale cache result, when loading, then stale warning is exposed")
    func loadExposesStaleWarning() async {
        let passengerID = PassengerID("PAX-001")
        let tracked = await makeConfiguredSessionBoundFlightListViewModelSUT(
            passengerID: passengerID,
            sourceLocation: #_sourceLocation,
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
        defer { tracked.assertNoLeaks() }
        let context = tracked.context

        await context.sut.load()

        #expect(context.sut.flights.count == 1)
        #expect(context.sut.staleMessage == AppStrings.localized("flights.list.staleWarning"))
    }

    @Test("Given first page is still loading, when state is observed, then the initial skeleton state is exposed")
    func loadExposesInitialSkeletonStateWhileFirstPageIsPending() async {
        let passengerID = PassengerID("PAX-001")
        let tracked = makeSessionBoundFlightListViewModelSUT(
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
                sourceLocation: #_sourceLocation
        )
        defer { tracked.assertNoLeaks() }
        let context = tracked.context

        let task = Task {
            await context.sut.load()
        }
        await Task.yield()

        #expect(context.sut.isShowingInitialSkeleton)

        await task.value

        #expect(context.sut.isShowingInitialSkeleton == false)
    }

    @Test("Given configured minimum skeleton duration, when first page resolves immediately, then the skeleton remains visible until the minimum time elapses")
    func loadKeepsSkeletonVisibleForMinimumDuration() async {
        let passengerID = PassengerID("PAX-001")
        let tracked = makeSessionBoundFlightListViewModelSUT(
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
                sourceLocation: #_sourceLocation
        )
        defer { tracked.assertNoLeaks() }
        let context = tracked.context
        let clock = ContinuousClock()
        let startedAt = clock.now

        await context.sut.load()
        let elapsed = startedAt.duration(to: clock.now)

        #expect(elapsed >= .milliseconds(200))
        #expect(context.sut.isShowingInitialSkeleton == false)
    }

    @Test("Given long list, when loading first page, then exposes first block and pagination state")
    func loadUsesFirstPageAndPaginationState() async {
        let passengerID = PassengerID("PAX-001")
        let tracked = await makeConfiguredSessionBoundFlightListViewModelSUT(
            passengerID: passengerID,
            sourceLocation: #_sourceLocation,
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
        defer { tracked.assertNoLeaks() }
        let context = tracked.context

        await context.sut.load()

        #expect(context.sut.flights.map { $0.id.value } == makeFlightIDs(range: 1...10))
        #expect(context.sut.canLoadMorePages)
        let requestedPages = await context.listUseCase.executePages
        #expect(requestedPages == [1])
    }
}
