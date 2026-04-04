import FlightsFeature
import Foundation
import SharedKernel
import SharedNavigation
import Testing

@MainActor
@Suite("FlightListSessionController")
struct FlightListSessionControllerTests {

    @Test("Given the session is expired, when handled, then the stored session ends and SessionExpired is published")
    func ensureActiveSessionInvalidatesExpiredSession() async {
        let tracked = makeFlightListSessionControllerSUT(sessionExpiresAt: .distantPast)
        defer { tracked.assertNoLeaks() }
        let context = tracked.context

        let isActive = await context.sut.ensureActiveSession()

        #expect(isActive == false)
        #expect(await context.logoutUseCase.endSessionCallCount == 1)
        #expect(await context.bus.lastPublishedEvent == .sessionEnded(.expired))
    }

    @Test("Given the user logs out manually, when handled, then the stored session ends and user-initiated termination is published")
    func logoutPublishesUserInitiatedTermination() async {
        let tracked = makeFlightListSessionControllerSUT(sessionExpiresAt: .distantFuture)
        defer { tracked.assertNoLeaks() }
        let context = tracked.context

        await context.sut.logoutUser()

        #expect(await context.logoutUseCase.endSessionCallCount == 1)
        #expect(await context.bus.lastPublishedEvent == .sessionEnded(.userInitiated))
    }
}
