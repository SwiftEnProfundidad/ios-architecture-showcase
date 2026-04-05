import SharedKernel
import SharedNavigation
import Testing

@Suite("ProtectedNavigationPolicy")
struct ProtectedNavigationPolicyTests {

    @Test("Given protected navigation has expired, when the policy is evaluated, then persistence is invalidated and state is reset")
    func expiredProtectedNavigationInvalidatesPersistence() throws {
        let sut = makeProtectedNavigationPolicySUT()
        let expiredState = makeExpiredProtectedNavigationState()

        let decision = sut.evaluate(
            current: expiredState,
            event: .requestProtectedPath([.primaryDetail(contextID: FlightID("IB3456"))])
        )
        let resolvedDecision = try #require(decision)

        #expect(resolvedDecision.nextState == .initial)
        #expect(resolvedDecision.shouldInvalidatePersistedSession)
    }

    @Test("Given protected navigation is still valid, when the policy is evaluated, then the session is preserved and persistence is not invalidated")
    func validProtectedNavigationKeepsSession() throws {
        let sut = makeProtectedNavigationPolicySUT()
        let validState = makeValidProtectedNavigationState()

        let decision = sut.evaluate(
            current: validState,
            event: .requestProtectedPath([.secondaryAttachment(contextID: FlightID("IB3456"))])
        )
        let resolvedDecision = try #require(decision)

        #expect(resolvedDecision.nextState.rootRoute == .authenticatedHome)
        #expect(resolvedDecision.nextState.session == validState.session)
        #expect(resolvedDecision.nextState.path == [
            .primaryDetail(contextID: FlightID("IB3456")),
            .secondaryAttachment(contextID: FlightID("IB3456"))
        ])
        #expect(resolvedDecision.shouldInvalidatePersistedSession == false)
    }
}
