import FlightsFeature
import Foundation
import SharedKernel
import Testing

@MainActor
@Suite("FlightListViewModel.Loading")
struct FlightListViewModelLoadingTests {

    @Test("Given stale cache result, when loading, then stale warning is exposed")
    func loadExposesStaleWarning() async {
        let tracked = await makeStaleCacheFlightListLoadingSUT(sourceLocation: #_sourceLocation)
        defer { tracked.assertNoLeaks() }
        let context = tracked.context

        await context.sut.load()

        #expect(context.sut.flights.count == 1)
        #expect(context.sut.staleMessage == AppStrings.localized("flights.list.staleWarning"))
    }

    @Test("Given first page is still loading, when state is observed, then the initial skeleton state is exposed")
    func loadExposesInitialSkeletonStateWhileFirstPageIsPending() async {
        let tracked = makePendingFirstPageFlightListLoadingSUT(sourceLocation: #_sourceLocation)
        defer { tracked.assertNoLeaks() }
        let context = tracked.context

        let task = Task {
            await context.sut.load()
        }
        await context.listUseCase.awaitExecuteCall()

        #expect(context.sut.isShowingInitialSkeleton)

        await context.listUseCase.resumeExecute()
        await task.value

        #expect(context.sut.isShowingInitialSkeleton == false)
    }

    @Test("Given configured minimum skeleton duration, when first page resolves immediately, then the skeleton remains visible until the minimum time elapses")
    func loadKeepsSkeletonVisibleForMinimumDuration() async {
        let testClock = ImmediateTestClock()
        let tracked = makeMinimumSkeletonFlightListLoadingSUT(
            clock: testClock,
            sourceLocation: #_sourceLocation
        )
        defer { tracked.assertNoLeaks() }
        let context = tracked.context

        await context.sut.load()

        let elapsed = testClock.now.offset
        #expect(elapsed >= .nanoseconds(250_000_000))
        #expect(context.sut.isShowingInitialSkeleton == false)
        #expect(context.sut.flights.isEmpty == false)
    }

    @Test("Given long list, when loading first page, then exposes first block and pagination state")
    func loadUsesFirstPageAndPaginationState() async {
        let tracked = await makeFirstPagePaginationFlightListLoadingSUT(sourceLocation: #_sourceLocation)
        defer { tracked.assertNoLeaks() }
        let context = tracked.context

        await context.sut.load()

        #expect(context.sut.flights.map { $0.id.value } == makeFlightIDs(range: 1...10))
        #expect(context.sut.canLoadMorePages)
        let requestedPages = await context.listUseCase.executePages
        #expect(requestedPages == [1])
    }
}
