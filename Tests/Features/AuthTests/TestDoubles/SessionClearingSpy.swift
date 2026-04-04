import AuthFeature

actor SessionClearingSpy: SessionClearing {
    private(set) var clearCallCount = 0

    func clear() async {
        clearCallCount += 1
    }

    func recordedClearCallCount() -> Int {
        clearCallCount
    }
}
