import Foundation
import SharedKernel

public struct AppSession: Sendable, Equatable {
    public let passengerID: PassengerID
    public let token: String
    public let expiresAt: Date

    public init(passengerID: PassengerID, token: String, expiresAt: Date) {
        self.passengerID = passengerID
        self.token = token
        self.expiresAt = expiresAt
    }

    public var isExpired: Bool {
        expiresAt <= .now
    }
}
