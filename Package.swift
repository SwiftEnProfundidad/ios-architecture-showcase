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
        .library(name: "AppComposition", targets: ["AppComposition"])
    ],
    targets: [
        .target(
            name: "SharedKernel",
            path: "Sources/Shared/Kernel",
            resources: [.process("Resources")]
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
            resources: [.process("Resources")]
        ),
        .target(
            name: "BoardingPassFeature",
            dependencies: [
                "SharedKernel",
                "SharedNavigation"
            ],
            path: "Sources/Features/BoardingPass",
            resources: [.process("Resources")]
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
        .testTarget(
            name: "iOSArchitectureShowcaseTests",
            dependencies: [
                "SharedKernel",
                "SharedNavigation",
                "AuthFeature",
                "FlightsFeature",
                "BoardingPassFeature",
                "AppComposition"
            ],
            path: "Tests",
            resources: [
                .copy("Fixtures/Coverage")
            ]
        )
    ]
)
