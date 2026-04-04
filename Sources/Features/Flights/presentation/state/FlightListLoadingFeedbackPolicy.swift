import Foundation

struct FlightListLoadingFeedbackPolicy: Sendable {
    let minimumInitialSkeletonNanoseconds: UInt64
    let minimumNextPageSpinnerNanoseconds: UInt64

    init(
        minimumInitialSkeletonNanoseconds: UInt64,
        minimumNextPageSpinnerNanoseconds: UInt64
    ) {
        self.minimumInitialSkeletonNanoseconds = minimumInitialSkeletonNanoseconds
        self.minimumNextPageSpinnerNanoseconds = minimumNextPageSpinnerNanoseconds
    }

    func awaitMinimumFeedback<C: Clock<Duration>>(
        isInitialPresentation: Bool,
        isNextPageLoad: Bool,
        clock: C,
        loadStartedAt: C.Instant
    ) async throws {
        let minimumNanoseconds = minimumFeedbackNanoseconds(
            isInitialPresentation: isInitialPresentation,
            isNextPageLoad: isNextPageLoad
        )
        guard minimumNanoseconds > 0 else { return }
        let minimumDuration = Duration.nanoseconds(Int64(minimumNanoseconds))
        let elapsed = loadStartedAt.duration(to: clock.now)
        guard elapsed < minimumDuration else { return }
        try await clock.sleep(until: loadStartedAt.advanced(by: minimumDuration), tolerance: nil)
    }

    private func minimumFeedbackNanoseconds(
        isInitialPresentation: Bool,
        isNextPageLoad: Bool
    ) -> UInt64 {
        guard isInitialPresentation == false else {
            return minimumInitialSkeletonNanoseconds
        }
        guard isNextPageLoad == false else {
            return minimumNextPageSpinnerNanoseconds
        }
        return 0
    }
}
