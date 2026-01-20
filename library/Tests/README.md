# AI PRD Test Suite

> Professional test suite with production validation, randomized synthetic data, and scalable execution (100 to 1M+ samples)

## Overview

This test suite enforces **professional testing standards** as defined in CLAUDE.md Section 0.5. All tests must:

- **Test real implementation** (not mock logic)
- **Use randomized synthetic data** (different scenarios, not repetitions)
- **Support scalable execution** (100 to 1M+ samples via `VALIDATION_SAMPLES`)
- **Validate statistical properties** (for algorithms with statistical behavior)
- **Call actual services** (mock only external dependencies)

## Test Structure

```
Tests/
├── DomainTests/              # Domain layer tests (pure business logic)
│   ├── ConvergenceEvidenceSpec.swift
│   ├── ConvergenceEvidenceDiagnostics.swift
│   └── ConvergenceEvidenceProductionValidation.swift
│
├── ApplicationTests/         # Application layer tests (use cases, services)
│   ├── UseCases/             # Use case tests
│   ├── Services/             # Service tests
│   ├── ContextGraphTrackerSpec.swift
│   ├── ContextGraphProductionValidation.swift
│   ├── HybridSearchServiceSpec.swift
│   ├── HybridSearchProductionValidation.swift
│   ├── TRMTrajectoryGenerator.swift
│   └── TRMConvergenceBenchmark.swift
│
├── InfrastructureTests/      # Infrastructure layer tests (adapters, ports)
│   └── InfrastructureTestsPlaceholder.swift
│
└── README.md                 # This file
```

## Test Types

### 1. Unit Tests (Spec files)

**Purpose:** Test individual components in isolation
**Naming:** `{Component}Spec.swift`
**Sample Size:** 100-200 scenarios
**Execution Time:** <1 second

**Example:**
```swift
final class HybridSearchServiceSpec: QuickSpec {
    override class func spec() {
        describe("HybridSearchService") {
            context("with conflicting rankings") {
                it("should fuse using RRF correctly") {
                    // Test with mock dependencies
                    let service = createService(...)

                    let results = try await service.search(...)

                    expect(results[0].id).to(equal(expectedChunk.id))
                }
            }
        }
    }
}
```

### 2. Production Validation Tests

**Purpose:** Validate statistical correctness at scale
**Naming:** `{Component}ProductionValidation.swift`
**Sample Size:** 100 (dev) to 1M+ (CI/CD)
**Execution Time:** 1s (100 samples) to 2-5 minutes (1M samples)

**Example:**
```swift
final class HybridSearchProductionValidation: XCTestCase {
    private var productionSamples: Int {
        ProcessInfo.processInfo.environment["VALIDATION_SAMPLES"]
            .flatMap(Int.init) ?? 1_000_000
    }

    func testRRF_formula_correctness_1M_samples() async throws {
        let result = await runStatisticalValidation(
            name: "RRF Formula Correctness",
            targetRate: 0.99,  // 99% must match exact RRF math
            generator: generateRRFScenario,  // ✅ Random each time
            validator: { scenario in
                await self.validateRRFMath(scenario: scenario)
            }
        )

        XCTAssertTrue(result.passed, result.failureMessage)
    }

    private func generateRRFScenario() -> RRFScenario {
        // ✅ Randomized - different scenario each call
        let numChunks = Int.random(in: 3...5)
        let alpha = Double.random(in: 0.0...1.0)
        // ... generate random rankings ...
    }
}
```

### 3. Benchmark Tests

**Purpose:** Performance measurement and regression detection
**Naming:** `{Component}Benchmark.swift`
**Sample Size:** 1K-10K operations
**Execution Time:** 2-10 seconds

**Example:**
```swift
final class TRMConvergenceBenchmark: XCTestCase {
    func testConvergenceDetectionPerformance() {
        measure {
            for _ in 0..<1000 {
                let trajectory = generateRandomTrajectory()
                let evidence = ConvergenceEvidence(trajectory: trajectory)
                _ = evidence.showsStrongConvergence
            }
        }
    }
}
```

## Running Tests

### Quick Validation (Development)

```bash
# Default: 100 samples, <1 second
swift test
```

### Medium Validation

```bash
# 10K samples, ~10 seconds
VALIDATION_SAMPLES=10000 swift test --filter "ProductionValidation"
```

### Full Validation (CI/CD)

