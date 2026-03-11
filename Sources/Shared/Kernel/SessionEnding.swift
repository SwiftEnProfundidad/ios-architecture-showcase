public protocol SessionEnding: Sendable {
    func endSession() async
}
