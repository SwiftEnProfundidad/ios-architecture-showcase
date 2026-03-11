import SharedNavigation

struct ProtectedPathCommandChannel {
    private let publish: @Sendable ([AppRoute]) async -> Void

    init(publish: @escaping @Sendable ([AppRoute]) async -> Void) {
        self.publish = publish
    }

    func synchronize(
        visiblePath: [AppRoute],
        projectedPath: [AppRoute]
    ) async {
        guard visiblePath != projectedPath else {
            return
        }
        await publish(visiblePath)
    }
}
