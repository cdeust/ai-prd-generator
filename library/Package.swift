// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "AIPRDBuilder",
    platforms: [
        .macOS(.v14),
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "Domain",
            targets: ["Domain"]
        ),
        .library(
            name: "Application",
            targets: ["Application"]
        ),
        .library(
            name: "Infrastructure",
            targets: ["InfrastructureCore"]
        ),
        .library(
            name: "AIBusiness",
            targets: ["Domain", "Application", "InfrastructureCore", "Composition"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/Quick/Quick.git", from: "7.0.0"),
        .package(url: "https://github.com/Quick/Nimble.git", from: "13.0.0"),
        .package(url: "https://github.com/awslabs/aws-sdk-swift.git", from: "0.30.0"),
        .package(url: "https://github.com/vapor/postgres-nio.git", from: "1.21.0")
    ],
    targets: [
        // MARK: - Layer 1: Domain (Pure Business Logic - NO dependencies)
        .target(
            name: "Domain",
            dependencies: [],
            path: "Sources/Domain",
            exclude: ["README.md"]
        ),

        // MARK: - Layer 2: Application (Use Cases)
        .target(
            name: "Application",
            dependencies: ["Domain"],
            path: "Sources/Application",
            exclude: ["README.md"]
        ),

        // MARK: - Layer 3: Infrastructure (Implementations)

        // Infrastructure Core - Cloud providers + Apple Intelligence + PostgreSQL
        .target(
            name: "InfrastructureCore",
            dependencies: [
                "Domain",
                "Application",
                .product(name: "AWSBedrockRuntime", package: "aws-sdk-swift"),
                .product(name: "AWSClientRuntime", package: "aws-sdk-swift"),
                .product(name: "PostgresNIO", package: "postgres-nio")
            ],
            path: "Sources/Infrastructure",
            exclude: [
                "Vision/VisionAnalyzerFactory.swift",
                "README.md",
                "Vision/README.md"
            ]
        ),

        // MARK: - Layer 4: Composition (DI Wiring)
        .target(
            name: "Composition",
            dependencies: ["Domain", "Application", "InfrastructureCore"],
            path: "Sources/Composition",
            exclude: ["README.md"]
        ),

        // MARK: - Tests
        .testTarget(
            name: "DomainTests",
            dependencies: [
                "Domain",
                .product(name: "Quick", package: "Quick"),
                .product(name: "Nimble", package: "Nimble")
            ],
            path: "Tests/DomainTests"
        ),
        .testTarget(
            name: "ApplicationTests",
            dependencies: ["Application", "Domain"],
            path: "Tests/ApplicationTests"
        ),
        .testTarget(
            name: "InfrastructureTests",
            dependencies: ["InfrastructureCore", "Application", "Domain"],
            path: "Tests/InfrastructureTests",
            exclude: ["README.md"]
        ),
        .testTarget(
            name: "IntegrationTests",
            dependencies: ["InfrastructureCore", "Application", "Domain", "Composition"],
            path: "Tests/IntegrationTests"
        )
    ]
)
