import FlightsFeature
import Foundation
import SharedKernel
import Testing

@MainActor
@Suite("FlightListViewModel.Session")
struct FlightListViewModelSessionTests {

    @Test("When logout is requested, the view model delegates to the session controller")
    func logoutDelegatesToSessionController() async {
        let tracked = makeSUTForControlledSession(
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
        let tracked = makeExpiredSessionSUT(
            passengerID: defaultFlightListPassengerID,
            sourceLocation: #_sourceLocation
        )
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
        let tracked = makeExpiringDuringLoadSUT(
            passengerID: defaultFlightListPassengerID,
            sourceLocation: #_sourceLocation
        )
        defer { tracked.assertNoLeaks() }
        let context = tracked.context

        await context.sut.load()

        #expect(context.sut.flights.isEmpty)
        #expect(await context.eventBus.lastPublishedEvent == .sessionEnded(.expired))
        #expect(await context.logoutUseCase.endSessionCallCount == 1)
    }

    @Test("Given session expires while refresh is suspended, when the refresh returns, then refreshed flights are discarded and SessionExpired is published")
    func refreshDiscardsFlightsIfSessionExpiresDuringSuspendedRefresh() async {
        let scenario = makeExpiringDuringRefreshSUT(
            passengerID: defaultFlightListPassengerID,
            sourceLocation: #_sourceLocation
        )
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

    private func makeSUTForControlledSession(
        sourceLocation: SourceLocation
    ) -> TrackedTestContext<ControlledFlightListViewModelTestContext<ListFlightsUseCaseSpy>> {
        makeControlledFlightListViewModelSUT(
            listUseCase: ListFlightsUseCaseSpy(),
            sourceLocation: sourceLocation
        )
    }

    private func makeExpiredSessionSUT(
        passengerID: PassengerID,
        sourceLocation: SourceLocation
    ) -> TrackedTestContext<SessionBoundFlightListViewModelTestContext<ListFlightsUseCaseSpy, LogoutUseCaseSpy>> {
        makeSessionBoundFlightListViewModelSUT(
            listUseCase: ListFlightsUseCaseSpy(),
            logoutUseCase: LogoutUseCaseSpy(),
            passengerID: passengerID,
            sessionExpiresAt: .distantPast,
            sourceLocation: sourceLocation
        )
    }

    private func makeExpiringDuringLoadSUT(
        passengerID: PassengerID,
        sourceLocation: SourceLocation
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

    private func makeExpiringDuringRefreshSUT(
        passengerID: PassengerID,
        sourceLocation: SourceLocation
    ) -> ExpiringRefreshScenario {
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
        return ExpiringRefreshScenario(tracked: tracked, currentDate: currentDate)
    }

    private struct ExpiringRefreshScenario {
        let tracked: TrackedTestContext<
            SessionBoundFlightListViewModelTestContext<RefreshDelayListFlightsUseCaseSpy, LogoutUseCaseSpy>
        >
        let currentDate: CurrentDateStub
    }
}
