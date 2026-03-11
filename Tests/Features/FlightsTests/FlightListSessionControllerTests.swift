import FlightsFeature
import Foundation
import SharedKernel
import SharedNavigation
import Testing

@MainActor
@Suite("FlightListSessionController")
struct FlightListSessionControllerTests {

    @Test("Expired session ends the stored session and publishes SessionExpired")
    func ensureActiveSessionInvalidatesExpiredSession() async {
        let tracked = makeFlightListSessionControllerSUT(sessionExpiresAt: .distantPast)
        defer { tracked.assertNoLeaks() }
        let context = tracked.context

        let isActive = await context.sut.ensureActiveSession()

        #expect(isActive == false)
        #expect(await context.logoutUseCase.endSessionCallCount == 1)
        #expect(await context.bus.lastPublishedEvent == .sessionEnded(.expired))
    }

    @Test("Manual logout ends the stored session and publishes user initiated termination")
    func logoutPublishesUserInitiatedTermination() async {
        let tracked = makeFlightListSessionControllerSUT(sessionExpiresAt: .distantFuture)
        defer { tracked.assertNoLeaks() }
        let context = tracked.context

        await context.sut.logoutUser()

        #expect(await context.logoutUseCase.endSessionCallCount == 1)
        #expect(await context.bus.lastPublishedEvent == .sessionEnded(.userInitiated))
    }
}
