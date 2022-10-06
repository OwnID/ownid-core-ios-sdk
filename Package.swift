// swift-tools-version:5.1.1

import PackageDescription

let package = Package(
    name: "OwnIDCoreSDK",
//    defaultLocalization: "en",
    platforms: [
        .iOS(.v13)
    ],
    products: [
        .library(
            name: "OwnIDCoreSDK",
            targets: ["OwnIDCoreSDK"]),
        .library(
            name: "OwnIDFlowsSDK",
            targets: ["OwnIDFlowsSDK"]),
        .library(
            name: "OwnIDUISDK",
            targets: ["OwnIDUISDK"]),
    ],
    targets: [
        .target(name: "OwnIDCoreSDK", path: "Core/Sources"),
        .testTarget(
            name: "OwnIDCoreTests",
            dependencies: ["OwnIDCoreSDK", "TestsMocks"],
            path: "Core/Tests"),
        
            .target(name: "TestsMocks",
                    dependencies: ["OwnIDCoreSDK"],
                    path: "TestsMocks"),
        
            .target(name: "OwnIDFlowsSDK",
                    dependencies: [
                        "OwnIDCoreSDK",
                        "OwnIDUISDK"
                    ],
                    path: "Flows/Sources"),
        
            .testTarget(
                name: "OwnIDFlowsSDKTests",
                dependencies: ["OwnIDCoreSDK", "TestsMocks", "OwnIDFlowsSDK"],
                path: "Flows/Tests"),
        
            .target(name: "OwnIDUISDK",
                    dependencies: ["OwnIDCoreSDK"],
                    path: "UI"),
    ]
)
