import SharedKernel
import SharedNavigation
import Testing

@Suite("ProtectedNavigationPolicy")
struct ProtectedNavigationPolicyTests {

    @Test("Expired protected navigation invalidates persistence and resets state")
    func expiredProtectedNavigationInvalidatesPersistence() throws {
        let sut = ProtectedNavigationPolicy()
        let expiredState = AppState(
            rootRoute: .authenticatedHome,
            session: AppSession(
                passengerID: PassengerID("PAX-001"),
                token: "tok-expired",
                expiresAt: .distantPast
            ),
            path: []
        )

        let decision = sut.evaluate(
            current: expiredState,
            event: .requestProtectedPath([.primaryDetail(contextID: "IB3456")])
        )
        let resolvedDecision = try #require(decision)

        #expect(resolvedDecision.nextState == .initial)
        #expect(resolvedDecision.shouldInvalidatePersistedSession)
    }

    @Test("Valid protected navigation keeps the session and does not invalidate persistence")
    func validProtectedNavigationKeepsSession() throws {
        let sut = ProtectedNavigationPolicy()
        let session = AppSession(
            passengerID: PassengerID("PAX-001"),
            token: "tok-valid",
            expiresAt: fixedDate(hour: 12, minute: 0)
        )

        let decision = sut.evaluate(
            current: AppState(
                rootRoute: .authenticatedHome,
                session: session,
                path: []
            ),
            event: .requestProtectedPath([.secondaryAttachment(contextID: "IB3456")])
        )
        let resolvedDecision = try #require(decision)

        #expect(resolvedDecision.nextState.rootRoute == .authenticatedHome)
        #expect(resolvedDecision.nextState.session == session)
        #expect(resolvedDecision.nextState.path == [
            .primaryDetail(contextID: "IB3456"),
            .secondaryAttachment(contextID: "IB3456")
        ])
        #expect(resolvedDecision.shouldInvalidatePersistedSession == false)
    }
}
