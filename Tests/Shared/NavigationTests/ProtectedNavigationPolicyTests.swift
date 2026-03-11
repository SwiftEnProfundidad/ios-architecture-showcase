import SharedKernel
import SharedNavigation
import Testing

@Suite("ProtectedNavigationPolicy")
struct ProtectedNavigationPolicyTests {

    @Test("Expired protected navigation invalidates persistence and resets state")
    func expiredProtectedNavigationInvalidatesPersistence() throws {
        let sut = makeProtectedNavigationPolicySUT()
        let expiredState = makeExpiredProtectedNavigationState()

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
        let sut = makeProtectedNavigationPolicySUT()
        let validState = makeValidProtectedNavigationState()

        let decision = sut.evaluate(
            current: validState,
            event: .requestProtectedPath([.secondaryAttachment(contextID: "IB3456")])
        )
        let resolvedDecision = try #require(decision)

        #expect(resolvedDecision.nextState.rootRoute == .authenticatedHome)
        #expect(resolvedDecision.nextState.session == validState.session)
        #expect(resolvedDecision.nextState.path == [
            .primaryDetail(contextID: "IB3456"),
            .secondaryAttachment(contextID: "IB3456")
        ])
        #expect(resolvedDecision.shouldInvalidatePersistedSession == false)
    }
}
