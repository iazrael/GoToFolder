// swift-tools-version: 5.9
// Package.swift — For IDE support / LSP (language server) only.
// Use build.sh for the actual .app bundle; swift build doesn't produce a
// proper macOS .app bundle on its own.

import PackageDescription

let package = Package(
    name: "GoToFolder",
    platforms: [
        .macOS(.v12)
    ],
    targets: [
        .executableTarget(
            name: "GoToFolder",
            path: "Sources/GoToFolder",
            swiftSettings: [
                .unsafeFlags(["-framework", "Cocoa"])
            ],
            linkerSettings: [
                .linkedFramework("Cocoa")
            ]
        )
    ]
)
