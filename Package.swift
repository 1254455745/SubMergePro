// swift-tools-version: 6.0
import Foundation
import PackageDescription

let baseExcludes = [
    ".editorconfig",
    ".gitattributes",
    ".github",
    ".gitignore",
    "CHANGELOG.md",
    "CONTRIBUTING.md",
    "LICENSE",
    "Makefile",
    "README.md",
    "README_中文说明.md",
    "Resources/Info.plist",
    "SECURITY.md",
    "Tests",
    "docs",
    "scripts",
    "SubMergeProMac.xcodeproj"
]

let generatedExcludes = [
    ".DS_Store",
    "build",
    "dist"
].filter { FileManager.default.fileExists(atPath: $0) }

let package = Package(
    name: "SubMergeProMac",
    defaultLocalization: "zh-Hans",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "SubMergeProMac",
            targets: ["SubMergeProMac"]
        )
    ],
    targets: [
        .executableTarget(
            name: "SubMergeProMac",
            path: ".",
            exclude: baseExcludes + generatedExcludes,
            sources: [
                "App",
                "Models",
                "Services",
                "ViewModels",
                "Views"
            ],
            resources: [
                .process("Resources")
            ]
        ),
        .testTarget(
            name: "SubMergeProMacTests",
            dependencies: ["SubMergeProMac"],
            path: "Tests/SubMergeProMacTests"
        )
    ]
)
