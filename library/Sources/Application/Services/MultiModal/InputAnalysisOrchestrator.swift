import Foundation
import Domain

/// Orchestrates input analysis strategies based on provided data
///
/// Determines optimal analysis approach based on:
/// - Input types (text, mockups, codebase)
/// - Input quality and completeness
/// - Available resources
public actor InputAnalysisOrchestrator: Sendable {
    private let multiModalService: MultiModalAnalysisService
    private let contextAggregator: ContextAggregator

    public init(
        multiModalService: MultiModalAnalysisService,
        contextAggregator: ContextAggregator
    ) {
        self.multiModalService = multiModalService
        self.contextAggregator = contextAggregator
    }

    /// Orchestrate comprehensive input analysis
    ///
    /// - Parameter request: Analysis request with inputs
    /// - Returns: Aggregated analysis context ready for PRD generation
    public func orchestrateAnalysis(
        _ request: InputAnalysisRequest
    ) async throws -> AggregatedContext {
        // Validate inputs
        try validateRequest(request)

        // Determine analysis strategy
        let strategy = selectStrategy(for: request)

        // Execute analysis
        let result = try await executeAnalysis(
            request: request,
            strategy: strategy
        )

        // Aggregate into unified context
        return try await contextAggregator.aggregate(result)
    }

    /// Validate input analysis request
    private func validateRequest(_ request: InputAnalysisRequest) throws {
        guard !request.textDescription.isEmpty else {
            throw InputAnalysisError.emptyTextDescription
        }

        if let images = request.mockupImages, images.isEmpty {
            throw InputAnalysisError.emptyMockupImages
        }
    }

    /// Select optimal analysis strategy
    private func selectStrategy(
        for request: InputAnalysisRequest
    ) -> AnalysisStrategy {
        let hasMockups = request.mockupImages?.isEmpty == false
        let hasCodebase = request.codebaseId != nil

        switch (hasMockups, hasCodebase) {
        case (true, true):
            return .comprehensive
        case (true, false):
            return .mockupFocused
        case (false, true):
            return .codebaseFocused
        case (false, false):
            return .textOnly
        }
    }

    /// Execute analysis based on selected strategy
    private func executeAnalysis(
        request: InputAnalysisRequest,
        strategy: AnalysisStrategy
    ) async throws -> MultiModalAnalysisResult {
        switch strategy {
        case .comprehensive:
            return try await analyzeComprehensive(request)
        case .mockupFocused:
            return try await analyzeMockupFocused(request)
        case .codebaseFocused:
            return try await analyzeCodebaseFocused(request)
        case .textOnly:
            return try await analyzeTextOnly(request)
        }
    }

    /// Comprehensive analysis (all inputs)
    private func analyzeComprehensive(
        _ request: InputAnalysisRequest
    ) async throws -> MultiModalAnalysisResult {
        try await multiModalService.analyzeInputs(
            textDescription: request.textDescription,
            mockupImages: request.mockupImages ?? [],
            codebaseId: request.codebaseId
        )
    }

    /// Mockup-focused analysis
    private func analyzeMockupFocused(
        _ request: InputAnalysisRequest
    ) async throws -> MultiModalAnalysisResult {
        try await multiModalService.analyzeInputs(
            textDescription: request.textDescription,
            mockupImages: request.mockupImages ?? [],
            codebaseId: nil
        )
    }

    /// Codebase-focused analysis
    private func analyzeCodebaseFocused(
        _ request: InputAnalysisRequest
    ) async throws -> MultiModalAnalysisResult {
        try await multiModalService.analyzeInputs(
            textDescription: request.textDescription,
            mockupImages: [],
            codebaseId: request.codebaseId
        )
    }

    /// Text-only analysis
    private func analyzeTextOnly(
        _ request: InputAnalysisRequest
    ) async throws -> MultiModalAnalysisResult {
        MultiModalAnalysisResult(
            textDescription: request.textDescription,
            mockupAnalysis: [],
            codebaseContext: nil,
            analyzedAt: Date()
        )
    }
}
