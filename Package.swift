// swift-tools-version: 5.9
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
        .package(url: "https://github.com/scinfu/SwiftSoup.git", from: "2.3.2"),
    ],
    targets: [
        // Targets are the basic building blocks of a package.
        .executableTarget(
            name: "apt_listings",
            dependencies: ["SwiftSoup"]),
        // Test targets can be added here as well
    ]
)
