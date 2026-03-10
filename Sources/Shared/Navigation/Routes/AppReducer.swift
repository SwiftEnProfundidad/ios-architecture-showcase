import SharedKernel

public struct AppReducer: Sendable {

    public init() {}

    public func reduce(_ state: AppState, event: NavigationEvent) -> AppState {
        switch event {
        case .loginSuccess(let passengerID, _):
            return AppState(route: .flightList, isAuthenticated: true, passengerID: passengerID)
        case .logout, .sessionExpired:
            return AppState(route: .login, isAuthenticated: false, passengerID: nil)
        case .loginFailure:
            return AppState(route: .login, isAuthenticated: false, passengerID: nil)
        case .showFlightDetail(let flightID):
            return AppState(route: .flightDetail(flightID), isAuthenticated: state.isAuthenticated, passengerID: state.passengerID)
        case .showBoardingPass(let flightID):
            return AppState(route: .boardingPass(flightID), isAuthenticated: state.isAuthenticated, passengerID: state.passengerID)
        case .backToFlightList:
            return AppState(route: .flightList, isAuthenticated: state.isAuthenticated, passengerID: state.passengerID)
        case .backToFlightDetail(let flightID):
            return AppState(route: .flightDetail(flightID), isAuthenticated: state.isAuthenticated, passengerID: state.passengerID)
        }
    }
}
