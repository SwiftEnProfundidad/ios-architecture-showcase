import SharedKernel
import Testing

@Suite("AppStrings")
struct AppStringsTests {
    @Test("Given a localized key, when AppStrings resolves it, then the expected string is returned")
    func resolvesLocalizedKeys() {
        let sut = makeSUT()
        let title = sut.localized("auth.login.title")
        let productName = sut.localized("auth.login.productName")

        #expect(title.isEmpty == false)
        #expect(title != "auth.login.title")
        #expect(productName == "iOS Architecture Showcase")
    }

    @Test("Given a format string and arguments, when AppStrings formats it, then placeholders are interpolated")
    func interpolatesArguments() {
        let sut = makeSUT()
        let message = sut.localized(
            "flights.row.accessibility",
            "IB3456",
            "MAD",
            "BCN",
            "On time"
        )

        #expect(message.contains("IB3456"))
        #expect(message.contains("MAD"))
        #expect(message.contains("BCN"))
    }

    @Test("Given shared UI string accessors, when they are resolved, then values come from localization without hardcoded fallbacks")
    func formatsSharedUIStrings() {
        let sut = makeSUT()
        let route = sut.localized("flights.route", "MAD", "BCN")
        let labelValue = sut.localized("shared.accessibility.labelValue", "Gate", "J12")

        #expect(route == "MAD → BCN")
        #expect(labelValue == "Gate: J12")
    }

    private func makeSUT() -> AppStrings.Type {
        AppStrings.self
    }
}
