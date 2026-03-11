import AuthFeature
import Testing

@Suite("LoginEmailFieldConfiguration")
struct LoginEmailFieldConfigurationTests {
    @Test("Default login email field configuration disables corrections and keeps visible normalization")
    func defaultConfigurationDisablesCorrectionsAndNormalizesVisibleInput() {
        let sut = makeSUT()

        #expect(sut.disablesAutocorrection)
        #expect(sut.normalizesVisibleInput)
    }

    private func makeSUT() -> LoginEmailFieldConfiguration {
        LoginEmailFieldConfiguration.default
    }
}
