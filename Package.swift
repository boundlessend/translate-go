// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "OllamaTranslatorApp",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "OllamaTranslatorApp",
            targets: ["OllamaTranslatorApp"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/soffes/HotKey.git", from: "0.2.1")
    ],
    targets: [
        .executableTarget(
            name: "OllamaTranslatorApp",
            dependencies: ["HotKey"],
            path: "Sources/OllamaTranslatorApp",
            exclude: ["Info.plist", "Resources"]
        )
    ]
)
