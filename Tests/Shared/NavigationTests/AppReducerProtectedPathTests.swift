import SharedNavigation
import Testing

@Suite("AppReducer protected path")
struct AppReducerProtectedPathTests {

    @Test("Given authenticated state, when requesting the protected primary detail path, then path is replaced")
    func requestProtectedPrimaryDetailPath() {
        let sut = makeAppReducerSUT()
        let contextID = "IB3456"

        let result = sut.reduce(
            makeAuthenticatedNavigationState(),
            event: .requestProtectedPath([.primaryDetail(contextID: contextID)])
        )

        #expect(result.rootRoute == .authenticatedHome)
        #expect(result.path == [.primaryDetail(contextID: contextID)])
    }

    @Test("Given authenticated state, when requesting a primary and secondary protected path, then it is normalized")
    func requestProtectedSecondaryPath() {
        let sut = makeAppReducerSUT()
        let contextID = "IB3456"

        let result = sut.reduce(
            makeAuthenticatedNavigationState(),
            event: .requestProtectedPath([
                .primaryDetail(contextID: contextID),
                .secondaryAttachment(contextID: contextID)
            ])
        )

        #expect(result.rootRoute == .authenticatedHome)
        #expect(result.path == [.primaryDetail(contextID: contextID), .secondaryAttachment(contextID: contextID)])
    }

    @Test("Given unauthenticated state, when a protected navigation event is received, then the state remains unchanged")
    func unauthenticatedProtectedRoutesDoNotChangeState() {
        let sut = makeAppReducerSUT()
        let contextID = "IB3456"

        let result = sut.reduce(.initial, event: .requestProtectedPath([.primaryDetail(contextID: contextID)]))

        #expect(result == .initial)
    }

    @Test("Given a navigation stack with detail and attachment, when the visible path is synced progressively, then the stack is rebuilt as expected")
    func syncProtectedPathProducesExpectedPath() {
        let sut = makeAppReducerSUT()
        let contextID = "IB3456"
        let initial = AppState(
            rootRoute: .authenticatedHome,
            session: makeAuthenticatedNavigationState().session,
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

    @Test("Given a protected navigation stack, when SyncProtectedPath runs, then the stack is normalized as expected")
    func syncProtectedPathNormalizesProtectedStacks() {
        let sut = makeAppReducerSUT()
        let contextID = "IB3456"

        let result = sut.reduce(
            makeAuthenticatedNavigationState(),
            event: .syncProtectedPath([.secondaryAttachment(contextID: contextID)])
        )

        #expect(result.path == [.primaryDetail(contextID: contextID), .secondaryAttachment(contextID: contextID)])
    }
}
