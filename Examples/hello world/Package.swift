// swift-tools-version:5.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "hello world",
    dependencies: [
    .package(url: "https://github.com/3Qax/SwiftyOLED.git", from: "1.0.0"),
    .package(url: "https://github.com/3Qax/SwiftyGFX.git", from: "1.0.0"),
    .package(url: "https://github.com/uraimo/SwiftyGPIO.git", from: "1.0.0"),
    ],
    targets: [
        .target(
            name: "hello world",
            dependencies: ["SwiftyGFX", "SwiftyOLED", "SwiftyGPIO"]),
    ]
)
