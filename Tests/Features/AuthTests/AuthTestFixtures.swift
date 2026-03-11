import AuthFeature
import SharedKernel

func makeAuthSession(
    passengerID: PassengerID = PassengerID("PAX-001"),
    token: String = "tok-abc",
    hour: Int = 12,
    minute: Int = 0
) -> AuthSession {
    AuthSession(
        passengerID: passengerID,
        token: token,
        expiresAt: fixedDate(hour: hour, minute: minute)
    )
}
