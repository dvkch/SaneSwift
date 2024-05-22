// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SaneSwift",
    defaultLocalization: .init(rawValue: "en"),
    platforms: [
        .iOS(.v12),
        .tvOS(.v12)
    ],
    products: [
        .library(name: "Sane", targets: ["SaneBackend", "SaneTranslations", "SaneSwift", "SaneSwiftC"])
    ],
    dependencies: [],
    targets: [
        .binaryTarget(name: "SaneBackend", path: "Sources/SaneBackend/all/Sane.xcframework"),
        .target(name: "SaneSwift", dependencies: ["SaneSwiftC", "SaneTranslations"]),
        .target(name: "SaneSwiftC"),
        .target(name: "SaneTranslations", resources: [.process("SaneBackend"), .process("SaneSwift")]),
        .testTarget(name: "SaneSwiftTests", dependencies: ["SaneBackend", "SaneTranslations", "SaneSwift", "SaneSwiftC"]),
    ],
    swiftLanguageVersions: [
        .v5
    ]
)
