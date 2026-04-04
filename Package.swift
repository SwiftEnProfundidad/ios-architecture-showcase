// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "iOSArchitectureShowcase",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(name: "SharedKernel", targets: ["SharedKernel"]),
        .library(name: "SharedNavigation", targets: ["SharedNavigation"]),
        .library(name: "AuthFeature", targets: ["AuthFeature"]),
        .library(name: "FlightsFeature", targets: ["FlightsFeature"]),
        .library(name: "BoardingPassFeature", targets: ["BoardingPassFeature"]),
        .library(name: "AppComposition", targets: ["AppComposition"]),
        .library(name: "CoverageGate", targets: ["CoverageGate"])
    ],
    targets: [
        .target(
            name: "SharedKernel",
            path: "Sources/Shared/Kernel",
            resources: [.process("resources")]
        ),
        .target(
            name: "SharedNavigation",
            dependencies: ["SharedKernel"],
            path: "Sources/Shared/Navigation"
        ),
        .target(
            name: "AuthFeature",
            dependencies: [
                "SharedKernel",
                "SharedNavigation"
            ],
            path: "Sources/Features/Auth"
        ),
        .target(
            name: "FlightsFeature",
            dependencies: [
                "SharedKernel",
                "SharedNavigation"
            ],
            path: "Sources/Features/Flights",
            resources: [.process("resources")]
        ),
        .target(
            name: "BoardingPassFeature",
            dependencies: [
                "SharedKernel",
                "SharedNavigation"
            ],
            path: "Sources/Features/BoardingPass",
            resources: [.process("resources")]
        ),
        .target(
            name: "AppComposition",
            dependencies: [
                "SharedKernel",
                "SharedNavigation",
                "AuthFeature",
                "FlightsFeature",
                "BoardingPassFeature"
            ],
            path: "Sources/AppComposition"
        ),
        .target(
            name: "CoverageGate",
            path: "Sources/Tooling/CoverageGate"
        ),
        .testTarget(
            name: "iOSArchitectureShowcaseTests",
            dependencies: [
                "SharedKernel",
                "SharedNavigation",
                "AuthFeature",
                "FlightsFeature",
                "BoardingPassFeature",
                "AppComposition",
                "CoverageGate"
            ],
            path: "Tests",
            resources: [
                .copy("Fixtures/Coverage")
            ]
        )
    ]
)
