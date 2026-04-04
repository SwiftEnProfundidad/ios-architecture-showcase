import SharedKernel
import SwiftUI

public struct FlightStatusPresentation {
    public enum Tint: String, Sendable, Equatable {
        case success
        case accent
        case warning
        case neutral
        case danger

        var color: Color {
            switch self {
            case .success: .green
            case .accent: .blue
            case .warning: .orange
            case .neutral: .gray
            case .danger: .red
            }
        }
    }

    public let title: String
    public let tint: Tint

    public init(status: Flight.Status) {
        switch status {
        case .onTime:
            title = AppStrings.localized("flights.status.onTime")
            tint = .success
        case .delayed:
            title = AppStrings.localized("flights.status.delayed")
            tint = .warning
        case .boarding:
            title = AppStrings.localized("flights.status.boarding")
            tint = .accent
        case .departed:
            title = AppStrings.localized("flights.status.departed")
            tint = .neutral
        case .cancelled:
            title = AppStrings.localized("flights.status.cancelled")
            tint = .danger
        }
    }
}
