import AuthFeature
import SharedNavigation

@MainActor
public struct SessionBootstrapper {
    private let sessionStore: any SessionReading & SessionClearing
    private let stateStore: AppStateStore
    private let policy: SessionLaunchPolicy

    public init(
        sessionStore: any SessionReading & SessionClearing,
        stateStore: AppStateStore,
        policy: SessionLaunchPolicy
    ) {
        self.sessionStore = sessionStore
        self.stateStore = stateStore
        self.policy = policy
    }

    public func bootstrap() async {
        guard policy == .restoreValidSession else {
            await sessionStore.clear()
            return
        }
        await restoreSessionIfAvailable()
    }

    private func restoreSessionIfAvailable() async {
        guard let storedSession = await sessionStore.currentSession() else {
            return
        }
        guard storedSession.expiresAt > .now else {
            await sessionStore.clear()
            return
        }
        await stateStore.apply(
            AppState(
                rootRoute: .authenticatedHome,
                session: AppSession(
                    passengerID: storedSession.passengerID,
                    token: storedSession.token,
                    expiresAt: storedSession.expiresAt
                ),
                path: []
            )
        )
    }
}
