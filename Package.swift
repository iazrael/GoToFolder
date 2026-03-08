// swift-tools-version: 5.7
import PackageDescription

let package = Package(
    name: "Go2Shell",
    products: [
        .executable(
            name: "Go2Shell",
            targets: ["Go2Shell"]
        )
    ],
    targets: [
        .executableTarget(
            name: "Go2Shell",
            path: "Sources/Go2Shell"
        )
    ]
)
