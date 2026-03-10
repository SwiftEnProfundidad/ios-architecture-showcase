public actor InMemorySessionStore: SessionStoreProtocol {
    private var token: String?

    public init() {}

    public func save(token: String) {
        self.token = token
    }

    public func currentToken() -> String? {
        token
    }

    public func clear() {
        token = nil
    }
}
