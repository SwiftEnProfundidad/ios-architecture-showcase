import Testing
@testable import SharedNavigation
@testable import SharedKernel

@Suite("AppReducer")
struct AppReducerTests {

    private let sut = AppReducer()

    @Test("Dado estado login, cuando LoginSuccess, entonces estado flightList autenticado")
    func loginSuccessTransitionsToFlightList() {
        let initial = AppState(route: .login, isAuthenticated: false, passengerID: nil)
        let passengerID = PassengerID("PAX-001")

        let result = sut.reduce(initial, event: .loginSuccess(passengerID: passengerID, token: "tok-abc"))

        #expect(result.route == .flightList)
        #expect(result.isAuthenticated == true)
        #expect(result.passengerID == passengerID)
    }

    @Test("Dado estado autenticado, cuando Logout, entonces estado login no autenticado")
    func logoutTransitionsToLogin() {
        let initial = AppState(route: .flightList, isAuthenticated: true, passengerID: PassengerID("PAX-001"))

        let result = sut.reduce(initial, event: .logout)

        #expect(result.route == .login)
        #expect(result.isAuthenticated == false)
        #expect(result.passengerID == nil)
    }

    @Test("Dado estado autenticado, cuando SessionExpired, entonces estado login no autenticado")
    func sessionExpiredTransitionsToLogin() {
        let initial = AppState(route: .flightList, isAuthenticated: true, passengerID: PassengerID("PAX-001"))

        let result = sut.reduce(initial, event: .sessionExpired)

        #expect(result.route == .login)
        #expect(result.isAuthenticated == false)
    }

    @Test("Dado estado flightList, cuando ShowFlightDetail, entonces ruta es flightDetail")
    func showFlightDetailTransitionsToFlightDetail() {
        let flightID = FlightID("IB3456")
        let initial = AppState(route: .flightList, isAuthenticated: true, passengerID: PassengerID("PAX-001"))

        let result = sut.reduce(initial, event: .showFlightDetail(flightID: flightID))

        #expect(result.route == .flightDetail(flightID))
    }

    @Test("Dado estado flightDetail, cuando ShowBoardingPass, entonces ruta es boardingPass")
    func showBoardingPassTransitionsToBoardingPass() {
        let flightID = FlightID("IB3456")
        let initial = AppState(route: .flightDetail(flightID), isAuthenticated: true, passengerID: PassengerID("PAX-001"))

        let result = sut.reduce(initial, event: .showBoardingPass(flightID: flightID))

        #expect(result.route == .boardingPass(flightID))
    }

    @Test("Reducer es una función pura: mismo input produce mismo output")
    func reducerIsPure() {
        let initial = AppState(route: .login, isAuthenticated: false, passengerID: nil)
        let passengerID = PassengerID("PAX-001")
        let event = NavigationEvent.loginSuccess(passengerID: passengerID, token: "tok-abc")

        let first = sut.reduce(initial, event: event)
        let second = sut.reduce(initial, event: event)

        #expect(first == second)
    }

    @Test("Dado estado flightDetail, cuando BackToFlightList, entonces ruta es flightList")
    func backToFlightListTransitionsToFlightList() {
        let flightID = FlightID("IB3456")
        let initial = AppState(route: .flightDetail(flightID), isAuthenticated: true, passengerID: PassengerID("PAX-001"))

        let result = sut.reduce(initial, event: .backToFlightList)

        #expect(result.route == .flightList)
    }
}
