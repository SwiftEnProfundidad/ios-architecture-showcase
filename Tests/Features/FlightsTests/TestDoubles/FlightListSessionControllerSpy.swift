import FlightsFeature

@MainActor
final class FlightListSessionControllerSpy: FlightListSessionControlling {
    private(set) var ensureActiveSessionCallCount = 0
    private(set) var logoutCallCount = 0
    var isSessionActive = true

    func ensureActiveSession() async -> Bool {
        ensureActiveSessionCallCount += 1
        return isSessionActive
    }

    func logoutUser() async {
        logoutCallCount += 1
    }
}
