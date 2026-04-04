import Foundation

public struct CoverageSummary: Equatable {
    public let percentage: Double
    public let coveredLines: Int
    public let totalLines: Int
    public let productionFiles: Int

    public func meets(threshold: Double) -> Bool {
        percentage + 0.000_000_001 >= threshold
    }

    public func formatted(threshold: Double) -> String {
        let locale = Locale(identifier: "en_US_POSIX")
        let percentageText = percentage.formatted(
            .number
                .precision(.fractionLength(2))
                .locale(locale)
        )
        let thresholdText = threshold.formatted(
            .number
                .precision(.fractionLength(2))
                .locale(locale)
        )
        return "Production coverage: \(percentageText)% (\(coveredLines)/\(totalLines) lines across \(productionFiles) production files). Required threshold: \(thresholdText)%."
    }
}

public enum CoverageGateEvaluatorError: Error, Equatable {
    case fixtureNotFound(String)
    case invalidReport
    case missingProductionFiles
}

public enum CoverageGateEvaluator {
    public static func loadSummary(from reportURL: URL) throws -> CoverageSummary {
        let data = try Data(contentsOf: reportURL)
        let report = try JSONDecoder().decode(CoverageReport.self, from: data)

        var totalLines = 0
        var coveredLines = 0
        var productionFiles = 0

        for block in report.data {
            for file in block.files where shouldInclude(file.filename) {
                totalLines += file.summary.lines.count
                coveredLines += file.summary.lines.covered
                productionFiles += 1
            }
        }

        guard totalLines > 0, productionFiles > 0 else {
            throw CoverageGateEvaluatorError.missingProductionFiles
        }

        let percentage = (Double(coveredLines) / Double(totalLines)) * 100
        return CoverageSummary(
            percentage: percentage,
            coveredLines: coveredLines,
            totalLines: totalLines,
            productionFiles: productionFiles
        )
    }

    private static func shouldInclude(_ filename: String) -> Bool {
        let normalized = filename.replacingOccurrences(of: "\\", with: "/")
        guard normalized.contains("/Sources/") else {
            return false
        }
        if normalized.contains("/Tests/") {
            return false
        }
        if normalized.contains("/DerivedSources/") {
            return false
        }
        if normalized.hasSuffix("/resource_bundle_accessor.swift") {
            return false
        }
        return true
    }
}

private struct CoverageReport: Decodable {
    let data: [CoverageDataBlock]
}

private struct CoverageDataBlock: Decodable {
    let files: [CoverageFile]
}

private struct CoverageFile: Decodable {
    let filename: String
    let summary: CoverageFileSummary
}

private struct CoverageFileSummary: Decodable {
    let lines: CoverageLineSummary
}

private struct CoverageLineSummary: Decodable {
    let count: Int
    let covered: Int
}
