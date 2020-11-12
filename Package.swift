// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "ExpressionEvaluator",
    products: [
        .library(
            name: "ExpressionEvaluator",
            targets: ["ExpressionEvaluator"]),
    ],
    targets: [
        .target(
            name: "ExpressionEvaluator",
            dependencies: []),
        .testTarget(
            name: "ExpressionEvaluatorTests",
            dependencies: ["ExpressionEvaluator"]),
    ]
)
