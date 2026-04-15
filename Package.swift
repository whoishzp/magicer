// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "WorkStop",
    platforms: [.macOS(.v13)],
    targets: [
        .target(
            name: "CarbonBridge",
            path: "Sources/CarbonBridge",
            publicHeadersPath: "include",
            linkerSettings: [
                .linkedFramework("Carbon")
            ]
        ),
        .executableTarget(
            name: "WorkStop",
            dependencies: ["CarbonBridge"],
            path: "Sources",
            exclude: ["CarbonBridge"],
            swiftSettings: [
                .unsafeFlags(["-I", "Sources/CarbonBridge/include"])
            ]
        )
    ]
)
