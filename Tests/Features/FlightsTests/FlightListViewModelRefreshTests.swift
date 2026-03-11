import FlightsFeature
import SharedKernel
import Testing

@MainActor
@Suite("FlightListViewModel.Refresh")
struct FlightListViewModelRefreshTests {

    @Test("Given paginated list, when refreshing, then visible flights are refreshed and length is preserved")
    func refreshPreservesLoadedLength() async {
        let tracked = await makeSUT(
            configure: { listUseCase in
                await listUseCase.stubPage(
                    result: makePageResult(
                        flightIDs: ["IB1001", "IB1002"],
                        passengerID: defaultFlightListPassengerID,
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
                        passengerID: defaultFlightListPassengerID,
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
                        passengerID: defaultFlightListPassengerID
                    )
                )
            },
            sourceLocation: #_sourceLocation
        )
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
        let tracked = await makeSUT(
            configure: { listUseCase in
                await listUseCase.stubPage(
                    result: makePageResult(
                        flightIDs: ["IB1001"],
                        passengerID: defaultFlightListPassengerID,
                        source: .cache,
                        isStale: true,
                        page: 1,
                        hasMorePages: false
                    ),
                    for: 1
                )
                await listUseCase.stubRefreshError(FlightListFailure())
            },
            sourceLocation: #_sourceLocation
        )
        defer { tracked.assertNoLeaks() }
        let context = tracked.context

        await context.sut.load()
        await context.sut.refresh()

        #expect(context.sut.flights.map { $0.id.value } == ["IB1001"])
        #expect(context.sut.errorMessage == AppStrings.localized("flights.error.load"))
        #expect(context.sut.staleMessage == AppStrings.localized("flights.list.staleWarning"))
    }

    private func makeSUT(
        passengerID: PassengerID = defaultFlightListPassengerID,
        configure: (ListFlightsUseCaseSpy) async -> Void,
        sourceLocation: SourceLocation
    ) async -> TrackedTestContext<SessionBoundFlightListViewModelTestContext<ListFlightsUseCaseSpy, LogoutUseCaseSpy>> {
        await makeConfiguredSessionBoundFlightListViewModelSUT(
            passengerID: passengerID,
            sourceLocation: sourceLocation,
            configure: configure
        )
    }
}
