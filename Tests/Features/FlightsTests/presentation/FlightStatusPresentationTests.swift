import FlightsFeature
import SharedKernel
import Testing

@Suite("FlightStatusPresentation")
struct FlightStatusPresentationTests {
    @Test("Given an on-time flight status, when presentation is built, then the title is localized and the tint is success")
    func onTimeStatusUsesSuccessPresentation() {
        let sut = makeSUT(status: .onTime)

        #expect(sut.title == AppStrings.localized("flights.status.onTime"))
        #expect(sut.tint == .success)
    }

    @Test("Given a delayed flight status, when presentation is built, then the title is localized and the tint is warning")
    func delayedStatusUsesWarningPresentation() {
        let sut = makeSUT(status: .delayed)

        #expect(sut.title == AppStrings.localized("flights.status.delayed"))
        #expect(sut.tint == .warning)
    }

    @Test("Given a boarding flight status, when presentation is built, then the title is localized and the tint is accent")
    func boardingStatusUsesAccentPresentation() {
        let sut = makeSUT(status: .boarding)

        #expect(sut.title == AppStrings.localized("flights.status.boarding"))
        #expect(sut.tint == .accent)
    }

    @Test("Given a departed flight status, when presentation is built, then the title is localized and the tint is neutral")
    func departedStatusUsesNeutralPresentation() {
        let sut = makeSUT(status: .departed)

        #expect(sut.title == AppStrings.localized("flights.status.departed"))
        #expect(sut.tint == .neutral)
    }

    @Test("Given a cancelled flight status, when presentation is built, then the title is localized and the tint is danger")
    func cancelledStatusUsesDangerPresentation() {
        let sut = makeSUT(status: .cancelled)

        #expect(sut.title == AppStrings.localized("flights.status.cancelled"))
        #expect(sut.tint == .danger)
    }

    private func makeSUT(status: Flight.Status) -> FlightStatusPresentation {
        FlightStatusPresentation(status: status)
    }
}
