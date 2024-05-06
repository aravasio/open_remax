// swift-tools-version:5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "apt_listings",
    platforms: [
        .macOS(.v10_15), // Specify macOS minimum platform version
        // Note: For Linux, the Swift tools version and your code's compatibility determine support.
    ],
    dependencies: [
        .package(url: "https://github.com/groue/GRDB.swift.git", from: "6.27.0"),
        .package(url: "https://github.com/scinfu/SwiftSoup.git", from: "2.3.2"),
        .package(url: "https://github.com/apple/swift-nio.git", from: "2.64.0"),
    ],
    targets: [
        .executableTarget(
            name: "apt_listings",
            dependencies: [
                .product(name: "GRDB", package: "GRDB.swift"),
                .product(name: "NIO", package: "swift-nio"),
                .product(name: "SwiftSoup", package: "SwiftSoup"),
            ],
            swiftSettings: [
                .define("SQLITE_ENABLE_SNAPSHOT", .when(platforms: [.linux]))
            ],
            linkerSettings: [
                .linkedLibrary("sqlite3", .when(platforms: [.linux]))
            ]
        ),
        // Test targets can be added here
    ]
)