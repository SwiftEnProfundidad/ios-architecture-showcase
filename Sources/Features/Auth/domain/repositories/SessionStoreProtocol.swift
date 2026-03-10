public protocol SessionStoreProtocol: Sendable {
    func save(token: String) async
    func currentToken() async -> String?
    func clear() async
}
