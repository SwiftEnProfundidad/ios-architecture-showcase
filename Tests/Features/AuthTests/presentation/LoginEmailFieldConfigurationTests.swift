import AuthFeature
import Testing

@Suite("LoginEmailFieldConfiguration")
struct LoginEmailFieldConfigurationTests {
    @Test("Given the default login email field configuration, when inspected, then autocorrect is disabled and visible normalization is enabled")
    func defaultConfigurationDisablesCorrectionsAndNormalizesVisibleInput() {
        let sut = makeSUT()

        #expect(sut.disablesAutocorrection)
        #expect(sut.normalizesVisibleInput)
    }

    private func makeSUT() -> LoginEmailFieldConfiguration {
        LoginEmailFieldConfiguration.default
    }
}
