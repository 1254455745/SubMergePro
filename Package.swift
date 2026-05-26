// swift-tools-version: 6.0
import PackageDescription

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
            exclude: [
                "README_中文说明.md",
                "Resources/Info.plist",
                "SubMergeProMac.xcodeproj"
            ],
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
        )
    ]
)
