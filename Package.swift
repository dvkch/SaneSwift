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
        .library(name: "Sane", targets: ["SaneBackend", "SaneBackendTranslations", "SaneSwift", "SaneSwiftC"])
    ],
    dependencies: [],
    targets: [
        .binaryTarget(name: "SaneBackend", path: "Sources/SaneBackend/all/Sane.xcframework"),
        .target(name: "SaneBackendTranslations", dependencies: ["SaneBackend"], resources: [.copy("translations")]),
        .target(name: "SaneSwift", dependencies: ["SaneSwiftC"], resources: [.process("Localizable")]),
        .target(name: "SaneSwiftC"),
        .testTarget(name: "SaneSwiftTests", dependencies: ["SaneBackend", "SaneBackendTranslations", "SaneSwift", "SaneSwiftC"]),
    ],
    swiftLanguageVersions: [
        .v5
    ]
)
