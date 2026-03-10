import Testing
@testable import iOSArchitectureShowcase

@Suite("AppReducer")
struct AppReducerTests {

    private let sut = AppReducer()

    @Test("Given login state, when LoginSuccess, then flight list state and authenticated")
    func loginSuccessTransitionsToFlightList() {
        let initial = AppState(route: .login, isAuthenticated: false, passengerID: nil)
        let passengerID = PassengerID("PAX-001")

        let result = sut.reduce(initial, event: .loginSuccess(passengerID: passengerID, token: "tok-abc"))

        #expect(result.route == .flightList)
        #expect(result.isAuthenticated == true)
        #expect(result.passengerID == passengerID)
    }

    @Test("Given authenticated state, when Logout, then login state and not authenticated")
    func logoutTransitionsToLogin() {
        let initial = AppState(route: .flightList, isAuthenticated: true, passengerID: PassengerID("PAX-001"))

        let result = sut.reduce(initial, event: .logout)

        #expect(result.route == .login)
        #expect(result.isAuthenticated == false)
        #expect(result.passengerID == nil)
    }

    @Test("Given authenticated state, when SessionExpired, then login state and not authenticated")
    func sessionExpiredTransitionsToLogin() {
        let initial = AppState(route: .flightList, isAuthenticated: true, passengerID: PassengerID("PAX-001"))

        let result = sut.reduce(initial, event: .sessionExpired)

        #expect(result.route == .login)
        #expect(result.isAuthenticated == false)
    }

    @Test("Given flight list state, when ShowFlightDetail, then route is flightDetail")
    func showFlightDetailTransitionsToFlightDetail() {
        let flightID = FlightID("IB3456")
        let initial = AppState(route: .flightList, isAuthenticated: true, passengerID: PassengerID("PAX-001"))

        let result = sut.reduce(initial, event: .showFlightDetail(flightID: flightID))

        #expect(result.route == .flightDetail(flightID))
    }

    @Test("Given flight detail state, when ShowBoardingPass, then route is boardingPass")
    func showBoardingPassTransitionsToBoardingPass() {
        let flightID = FlightID("IB3456")
        let initial = AppState(route: .flightDetail(flightID), isAuthenticated: true, passengerID: PassengerID("PAX-001"))

        let result = sut.reduce(initial, event: .showBoardingPass(flightID: flightID))

        #expect(result.route == .boardingPass(flightID))
    }

    @Test("Reducer is a pure function: same input produces same output")
    func reducerIsPure() {
        let initial = AppState(route: .login, isAuthenticated: false, passengerID: nil)
        let passengerID = PassengerID("PAX-001")
        let event = NavigationEvent.loginSuccess(passengerID: passengerID, token: "tok-abc")

        let first = sut.reduce(initial, event: event)
        let second = sut.reduce(initial, event: event)

        #expect(first == second)
    }

    @Test("Given flight detail state, when BackToFlightList, then route is flightList")
    func backToFlightListTransitionsToFlightList() {
        let flightID = FlightID("IB3456")
        let initial = AppState(route: .flightDetail(flightID), isAuthenticated: true, passengerID: PassengerID("PAX-001"))

        let result = sut.reduce(initial, event: .backToFlightList)

        #expect(result.route == .flightList)
    }
}
