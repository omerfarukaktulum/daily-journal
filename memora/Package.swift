// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "memora",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(
            name: "memora",
            targets: ["memora"]),
    ],
    dependencies: [
        .package(url: "https://github.com/stripe/stripe-ios", from: "24.0.0")
    ],
    targets: [
        .target(
            name: "memora",
            dependencies: [
                .product(name: "Stripe", package: "stripe-ios")
            ]),
    ]
)
