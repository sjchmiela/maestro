// swift-tools-version: 5.8

import PackageDescription

let package = Package(
    name: "XCTestRunner",
    platforms: [
        .macOS(.v10_15),
        .iOS(.v14)
    ],
    products: [
        .library(
            name: "XCTestRunner",
            targets: ["XCTestRunner"]),
    ],
    dependencies: [
        .package(url: "https://github.com/swhitty/FlyingFox", exact: "0.9.1")
    ],
    targets: [
        .target(
            name: "XCTestRunner",
            dependencies: ["FlyingFox"]),
        .testTarget(
            name: "XCTestRunnerTests",
            dependencies: ["XCTestRunner"]),
    ]
)
