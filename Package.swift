// swift-tools-version:5.0

import PackageDescription

let package = Package(
    name: "SwiftyOLED",
    products: [
        .library(
            name: "SwiftyOLED",
            targets: ["SwiftyOLED"]),
        .executable(
            name: "Example_use_of_SwiftyOLED",
            targets: ["Example_use_of_SwiftyOLED"]),
    ],
    dependencies: [
        .package(url: "https://github.com/uraimo/SwiftyGPIO.git", .exact("1.1.3")),
    ],
    targets: [
        .target(
            name: "SwiftyOLED",
            dependencies: ["SwiftyGPIO"]),
        .target(
            name: "Example_use_of_SwiftyOLED",
            dependencies: ["SwiftyOLED", "SwiftyGPIO"]
        )
    ]
)
