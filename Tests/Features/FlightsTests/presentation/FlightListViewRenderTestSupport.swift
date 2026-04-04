import FlightsFeature
import SharedKernel
import SharedNavigation
import Testing

@MainActor
struct FlightListViewRenderTestContext {
    let sut: FlightListViewModel<ListRenderExecutor, RenderSessionController, ContinuousClock>
    let executor: ListRenderExecutor
}

@MainActor
func makeFlightListRenderSUT(
    mode: FlightListRenderMode
) -> FlightListViewRenderTestContext {
    let executor = ListRenderExecutor(mode: mode)
    let eventBus = NavigationEventBusSpy()
    let sessionController = RenderSessionController()
    let sut = FlightListViewModel(
        listUseCase: executor,
        sessionController: sessionController,
        eventBus: eventBus,
        passengerID: PassengerID("PAX-001")
    )
    return FlightListViewRenderTestContext(sut: sut, executor: executor)
}

func makeRenderFlights(range: ClosedRange<Int>) -> [Flight] {
    let passengerID = PassengerID("PAX-001")
    return range.map { index in
        let status: Flight.Status
        switch index % 3 {
        case 0:
            status = .delayed
        case 1:
            status = .onTime
        default:
            status = .boarding
        }
        return Flight.stub(
            id: FlightID("IB\(1000 + index)"),
            passengerID: passengerID,
            status: status
        )
    }
}
