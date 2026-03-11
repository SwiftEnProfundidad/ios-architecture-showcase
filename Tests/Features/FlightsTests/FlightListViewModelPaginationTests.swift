import FlightsFeature
import SharedKernel
import Testing

@MainActor
@Suite("FlightListViewModel.Pagination")
struct FlightListViewModelPaginationTests {

    @Test("Given additional cached page, when loading next page, then appends the next ten flights without duplicates")
    func loadNextPageAppendsFlightsWithoutDuplicates() async {
        let tracked = await makeCachedSecondPageFlightListViewModelSUT(sourceLocation: #_sourceLocation)
        defer { tracked.assertNoLeaks() }
        let context = tracked.context

        await context.sut.load()
        await context.sut.loadNextPage()

        #expect(context.sut.flights.map { $0.id.value } == makeFlightIDs(range: 1...20))
        #expect(context.sut.canLoadMorePages)
        #expect(context.sut.staleMessage == AppStrings.localized("flights.list.staleWarning"))
        let requestedPages = await context.listUseCase.executePages
        #expect(requestedPages == [1, 2])
    }

    @Test("Given the passenger has not reached the pagination footer, when the next page is not requested explicitly, then only the first page stays visible")
    func loadDoesNotRequestTheNextPageBeforeThePaginationFooter() async {
        let tracked = await makeFirstPageOnlyFlightListViewModelSUT(sourceLocation: #_sourceLocation)
        defer { tracked.assertNoLeaks() }
        let context = tracked.context

        await context.sut.load()

        #expect(context.sut.flights.map { $0.id.value } == makeFlightIDs(range: 1...10))
        let requestedPages = await context.listUseCase.executePages
        #expect(requestedPages == [1])
    }

    @Test("Given the next page is still loading, when the request is in flight, then the inline pagination spinner state is exposed")
    func loadNextPageExposesInlineSpinnerState() async {
        let tracked = makeInlineSpinnerPaginationFlightListViewModelSUT(sourceLocation: #_sourceLocation)
        defer { tracked.assertNoLeaks() }
        let context = tracked.context

        await context.sut.load()

        let task = Task {
            await context.sut.loadNextPage()
        }
        await context.listUseCase.awaitSecondPageRequest()
        await Task.yield()

        #expect(context.sut.isLoadingNextPage)
        #expect(context.sut.flights.map { $0.id.value } == makeFlightIDs(range: 1...10))

        await context.listUseCase.finishSecondPageRequest()
        await task.value

        #expect(context.sut.isLoadingNextPage == false)
        #expect(context.sut.flights.map { $0.id.value } == makeFlightIDs(range: 1...20))
    }
}
