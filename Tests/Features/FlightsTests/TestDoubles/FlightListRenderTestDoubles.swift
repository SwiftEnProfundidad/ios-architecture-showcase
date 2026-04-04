import FlightsFeature
import SharedKernel

enum FlightListRenderMode {
    case initialSkeleton(FlightListResult)
    case content(FlightListResult)
    case paginating(firstPage: FlightListResult, secondPage: FlightListResult)
    case emptyError(Error)
    case refreshError(firstPage: FlightListResult, refreshError: Error)
}

actor ListRenderExecutor: ListFlightsExecuting {
    private let mode: FlightListRenderMode
    private var continuation: CheckedContinuation<FlightListResult, Error>?

    init(mode: FlightListRenderMode) {
        self.mode = mode
    }

    func execute(passengerID: PassengerID, page: Int) async throws -> FlightListResult {
        switch mode {
        case .initialSkeleton:
            return try await withCheckedThrowingContinuation { continuation in
                self.continuation = continuation
            }
        case .content(let result):
            return result
        case .paginating(let firstPage, _):
            if page == 1 {
                return firstPage
            }
            return try await withCheckedThrowingContinuation { continuation in
                self.continuation = continuation
            }
        case .emptyError(let error):
            throw error
        case .refreshError(let firstPage, _):
            return firstPage
        }
    }

    func refreshAll(flightIDs: [FlightID]) async throws -> [Flight] {
        switch mode {
        case .refreshError(_, let refreshError):
            throw refreshError
        default:
            return flightIDs.map { Flight.stub(id: $0, passengerID: PassengerID("PAX-001")) }
        }
    }

    func resume() {
        switch mode {
        case .initialSkeleton(let result):
            continuation?.resume(returning: result)
        case .paginating(_, let secondPage):
            continuation?.resume(returning: secondPage)
        default:
            return
        }
        continuation = nil
    }
}

@MainActor
final class RenderSessionController: FlightListSessionControlling {
    func ensureActiveSession() async -> Bool {
        true
    }

    func logoutUser() async {}
}
