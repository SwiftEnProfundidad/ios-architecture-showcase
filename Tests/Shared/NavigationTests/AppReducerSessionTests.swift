import SharedKernel
import SharedNavigation
import Testing

@Suite("AppReducer session")
struct AppReducerSessionTests {

    @Test("Given login state, when SessionStarted, then session is stored and path is cleared")
    func sessionStartedStoresSession() {
        let sut = makeAppReducerSUT()
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
        let sut = makeAppReducerSUT()

        let result = sut.reduce(makeAuthenticatedNavigationState(), event: .sessionEnded(.userInitiated))

        #expect(result == .initial)
    }

    @Test("Given authenticated state, when SessionExpired, then state returns to initial")
    func sessionExpiredTransitionsToInitial() {
        let sut = makeAppReducerSUT()

        let result = sut.reduce(makeAuthenticatedNavigationState(), event: .sessionEnded(.expired))

        #expect(result == .initial)
    }

    @Test("Given the same session state and event, when the reducer is applied twice, then both outputs are equal")
    func reducerIsPure() {
        let sut = makeAppReducerSUT()
        let initial = makeAuthenticatedNavigationState()
        let event = NavigationEvent.requestProtectedPath([])

        let first = sut.reduce(initial, event: event)
        let second = sut.reduce(initial, event: event)

        #expect(first == second)
    }
}
