import Foundation
import Testing

struct CoverageGateEvaluatorTests {
    @Test("Given filtered production coverage above threshold, when the gate evaluates the report, then it succeeds")
    func succeedsAboveThreshold() throws {
        let sut = makeSUT()
        let summary = try loadSummary(fixtureName: "above-threshold", evaluator: sut)

        #expect(summary.productionFiles == 2)
        #expect(summary.coveredLines == 54)
        #expect(summary.totalLines == 60)
        #expect(summary.percentage == 90)
        #expect(summary.meets(threshold: 85))
        #expect(summary.formatted(threshold: 85).contains("90.00%"))
    }

    @Test("Given filtered production coverage below threshold, when the gate evaluates the report, then it fails")
    func failsBelowThreshold() throws {
        let sut = makeSUT()
        let summary = try loadSummary(fixtureName: "below-threshold", evaluator: sut)

        #expect(summary.productionFiles == 2)
        #expect(summary.coveredLines == 70)
        #expect(summary.totalLines == 100)
        #expect(summary.percentage == 70)
        #expect(summary.meets(threshold: 85) == false)
        #expect(summary.formatted(threshold: 85).contains("85.00%"))
    }

    @Test("Given tests and generated files in the exported report, when the gate evaluates the report, then they are excluded from the metric")
    func excludesTestsAndGeneratedFiles() throws {
        let sut = makeSUT()
        let summary = try loadSummary(fixtureName: "filters-generated-and-tests", evaluator: sut)

        #expect(summary.productionFiles == 1)
        #expect(summary.coveredLines == 9)
        #expect(summary.totalLines == 10)
        #expect(summary.percentage == 90)
        #expect(summary.meets(threshold: 85))
    }

    private func makeSUT() -> CoverageGateEvaluator.Type {
        CoverageGateEvaluator.self
    }

    private func loadSummary(
        fixtureName: String,
        evaluator: CoverageGateEvaluator.Type
    ) throws -> CoverageSummary {
        let fixtureURL = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("Fixtures/Coverage/\(fixtureName).json")

        guard FileManager.default.fileExists(atPath: fixtureURL.path) else {
            throw CoverageGateEvaluatorError.fixtureNotFound(fixtureName)
        }

        return try evaluator.loadSummary(from: fixtureURL)
    }
}
