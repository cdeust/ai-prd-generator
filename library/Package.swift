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
            name: "Application",
            targets: ["Application"]
        ),
        .library(
            name: "Infrastructure",
            targets: ["InfrastructureCore"]
        ),
        .library(
            name: "AIBusiness",
            targets: ["Application", "InfrastructureCore", "Composition"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/awslabs/aws-sdk-swift.git", from: "0.30.0"),
        .package(url: "https://github.com/vapor/postgres-nio.git", from: "1.21.0"),
        // Source packages (decrypted from encrypted .source-package archives)
        .package(path: "../packages/AIPRDVisionEngine"),
        .package(path: "../packages/AIPRDVisionEngineApple")
    ],
    targets: [
        // MARK: - Engine Binary Targets (Decrypted XCFrameworks)
        // Run `scripts/setup-frameworks.sh` to decrypt before building
        .binaryTarget(name: "AIPRDSharedUtilities", path: "../frameworks/AIPRDSharedUtilities.xcframework"),
        .binaryTarget(name: "AIPRDRAGEngine", path: "../frameworks/AIPRDRAGEngine.xcframework"),
        .binaryTarget(name: "AIPRDVerificationEngine", path: "../frameworks/AIPRDVerificationEngine.xcframework"),
        .binaryTarget(name: "AIPRDMetaPromptingEngine", path: "../frameworks/AIPRDMetaPromptingEngine.xcframework"),
        .binaryTarget(name: "AIPRDStrategyEngine", path: "../frameworks/AIPRDStrategyEngine.xcframework"),
        .binaryTarget(name: "AIPRDOrchestrationEngine", path: "../frameworks/AIPRDOrchestrationEngine.xcframework"),
        .binaryTarget(name: "AIPRDEncryptionEngine", path: "../frameworks/AIPRDEncryptionEngine.xcframework"),

        // MARK: - Layer 1: Application (Thin CRUD Use Cases)
        .target(
            name: "Application",
            dependencies: [
                "AIPRDSharedUtilities",
                "AIPRDRAGEngine",
                "AIPRDOrchestrationEngine"
            ],
            path: "Sources/Application",
            exclude: ["README.md"]
        ),

        // MARK: - Layer 2: Infrastructure (AI Providers, PostgreSQL, Embeddings)
        .target(
            name: "InfrastructureCore",
            dependencies: [
                "Application",
                "AIPRDSharedUtilities",
                .product(name: "AWSBedrockRuntime", package: "aws-sdk-swift"),
                .product(name: "AWSClientRuntime", package: "aws-sdk-swift"),
                .product(name: "PostgresNIO", package: "postgres-nio")
            ],
            path: "Sources/Infrastructure",
            exclude: [
                "README.md"
            ]
        ),

        // MARK: - Layer 3: Composition (DI Wiring, Factories)
        .target(
            name: "Composition",
            dependencies: [
                "Application",
                "InfrastructureCore",
                "AIPRDSharedUtilities",
                "AIPRDRAGEngine",
                "AIPRDVerificationEngine",
                "AIPRDMetaPromptingEngine",
                "AIPRDStrategyEngine",
                .product(name: "AIPRDVisionEngine", package: "AIPRDVisionEngine"),
                .product(name: "AIPRDVisionEngineApple", package: "AIPRDVisionEngineApple"),
                "AIPRDOrchestrationEngine",
                "AIPRDEncryptionEngine"
            ],
            path: "Sources/Composition",
            exclude: ["README.md"]
        ),

        // MARK: - Tests
        .testTarget(
            name: "ApplicationTests",
            dependencies: [
                "Application",
                "AIPRDSharedUtilities"
            ],
            path: "Tests/ApplicationTests"
        ),
        .testTarget(
            name: "InfrastructureTests",
            dependencies: [
                "InfrastructureCore",
                "Application",
                "AIPRDSharedUtilities"
            ],
            path: "Tests/InfrastructureTests",
            exclude: ["README.md"]
        ),
        .testTarget(
            name: "IntegrationTests",
            dependencies: [
                "InfrastructureCore",
                "Application",
                "Composition",
                "AIPRDSharedUtilities"
            ],
            path: "Tests/IntegrationTests"
        )
    ]
)
