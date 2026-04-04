import Foundation
import SharedKernel
import SharedNavigation

@MainActor
public protocol FlightListSessionControlling: Sendable {
    func ensureActiveSession() async -> Bool
    func logoutUser() async
}

@MainActor
public final class FlightListSessionController<LogoutExecutor: SessionEnding>: FlightListSessionControlling {
    private let logoutUseCase: LogoutExecutor
    private let eventBus: NavigationEventPublishing
    private let sessionExpiresAt: Date
    private let currentDateProvider: () -> Date

    public init(
        logoutUseCase: LogoutExecutor,
        eventBus: NavigationEventPublishing,
        sessionExpiresAt: Date,
        currentDateProvider: @escaping () -> Date = { .now }
    ) {
        self.logoutUseCase = logoutUseCase
        self.eventBus = eventBus
        self.sessionExpiresAt = sessionExpiresAt
        self.currentDateProvider = currentDateProvider
    }

    public func ensureActiveSession() async -> Bool {
        guard sessionExpiresAt <= currentDateProvider() else {
            return true
        }
        await logoutUseCase.endSession()
        await eventBus.publish(.sessionEnded(.expired))
        return false
    }

    public func logoutUser() async {
        await logoutUseCase.endSession()
        await eventBus.publish(.sessionEnded(.userInitiated))
    }
}
