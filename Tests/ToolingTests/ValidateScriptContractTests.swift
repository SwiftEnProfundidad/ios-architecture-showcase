import Foundation
import Testing

struct ValidateScriptContractTests {
    @Test("Local validation defaults the coverage gate threshold to eighty five percent")
    func validateScriptDefaultsCoverageThresholdToEightyFive() throws {
        let sut = makeSUT()

        let contents = try String(contentsOf: sut.scriptURL, encoding: .utf8)

        #expect(contents.contains("COVERAGE_THRESHOLD:-85"))
    }

    private func makeSUT() -> ValidateScriptContractSubject {
        let repositoryRoot = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        return ValidateScriptContractSubject(
            scriptURL: repositoryRoot.appendingPathComponent("scripts/validate.sh")
        )
    }
}

private struct ValidateScriptContractSubject {
    let scriptURL: URL
}
