// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "crest",
    platforms: [
        .macOS(.v11)
    ],
    products: [
        .executable(name: "crest", targets: ["crest"]),
        .library(name: "CrestLib", targets: ["CrestLib"])
    ],
    dependencies: [
        .package(url: "https://github.com/klassen-software-solutions/KSSCore.git", from: "5.1.1"),
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.1.2"),
        .package(url: "https://github.com/swift-server/async-http-client", from: "1.10.0"),
        .package(url: "https://github.com/Kitura/Configuration.git", from: "3.0.200")
    ],
    targets: [
        .target(
            name: "crest",
            dependencies: [
                "CrestLib",
                .product(name: "ArgumentParser", package: "swift-argument-parser")
            ]),
        .target(
            name: "CrestLib",
            dependencies: [
                .product(name: "AsyncHTTPClient", package: "async-http-client"),
                .product(name: "Configuration", package: "Configuration"),
                .product(name: "KSSFoundation", package: "KSSCore")
            ]),
        .testTarget(
            name: "crestTests",
            dependencies: ["crest", .product(name: "KSSTest", package: "KSSCore")]
            ),
    ]
)
