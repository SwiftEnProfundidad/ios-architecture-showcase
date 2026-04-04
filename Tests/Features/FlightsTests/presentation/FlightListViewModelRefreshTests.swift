import FlightsFeature
import SharedKernel
import Testing

@MainActor
@Suite("FlightListViewModel.Refresh")
struct FlightListViewModelRefreshTests {

    @Test("Given paginated list, when refreshing, then visible flights are refreshed and length is preserved")
    func refreshPreservesLoadedLength() async {
        let tracked = await makePaginatedRefreshFlightListViewModelSUT(sourceLocation: #_sourceLocation)
        defer { tracked.assertNoLeaks() }
        let context = tracked.context

        await context.sut.load()
        await context.sut.loadNextPage()
        await context.sut.refresh()

        #expect(context.sut.flights.count == 4)
        #expect(context.sut.flights.first?.status == .boarding)
        #expect(context.sut.flights.last?.status == .delayed)
        let refreshedIDs = await context.listUseCase.lastRefreshFlightIDs
        #expect(refreshedIDs?.map { $0.value } == ["IB1001", "IB1002", "IB1003", "IB1004"])
    }

    @Test("Given stale cached flights, when refresh fails, then the stale warning remains visible")
    func refreshPreservesStaleWarningAfterFailure() async {
        let tracked = await makeStaleRefreshFailureFlightListViewModelSUT(sourceLocation: #_sourceLocation)
        defer { tracked.assertNoLeaks() }
        let context = tracked.context

        await context.sut.load()
        await context.sut.refresh()

        #expect(context.sut.flights.map { $0.id.value } == ["IB1001"])
        #expect(context.sut.errorMessage == AppStrings.localized("flights.error.load"))
        #expect(context.sut.staleMessage == AppStrings.localized("flights.list.staleWarning"))
    }
}
