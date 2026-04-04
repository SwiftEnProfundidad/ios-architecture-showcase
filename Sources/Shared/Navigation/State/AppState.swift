public struct AppState: Sendable, Equatable {
    public let rootRoute: RootRoute
    public let session: AppSession?
    public let path: [AppRoute]

    public init(rootRoute: RootRoute, session: AppSession?, path: [AppRoute]) {
        self.rootRoute = rootRoute
        self.session = session
        self.path = path
    }

    public static let initial = AppState(
        rootRoute: .login,
        session: nil,
        path: []
    )

    public var isAuthenticated: Bool {
        session?.isExpired() == false
    }
}
