import SharedNavigation

@MainActor
public struct ProtectedPathCommandChannel {
    private let publish: @Sendable ([AppRoute]) async -> Void

    public init(publish: @escaping @Sendable ([AppRoute]) async -> Void) {
        self.publish = publish
    }

    public func synchronize(
        visiblePath: [AppRoute],
        projectedPath: [AppRoute]
    ) async {
        guard visiblePath != projectedPath else {
            return
        }
        await publish(visiblePath)
    }
}
