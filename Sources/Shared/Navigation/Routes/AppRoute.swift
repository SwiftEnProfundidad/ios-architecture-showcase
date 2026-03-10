
public enum AppRoute: Sendable, Equatable {
    case login
    case flightList
    case flightDetail(FlightID)
    case boardingPass(FlightID)
}
