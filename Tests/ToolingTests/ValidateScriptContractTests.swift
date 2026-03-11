import Foundation
import Testing

struct ValidateScriptContractTests {
    @Test("Local validation defaults the coverage gate threshold to eighty five percent")
    func validateScriptDefaultsCoverageThresholdToEightyFive() throws {
        let scriptURL = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("scripts/validate.sh")

        let contents = try String(contentsOf: scriptURL, encoding: .utf8)

        #expect(contents.contains("COVERAGE_THRESHOLD:-85"))
    }
}
