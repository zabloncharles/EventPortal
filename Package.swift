// swift-tools-version:5.7
import PackageDescription

let package = Package(
    name: "EventAppPortal",
    platforms: [
        .iOS(.v13)
    ],
    products: [
        .library(
            name: "EventAppPortal",
            targets: ["EventAppPortal"]),
    ],
    dependencies: [
        .package(url: "https://github.com/airbnb/lottie-ios.git", exact: "3.5.0")
    ],
    targets: [
        .target(
            name: "EventAppPortal",
            dependencies: [
                .product(name: "Lottie", package: "lottie-ios")
            ]),
        .testTarget(
            name: "EventAppPortalTests",
            dependencies: ["EventAppPortal"]),
    ]
) 