import Foundation
import SharedKernel

public struct Flight: Sendable, Equatable, Identifiable {
    public enum Status: Sendable, Equatable {
        case onTime
        case delayed
        case boarding
        case departed
        case cancelled
    }

    public let id: FlightID
    public let passengerID: PassengerID
    public let number: String
    public let origin: String
    public let destination: String
    public let status: Status
    public let scheduledDeparture: Date
    public let departureTimeZoneIdentifier: String
    public let gate: String

    public init(
        id: FlightID,
        passengerID: PassengerID,
        number: String,
        origin: String,
        destination: String,
        status: Status,
        scheduledDeparture: Date,
        departureTimeZoneIdentifier: String,
        gate: String
    ) {
        self.id = id
        self.passengerID = passengerID
        self.number = number
        self.origin = origin
        self.destination = destination
        self.status = status
        self.scheduledDeparture = scheduledDeparture
        self.departureTimeZoneIdentifier = departureTimeZoneIdentifier
        self.gate = gate
    }

    public func formattedScheduledDeparture(locale: Locale = .current) -> String {
        OperationalTimeFormatter.hourMinute(
            from: scheduledDeparture,
            timeZoneIdentifier: departureTimeZoneIdentifier,
            locale: locale
        )
    }
}
