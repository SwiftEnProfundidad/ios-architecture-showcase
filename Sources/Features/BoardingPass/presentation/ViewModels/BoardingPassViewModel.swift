import Observation
import SharedKernel

@MainActor
@Observable
public final class BoardingPassViewModel<UseCase: BoardingPassGetting> {
    public private(set) var boardingPass: BoardingPassData?
    public private(set) var isLoading = true
    public private(set) var errorMessage: String?

    private let useCase: UseCase
    private let flightID: FlightID

    public init(
        useCase: UseCase,
        flightID: FlightID
    ) {
        self.useCase = useCase
        self.flightID = flightID
    }

    public func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            boardingPass = try await useCase.execute(flightID: flightID)
        } catch is CancellationError {
            return
        } catch {
            errorMessage = AppStrings.localized("boardingpass.error.load")
        }
    }
}
