import SharedKernel
import SharedNavigation
import Testing

@Suite("AppReducer")
struct AppReducerTests {

    @Test("Given login state, when SessionStarted, then session is stored and path is cleared")
    func sessionStartedStoresSession() {
        let sut = AppReducer()
        let passengerID = PassengerID("PAX-001")
        let expiresAt = fixedDate(hour: 12, minute: 0)
        let session = AppSession(passengerID: passengerID, token: "tok-abc", expiresAt: expiresAt)

        let result = sut.reduce(
            .initial,
            event: .sessionStarted(session)
        )

        #expect(result.rootRoute == .authenticatedHome)
        #expect(result.session == session)
        #expect(result.path.isEmpty)
        #expect(result.isAuthenticated)
    }

    @Test("Given authenticated state, when Logout, then state returns to initial")
    func logoutTransitionsToInitial() {
        let sut = AppReducer()
        let initial = authenticatedState()

        let result = sut.reduce(initial, event: .sessionEnded(.userInitiated))

        #expect(result == .initial)
    }

    @Test("Given authenticated state, when SessionExpired, then state returns to initial")
    func sessionExpiredTransitionsToInitial() {
        let sut = AppReducer()
        let initial = authenticatedState()

        let result = sut.reduce(initial, event: .sessionEnded(.expired))

        #expect(result == .initial)
    }

    @Test("Given authenticated state, when requesting the protected primary detail path, then path is replaced")
    func requestProtectedPrimaryDetailPath() {
        let sut = AppReducer()
        let contextID = "IB3456"

        let result = sut.reduce(
            authenticatedState(),
            event: .requestProtectedPath([.primaryDetail(contextID: contextID)])
        )

        #expect(result.rootRoute == .authenticatedHome)
        #expect(result.path == [.primaryDetail(contextID: contextID)])
    }

    @Test("Given authenticated state, when requesting a primary and secondary protected path, then it is normalized")
    func requestProtectedSecondaryPath() {
        let sut = AppReducer()
        let contextID = "IB3456"

        let result = sut.reduce(
            authenticatedState(),
            event: .requestProtectedPath([
                .primaryDetail(contextID: contextID),
                .secondaryAttachment(contextID: contextID)
            ])
        )

        #expect(result.rootRoute == .authenticatedHome)
        #expect(result.path == [.primaryDetail(contextID: contextID), .secondaryAttachment(contextID: contextID)])
    }

    @Test("Given unauthenticated state, protected navigation events do not modify the state")
    func unauthenticatedProtectedRoutesDoNotChangeState() {
        let sut = AppReducer()
        let contextID = "IB3456"

        let result = sut.reduce(.initial, event: .requestProtectedPath([.primaryDetail(contextID: contextID)]))

        #expect(result == .initial)
    }

    @Test("Reducer is a pure function: same input produces same output")
    func reducerIsPure() {
        let sut = AppReducer()
        let initial = authenticatedState()
        let event = NavigationEvent.requestProtectedPath([])

        let first = sut.reduce(initial, event: event)
        let second = sut.reduce(initial, event: event)

        #expect(first == second)
    }

    @Test("Given navigation stack, syncing the visible path rebuilds the expected protected stack")
    func syncProtectedPathProducesExpectedPath() {
        let sut = AppReducer()
        let contextID = "IB3456"
        let initial = AppState(
            rootRoute: .authenticatedHome,
            session: authenticatedState().session,
            path: [.primaryDetail(contextID: contextID), .secondaryAttachment(contextID: contextID)]
        )

        let detailState = sut.reduce(
            initial,
            event: .syncProtectedPath([.primaryDetail(contextID: contextID)])
        )
        let listState = sut.reduce(detailState, event: .syncProtectedPath([]))

        #expect(detailState.path == [.primaryDetail(contextID: contextID)])
        #expect(listState.path.isEmpty)
    }

    @Test("SyncProtectedPath normalizes protected stacks")
    func syncProtectedPathNormalizesProtectedStacks() {
        let sut = AppReducer()
        let contextID = "IB3456"

        let result = sut.reduce(
            authenticatedState(),
            event: .syncProtectedPath([.secondaryAttachment(contextID: contextID)])
        )

        #expect(result.path == [.primaryDetail(contextID: contextID), .secondaryAttachment(contextID: contextID)])
    }

    private func authenticatedState() -> AppState {
        AppState(
            rootRoute: .authenticatedHome,
            session: AppSession(
                passengerID: PassengerID("PAX-001"),
                token: "tok-abc",
                expiresAt: fixedDate(hour: 12, minute: 0)
            ),
            path: []
        )
    }
}
