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
        let logoutUseCase = FlightListLogoutUseCaseSpy()
        let bus = NavigationEventBusSpy()
        let sut = FlightListSessionController(
            logoutUseCase: logoutUseCase,
            eventBus: bus,
            sessionExpiresAt: Date.distantPast
        )

        let isActive = await sut.ensureActiveSession()

        #expect(isActive == false)
        #expect(await logoutUseCase.endSessionCallCount == 1)
        #expect(await bus.lastPublishedEvent == .sessionEnded(.expired))
    }

    @Test("Manual logout ends the stored session and publishes user initiated termination")
    func logoutPublishesUserInitiatedTermination() async {
        let logoutUseCase = FlightListLogoutUseCaseSpy()
        let bus = NavigationEventBusSpy()
        let sut = FlightListSessionController(
            logoutUseCase: logoutUseCase,
            eventBus: bus,
            sessionExpiresAt: Date.distantFuture
        )

        await sut.logoutUser()

        #expect(await logoutUseCase.endSessionCallCount == 1)
        #expect(await bus.lastPublishedEvent == .sessionEnded(.userInitiated))
    }
}

private actor FlightListLogoutUseCaseSpy: SessionEnding {
    private(set) var endSessionCallCount = 0

    func endSession() async {
        endSessionCallCount += 1
    }
}
