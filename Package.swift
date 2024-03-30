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
        // Dependencies declare other packages that this package depends on.
        .package(url: "https://github.com/groue/GRDB.swift.git", from: "6.25.0"),
        .package(url: "https://github.com/scinfu/SwiftSoup.git", from: "2.3.2"),
        .package(url: "https://github.com/apple/swift-nio.git", from: "2.64.0"),
        .package(url: "https://github.com/swift-server/async-http-client.git", from: "1.0.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package.
        .executableTarget(
            name: "apt_listings",
            dependencies: [
                .product(name: "GRDB", package: "GRDB.swift"),
                .product(name: "NIO", package: "swift-nio"),
                .product(name: "SwiftSoup", package: "SwiftSoup"),
                .product(name: "AsyncHTTPClient", package: "async-http-client")
            ]
        ),
        // Test targets can be added here as well
    ]
)