```bash
# 1M samples, ~2-5 minutes
VALIDATION_SAMPLES=1000000 swift test --filter "ProductionValidation"
```

### Specific Test Suites

```bash
# Domain tests only
swift test --filter "DomainTests"

# Application tests only
swift test --filter "ApplicationTests"

# Specific production validation
swift test --filter "HybridSearchProductionValidation"
```

### Verify Test Quality

```bash
# Check test compliance with standards
cd .. && ./scripts/verify-production-tests.sh
```

## Writing Tests

### Test Standards (Mandatory)

**All tests MUST:**

1. **Test Real Implementation**
   - ✅ Call actual service methods
   - ❌ Don't implement test logic that duplicates production code

2. **Use Randomized Data**
   - ✅ Use `Double.random()`, `Int.random()`, `.shuffled()`
   - ❌ Don't use fixed values in generators

3. **Generate Different Scenarios**
   - ✅ Each iteration produces different data
   - ❌ Don't repeat same scenario with different IDs

4. **Be Parameterizable**
   - ✅ Support `VALIDATION_SAMPLES` environment variable
   - ❌ Don't hardcode sample counts

### Production Validation Pattern

```swift
final class ComponentProductionValidation: XCTestCase {
    // 1. Configurable sample count
    private var productionSamples: Int {
        ProcessInfo.processInfo.environment["VALIDATION_SAMPLES"]
            .flatMap(Int.init) ?? 100  // Default for dev
    }

    private let stabilityRuns = 5  // Multiple runs for variance check

    // 2. Test method
    func testBehavior_production_validation() async throws {
        let result = await runStatisticalValidation(
            name: "Component Behavior",
            targetRate: 0.95,  // 95% correctness expected
            generator: generateRandomScenario,
            validator: validateImplementation
        )

        XCTAssertTrue(result.passed, result.failureMessage)
    }

    // 3. Random scenario generator
    private func generateRandomScenario() -> Scenario {
        Scenario(
            // ✅ ALL values must be randomized
            param1: Double.random(in: 0.0...1.0),
            param2: Int.random(in: 3...15),
            items: generateRandomItems()
        )
    }

    // 4. Validator calls REAL implementation
    private func validateImplementation(_ scenario: Scenario) async -> Bool {
        let service = createRealService(  // Real service
            dependency1: MockDep1(...),   // Mock external dependencies
            dependency2: MockDep2(...)
        )

        // Call REAL implementation
        guard let result = try? await service.process(scenario) else {
            return false
        }

        // Validate REAL behavior
        return result.isValid && result.score > 0.5
    }

    // 5. Statistical validation framework
    private func runStatisticalValidation(
        name: String,
        targetRate: Double,
        generator: @escaping () -> Scenario,
        validator: @escaping (Scenario) async -> Bool
    ) async -> ValidationResult {
        var rates: [Double] = []

        // Multiple runs for stability
        for run in 1...stabilityRuns {
            var correctCount = 0

            // Test N DIFFERENT scenarios
            for _ in 0..<productionSamples {
                let scenario = generator()  // ✅ Different each time

                if await validator(scenario) {
                    correctCount += 1
                }
            }

            let rate = Double(correctCount) / Double(productionSamples)
            rates.append(rate)
        }

        // Calculate statistics
        let mean = rates.reduce(0.0, +) / Double(rates.count)
        let variance = rates.map { pow($0 - mean, 2) }.reduce(0.0, +) / Double(rates.count)
        let stdDev = sqrt(variance)

        // 95% confidence interval
        let ci95Margin = 1.96 * (stdDev / sqrt(Double(rates.count)))
        let ci95Lower = mean - ci95Margin

        // Validation checks
        let targetMet = ci95Lower > targetRate
        let stabilityMet = (stdDev / mean) < 0.005  // <0.5% variance

        return ValidationResult(
            passed: targetMet && stabilityMet,
            mean: mean,
            ci95Lower: ci95Lower,
            // ...
        )
    }
}
```

### Anti-Patterns (FORBIDDEN)

**❌ Testing Mock Logic (Not Real Implementation):**
```swift
// ❌ WRONG: Testing MY fusion logic, not REAL service
func testFusion() {
    let myFusion = performMyOwnFusion(...)  // ❌ Mock logic
    XCTAssertEqual(myFusion, expected)
}

// ✅ CORRECT: Testing REAL HybridSearchService
func testFusion() async throws {
    let service = HybridSearchService(...)  // ✅ Real service
    let results = try await service.search(...)
    XCTAssertEqual(results[0].id, expectedId)
}
```

