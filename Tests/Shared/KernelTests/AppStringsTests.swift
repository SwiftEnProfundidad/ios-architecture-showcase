import SharedKernel
import Testing

@Suite("AppStrings")
struct AppStringsTests {
    @Test("AppStrings resolves localized keys")
    func resolvesLocalizedKeys() {
        let title = AppStrings.localized("auth.login.title")
        let productName = AppStrings.localized("auth.login.productName")

        #expect(title.isEmpty == false)
        #expect(title != "auth.login.title")
        #expect(productName == "iOS Architecture Showcase")
    }

    @Test("AppStrings interpolates localized arguments")
    func interpolatesArguments() {
        let message = AppStrings.localized(
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

    @Test("AppStrings formats shared UI strings without hardcoded fallbacks")
    func formatsSharedUIStrings() {
        let route = AppStrings.localized("flights.route", "MAD", "BCN")
        let labelValue = AppStrings.localized("shared.accessibility.labelValue", "Gate", "J12")

        #expect(route == "MAD → BCN")
        #expect(labelValue == "Gate: J12")
    }
}
