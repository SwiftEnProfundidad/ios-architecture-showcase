
public struct AuthSession: Sendable, Equatable {
    public let passengerID: PassengerID
    public let token: String

    public init(passengerID: PassengerID, token: String) {
        self.passengerID = passengerID
        self.token = token
    }
}
