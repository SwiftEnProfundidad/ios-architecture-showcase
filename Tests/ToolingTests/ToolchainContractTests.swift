import Foundation
import Testing

@Suite("ToolchainContract")
struct ToolchainContractTests {
    @Test("Package manifest declares Swift 6.2")
    func packageManifestDeclaresSwiftSixPointTwo() throws {
        let manifest = try String(contentsOfFile: packageManifestPath, encoding: .utf8)

        #expect(manifest.contains("// swift-tools-version: 6.2"))
    }

    @Test("XcodeGen project manifest declares Swift 6.2 and Xcode 26.3")
    func xcodeGenManifestDeclaresExpectedToolchain() throws {
        let manifest = try String(contentsOfFile: projectManifestPath, encoding: .utf8)

        #expect(manifest.contains("SWIFT_VERSION: \"6.2\""))
        #expect(manifest.contains("xcodeVersion: \"26.3\""))
    }

    private var packageManifestPath: String {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("Package.swift")
            .path
    }

    private var projectManifestPath: String {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("project.yml")
            .path
    }
}
