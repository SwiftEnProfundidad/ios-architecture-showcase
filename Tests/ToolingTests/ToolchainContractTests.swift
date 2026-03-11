import Foundation
import Testing

@Suite("ToolchainContract")
struct ToolchainContractTests {
    @Test("Package manifest declares Swift 6.2")
    func packageManifestDeclaresSwiftSixPointTwo() throws {
        let sut = makeSUT()
        let manifest = try String(contentsOfFile: sut.packageManifestPath, encoding: .utf8)

        #expect(manifest.contains("// swift-tools-version: 6.2"))
    }

    @Test("XcodeGen project manifest declares Swift 6.2 and Xcode 26.3")
    func xcodeGenManifestDeclaresExpectedToolchain() throws {
        let sut = makeSUT()
        let manifest = try String(contentsOfFile: sut.projectManifestPath, encoding: .utf8)

        #expect(manifest.contains("SWIFT_VERSION: \"6.2\""))
        #expect(manifest.contains("xcodeVersion: \"26.3\""))
    }

    private func makeSUT() -> ToolchainContractSubject {
        let repositoryRoot = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        return ToolchainContractSubject(
            packageManifestPath: repositoryRoot.appendingPathComponent("Package.swift").path,
            projectManifestPath: repositoryRoot.appendingPathComponent("project.yml").path
        )
    }
}

private struct ToolchainContractSubject {
    let packageManifestPath: String
    let projectManifestPath: String
}
