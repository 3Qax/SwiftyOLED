// swift-tools-version:5.0

import PackageDescription

let package = Package(
    name: "SwiftyOLED",
    products: [
        .library(
            name: "SwiftyOLED",
            targets: ["SwiftyOLED"]),
    ],
    dependencies: [
        .package(url: "https://github.com/uraimo/SwiftyGPIO.git", .exact("1.1.7")),
    ],
    targets: [
        .target(
            name: "SwiftyOLED",
            dependencies: ["SwiftyGPIO"]),
    ]
)
