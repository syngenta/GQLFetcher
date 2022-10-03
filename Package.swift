// swift-tools-version:4.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "GQLFetcher",
    products: [
        // Products define the executables and libraries produced by a package, and make them visible to other packages.
        .library(
            name: "GQLFetcher",
            targets: ["GQLFetcher"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
         .package(url: "https://github.com/Lumyk/GQLSchema.git", from: "1.1.3"),
         .package(url: "https://github.com/mxcl/PromiseKit.git", from: "6.18.1"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "GQLFetcher",
            dependencies: ["GQLSchema", "PromiseKit"]),
        .testTarget(
            name: "GQLFetcherTests",
            dependencies: ["GQLFetcher", "GQLSchema", "PromiseKit"]),
    ]
)
