import SharedKernel
import SharedNavigation

func makeAppReducerSUT() -> AppReducer {
    AppReducer()
}

func makeAuthenticatedNavigationState() -> AppState {
    AppState(
        rootRoute: .authenticatedHome,
        session: AppSession(
            passengerID: PassengerID("PAX-001"),
            token: "tok-abc",
            expiresAt: fixedDate(hour: 12, minute: 0)
        ),
        path: []
    )
}
