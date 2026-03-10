
public enum NavigationEvent: Sendable, Equatable {
    case loginSuccess(passengerID: PassengerID, token: String)
    case loginFailure
    case logout
    case sessionExpired
    case showFlightDetail(flightID: FlightID)
    case showBoardingPass(flightID: FlightID)
    case backToFlightList
    case backToFlightDetail(flightID: FlightID)
}
