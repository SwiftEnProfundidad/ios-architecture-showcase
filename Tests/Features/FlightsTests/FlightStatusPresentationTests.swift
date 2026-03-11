import FlightsFeature
import SharedKernel
import Testing

@Suite("FlightStatusPresentation")
struct FlightStatusPresentationTests {
    @Test("On-time status uses the localized title and success tint")
    func onTimeStatusUsesSuccessPresentation() {
        let sut = makeSUT(status: .onTime)

        #expect(sut.title == AppStrings.localized("flights.status.onTime"))
        #expect(sut.tint == .success)
    }

    @Test("Delayed status uses the localized title and warning tint")
    func delayedStatusUsesWarningPresentation() {
        let sut = makeSUT(status: .delayed)

        #expect(sut.title == AppStrings.localized("flights.status.delayed"))
        #expect(sut.tint == .warning)
    }

    @Test("Boarding status uses the localized title and accent tint")
    func boardingStatusUsesAccentPresentation() {
        let sut = makeSUT(status: .boarding)

        #expect(sut.title == AppStrings.localized("flights.status.boarding"))
        #expect(sut.tint == .accent)
    }

    @Test("Departed status uses the localized title and neutral tint")
    func departedStatusUsesNeutralPresentation() {
        let sut = makeSUT(status: .departed)

        #expect(sut.title == AppStrings.localized("flights.status.departed"))
        #expect(sut.tint == .neutral)
    }

    @Test("Cancelled status uses the localized title and danger tint")
    func cancelledStatusUsesDangerPresentation() {
        let sut = makeSUT(status: .cancelled)

        #expect(sut.title == AppStrings.localized("flights.status.cancelled"))
        #expect(sut.tint == .danger)
    }

    private func makeSUT(status: Flight.Status) -> FlightStatusPresentation {
        FlightStatusPresentation(status: status)
    }
}
