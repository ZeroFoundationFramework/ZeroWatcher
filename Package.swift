// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ZeroWatcher",
    platforms: [.macOS(.v12)],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .executable(
            name: "ZeroWatcher",
            targets: ["ZeroWatcher"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/ZeroFoundationFramework/ZeroLogger.git", from: "1.0.1"),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .executableTarget(
            name: "ZeroWatcher",
            dependencies: [ .product(name: "ZeroLogger", package: "ZeroLogger")]
        ),

    ]
)
