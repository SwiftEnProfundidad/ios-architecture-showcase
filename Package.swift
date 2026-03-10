// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "iOSArchitectureShowcase",
    defaultLocalization: "es",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(name: "SharedKernel", targets: ["SharedKernel"]),
        .library(name: "SharedNavigation", targets: ["SharedNavigation"]),
        .library(name: "Auth", targets: ["Auth"]),
        .library(name: "Flights", targets: ["Flights"]),
        .library(name: "BoardingPass", targets: ["BoardingPass"]),
        .executable(name: "iOSArchitectureShowcaseApp", targets: ["AppComposition"])
    ],
    targets: [
        .target(
            name: "SharedKernel",
            path: "Sources/Shared/Kernel",
            swiftSettings: strictConcurrency
        ),
        .target(
            name: "SharedNavigation",
            dependencies: ["SharedKernel"],
            path: "Sources/Shared/Navigation",
            swiftSettings: strictConcurrency
        ),
        .target(
            name: "Auth",
            dependencies: ["SharedKernel", "SharedNavigation"],
            path: "Sources/Features/Auth",
            swiftSettings: strictConcurrency
        ),
        .target(
            name: "Flights",
            dependencies: ["SharedKernel", "SharedNavigation"],
            path: "Sources/Features/Flights",
            swiftSettings: strictConcurrency
        ),
        .target(
            name: "BoardingPass",
            dependencies: ["SharedKernel", "SharedNavigation"],
            path: "Sources/Features/BoardingPass",
            swiftSettings: strictConcurrency
        ),
        .executableTarget(
            name: "AppComposition",
            dependencies: ["SharedKernel", "SharedNavigation", "Auth", "Flights", "BoardingPass"],
            path: "Sources/AppComposition",
            resources: [.process("Localizable.xcstrings")],
            swiftSettings: strictConcurrency
        ),
        .testTarget(
            name: "NavigationTests",
            dependencies: ["SharedNavigation", "SharedKernel"],
            path: "Tests/Shared/NavigationTests"
        ),
        .testTarget(
            name: "AuthTests",
            dependencies: ["Auth", "SharedKernel", "SharedNavigation"],
            path: "Tests/Features/AuthTests"
        ),
        .testTarget(
            name: "FlightsTests",
            dependencies: ["Flights", "SharedKernel", "SharedNavigation"],
            path: "Tests/Features/FlightsTests"
        ),
        .testTarget(
            name: "BoardingPassTests",
            dependencies: ["BoardingPass", "SharedKernel", "SharedNavigation"],
            path: "Tests/Features/BoardingPassTests"
        ),
        .testTarget(
            name: "AppCompositionTests",
            dependencies: ["AppComposition"],
            path: "Tests/AppCompositionTests"
        )
    ]
)

private let strictConcurrency: [SwiftSetting] = [
    .enableUpcomingFeature("StrictConcurrency"),
    .enableUpcomingFeature("ExistentialAny")
]
