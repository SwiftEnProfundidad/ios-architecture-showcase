public struct LoginEmailFieldConfiguration: Sendable, Equatable {
    public let disablesAutocorrection: Bool
    public let normalizesVisibleInput: Bool

    public init(
        disablesAutocorrection: Bool,
        normalizesVisibleInput: Bool
    ) {
        self.disablesAutocorrection = disablesAutocorrection
        self.normalizesVisibleInput = normalizesVisibleInput
    }
}

public extension LoginEmailFieldConfiguration {
    static let `default` = LoginEmailFieldConfiguration(
        disablesAutocorrection: true,
        normalizesVisibleInput: true
    )
}