**❌ Fixed Values (Same Scenario Repeated):**
```swift
// ❌ WRONG: Fixed values
func generateScenario() -> Scenario {
    Scenario(
        similarity: 0.9,  // ❌ ALWAYS 0.9
        score: 10.0       // ❌ ALWAYS 10.0
    )
}

// ✅ CORRECT: Randomized values
func generateScenario() -> Scenario {
    Scenario(
        similarity: Double.random(in: 0.7...0.95),  // ✅ Different
        score: Float.random(in: 8.0...12.0)         // ✅ Different
    )
}
```

**❌ No Parameterization (Hardcoded Sample Count):**
```swift
// ❌ WRONG: Hardcoded
for _ in 0..<1000 {  // ❌ Can't scale
    // ...
}

// ✅ CORRECT: Parameterizable
let sampleCount = ProcessInfo.processInfo.environment["VALIDATION_SAMPLES"]
    .flatMap(Int.init) ?? 100

for _ in 0..<sampleCount {  // ✅ Scalable
    // ...
}
```

## Test Coverage Goals

### Current Coverage
- **Domain:** ConvergenceEvidence (TRM core logic) - Production validated
- **Application:** HybridSearch, ContextGraphTracker - Production validated
- **Infrastructure:** Minimal (placeholder only)

### Target Coverage (See TEST_COVERAGE_ANALYSIS.md)

**Phase 1 (Weeks 1-2):** Critical foundation
- 15 test files
- Core use cases: GeneratePRD, ThinkingOrchestrator, TRM
- AI provider contract tests

**Phase 2 (Weeks 3-4):** Core business logic
- +18 test files
- All use cases
- Domain entities

**Phase 3 (Weeks 5-6):** Infrastructure & adapters
- +20 test files
- All adapters
- E2E integration tests

**Phase 4 (Weeks 7-8):** Comprehensive coverage
- +25 test files
- Edge cases, performance
- 85%+ overall coverage

## Test Infrastructure

### Planned Test Utilities

```
TestUtilities/
├── Factories/
│   ├── MockFactory.swift           # Central mock factory
│   ├── TestDataFactory.swift       # Synthetic data generators
│   └── FixtureLoader.swift        # Load test fixtures
│
├── Generators/
│   ├── TrajectoryGenerator.swift   # Random reasoning trajectories
│   ├── CodebaseGenerator.swift     # Synthetic codebases
│   ├── PRDGenerator.swift         # Test PRD documents
│   └── EmbeddingGenerator.swift   # Test embeddings
│
├── Assertions/
│   ├── CustomAssertions.swift     # Domain-specific assertions
│   ├── StatisticalAssertions.swift # Production validation helpers
│   └── AsyncAssertions.swift      # Async/await test helpers
│
└── Mocks/
    ├── MockAIProvider.swift       # Configurable AI provider
    ├── MockRepository.swift       # In-memory repository
    ├── MockEmbedder.swift        # Deterministic embeddings
    └── MockTokenizer.swift       # Predictable token counts
```

## Verification

Tests are verified by `scripts/verify-production-tests.sh` which checks:

1. ✅ **Parameterizable Sample Count** - Uses `VALIDATION_SAMPLES`
2. ✅ **Randomization Usage** - Tests use `.random()`, `.shuffled()`
3. ✅ **Statistical Validation** - Includes mean, variance, CI
4. ✅ **No Fixed Values** - No hardcoded test data
5. ✅ **Multiple Run Stability** - Runs 5+ times for variance
6. ✅ **Real Implementation** - Calls actual services

Run verification:
```bash
cd .. && ./scripts/verify-production-tests.sh
```

## References

- **[CLAUDE.md Section 0.5](../../CLAUDE.md)** - Production Validation standards
- **[TEST_COVERAGE_ANALYSIS.md](../../TEST_COVERAGE_ANALYSIS.md)** - 4-phase coverage plan
- **[ADR 009](../../docs/architecture/decisions/009-production-test-validation-system.md)** - Test validation system
- **[verify-production-tests.sh](../../scripts/verify-production-tests.sh)** - Verification script

---

**Key Principle:** Production tests validate both test generators AND implementation correctness with 1M different scenarios, not 1M repetitions.
