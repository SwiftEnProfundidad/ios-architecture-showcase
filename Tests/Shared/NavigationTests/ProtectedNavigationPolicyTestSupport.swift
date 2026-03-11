import SharedKernel
import SharedNavigation

func makeProtectedNavigationPolicySUT() -> ProtectedNavigationPolicy {
    ProtectedNavigationPolicy()
}

func makeExpiredProtectedNavigationState() -> AppState {
    AppState(
        rootRoute: .authenticatedHome,
        session: AppSession(
            passengerID: PassengerID("PAX-001"),
            token: "tok-expired",
            expiresAt: .distantPast
        ),
        path: []
    )
}

func makeValidProtectedNavigationState() -> AppState {
    AppState(
        rootRoute: .authenticatedHome,
        session: AppSession(
            passengerID: PassengerID("PAX-001"),
            token: "tok-valid",
            expiresAt: fixedDate(hour: 12, minute: 0)
        ),
        path: []
    )
}
