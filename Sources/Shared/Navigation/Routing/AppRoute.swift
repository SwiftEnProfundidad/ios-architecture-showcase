import SharedKernel

public enum AppRoute: Sendable, Equatable, Hashable {
    case primaryDetail(contextID: FlightID)
    case secondaryAttachment(contextID: FlightID)
}
