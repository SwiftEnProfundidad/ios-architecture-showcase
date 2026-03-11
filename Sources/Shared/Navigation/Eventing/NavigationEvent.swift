
public enum NavigationEvent: Sendable, Equatable {
    case sessionStarted(AppSession)
    case sessionStartRejected
    case sessionEnded(SessionTerminationReason)
    case requestProtectedPath([AppRoute])
    case syncProtectedPath([AppRoute])
}

public enum SessionTerminationReason: Sendable, Equatable {
    case userInitiated
    case expired
}
