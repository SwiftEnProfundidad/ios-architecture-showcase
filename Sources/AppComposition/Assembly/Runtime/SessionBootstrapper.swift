import AuthFeature
import SharedNavigation

struct SessionBootstrapper<Store: SessionReading & SessionClearing> {
    private let sessionStore: Store
    private let stateStore: AppStateStore
    private let policy: SessionLaunchPolicy

    init(
        sessionStore: Store,
        stateStore: AppStateStore,
        policy: SessionLaunchPolicy
    ) {
        self.sessionStore = sessionStore
        self.stateStore = stateStore
        self.policy = policy
    }

    func bootstrap() async {
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
