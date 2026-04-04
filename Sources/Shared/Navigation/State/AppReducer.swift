public struct AppReducer: Sendable {
    private let protectedNavigationPolicy: ProtectedNavigationPolicy

    public init(protectedNavigationPolicy: ProtectedNavigationPolicy = ProtectedNavigationPolicy()) {
        self.protectedNavigationPolicy = protectedNavigationPolicy
    }

    public func reduce(_ state: AppState, event: NavigationEvent) -> AppState {
        if let decision = protectedNavigationPolicy.evaluate(current: state, event: event) {
            return decision.nextState
        }

        switch event {
        case .sessionStarted(let session):
            return AppState(
                rootRoute: .authenticatedHome,
                session: session,
                path: []
            )
        case .sessionEnded:
            return .initial
        case .sessionStartRejected:
            return state
        case .syncProtectedPath, .requestProtectedPath:
            return state
        }
    }
}
