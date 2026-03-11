import FlightsFeature
import Foundation
import SharedKernel
import Testing

@MainActor
@Suite("FlightListViewModel.Session")
struct FlightListViewModelSessionTests {

    @Test("When logout is requested, the view model delegates to the session controller")
    func logoutDelegatesToSessionController() async {
        let tracked = makeControlledFlightListViewModelSUT(
            listUseCase: ListFlightsUseCaseSpy(),
            sourceLocation: #_sourceLocation
        )
        defer { tracked.assertNoLeaks() }
        let context = tracked.context

        await context.sut.logout()

        #expect(context.sessionController.logoutCallCount == 1)
        let loadCallCount = await context.listUseCase.executePages.count
        #expect(loadCallCount == 0)
    }

    @Test("Given expired session, when loading, then SessionExpired is published")
    func loadPublishesSessionExpiredWhenSessionHasExpired() async {
        let tracked = makeExpiredSessionFlightListViewModelSUT(sourceLocation: #_sourceLocation)
        defer { tracked.assertNoLeaks() }
        let context = tracked.context

        await context.sut.load()

        #expect(await context.eventBus.lastPublishedEvent == .sessionEnded(.expired))
        #expect(await context.logoutUseCase.endSessionCallCount == 1)
        let loadCallCount = await context.listUseCase.executePages.count
        #expect(loadCallCount == 0)
    }

    @Test("Given session expires while page load is suspended, when the page returns, then flights are discarded and SessionExpired is published")
    func loadDiscardsFlightsIfSessionExpiresDuringSuspendedPageLoad() async {
        let tracked = makeExpiringDuringLoadFlightListViewModelSUT(sourceLocation: #_sourceLocation)
        defer { tracked.assertNoLeaks() }
        let context = tracked.context

        await context.sut.load()

        #expect(context.sut.flights.isEmpty)
        #expect(await context.eventBus.lastPublishedEvent == .sessionEnded(.expired))
        #expect(await context.logoutUseCase.endSessionCallCount == 1)
    }

    @Test("Given session expires while refresh is suspended, when the refresh returns, then refreshed flights are discarded and SessionExpired is published")
    func refreshDiscardsFlightsIfSessionExpiresDuringSuspendedRefresh() async {
        let scenario = makeExpiringDuringRefreshFlightListViewModelSUT(sourceLocation: #_sourceLocation)
        let tracked = scenario.tracked
        defer { tracked.assertNoLeaks() }
        let context = tracked.context

        await context.sut.load()
        #expect(context.sut.flights.first?.status == .onTime)
        scenario.currentDate.value = scenario.currentDate.value.addingTimeInterval(0.2)

        await context.sut.refresh()

        #expect(context.sut.flights.first?.status == .onTime)
        #expect(await context.eventBus.lastPublishedEvent == .sessionEnded(.expired))
        #expect(await context.logoutUseCase.endSessionCallCount == 1)
    }
}
