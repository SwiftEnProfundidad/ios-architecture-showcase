import Observation
import SharedKernel
import SharedNavigation

@MainActor
@Observable
public final class FlightDetailViewModel<DetailUseCase: FlightDetailGetting> {
    public private(set) var detail: FlightDetail?
    public private(set) var isLoading = true
    public private(set) var errorMessage: String?

    private let detailUseCase: DetailUseCase
    private let eventBus: NavigationEventPublishing
    private let flightID: FlightID

    public init(
        detailUseCase: DetailUseCase,
        eventBus: NavigationEventPublishing,
        flightID: FlightID
    ) {
        self.detailUseCase = detailUseCase
        self.eventBus = eventBus
        self.flightID = flightID
    }

    public func load() async {
        isLoading = true
        errorMessage = nil
        detail = nil
        defer { isLoading = false }
        do {
            detail = try await detailUseCase.execute(flightID: flightID)
        } catch is CancellationError {
            return
        } catch {
            detail = nil
            errorMessage = AppStrings.localized("flights.error.detail")
        }
    }

    public func requestBoardingPass() async {
        await eventBus.publish(
            .requestProtectedPath([
                .primaryDetail(contextID: flightID),
                .secondaryAttachment(contextID: flightID)
            ])
        )
    }
}
