import SharedKernel

actor SessionEndingSpy: SessionEnding {
    private(set) var endSessionCallCount = 0

    func endSession() async {
        endSessionCallCount += 1
    }
}
