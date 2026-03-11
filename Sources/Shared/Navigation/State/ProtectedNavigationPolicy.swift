public struct ProtectedNavigationDecision: Sendable, Equatable {
    public let nextState: AppState
    public let shouldInvalidatePersistedSession: Bool

    public init(nextState: AppState, shouldInvalidatePersistedSession: Bool) {
        self.nextState = nextState
        self.shouldInvalidatePersistedSession = shouldInvalidatePersistedSession
    }
}

public struct ProtectedNavigationPolicy: Sendable {
    public init() {}

    public func evaluate(
        current: AppState,
        event: NavigationEvent
    ) -> ProtectedNavigationDecision? {
        switch event {
        case .requestProtectedPath(let path), .syncProtectedPath(let path):
            return decision(
                current: current,
                requestedPath: path
            )
        case .sessionStarted, .sessionEnded, .sessionStartRejected:
            return nil
        }
    }

    private func decision(
        current: AppState,
        requestedPath: [AppRoute]
    ) -> ProtectedNavigationDecision {
        guard let session = current.session else {
            return ProtectedNavigationDecision(
                nextState: .initial,
                shouldInvalidatePersistedSession: false
            )
        }

        guard session.isExpired == false else {
            return ProtectedNavigationDecision(
                nextState: .initial,
                shouldInvalidatePersistedSession: true
            )
        }

        return ProtectedNavigationDecision(
            nextState: AppState(
                rootRoute: .authenticatedHome,
                session: session,
                path: normalizedPath(requestedPath)
            ),
            shouldInvalidatePersistedSession: false
        )
    }

    private func normalizedPath(_ path: [AppRoute]) -> [AppRoute] {
        var normalized: [AppRoute] = []
        for route in path {
            switch route {
            case .primaryDetail(let contextID):
                normalized = [.primaryDetail(contextID: contextID)]
            case .secondaryAttachment(let contextID):
                if normalized.last != .primaryDetail(contextID: contextID) {
                    normalized = [.primaryDetail(contextID: contextID)]
                }
                normalized.append(.secondaryAttachment(contextID: contextID))
            }
        }
        return normalized
    }
}
