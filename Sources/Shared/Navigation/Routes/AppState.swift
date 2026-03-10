import SharedKernel

public struct AppState: Sendable, Equatable {
    public let route: AppRoute
    public let isAuthenticated: Bool
    public let passengerID: PassengerID?

    public init(route: AppRoute, isAuthenticated: Bool, passengerID: PassengerID?) {
        self.route = route
        self.isAuthenticated = isAuthenticated
        self.passengerID = passengerID
    }

    public static let initial = AppState(
        route: .login,
        isAuthenticated: false,
        passengerID: nil
    )
}
