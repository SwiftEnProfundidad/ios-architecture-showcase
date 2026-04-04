import SharedKernel

public protocol LogoutExecuting: SessionEnding {
    func execute() async
}

public struct LogoutUseCase<Store: SessionClearing>: Sendable {
    private let sessionStore: Store

    public init(sessionStore: Store) {
        self.sessionStore = sessionStore
    }

    public func execute() async {
        await sessionStore.clear()
    }
}

extension LogoutUseCase: LogoutExecuting {
    public func endSession() async {
        await execute()
    }
}
