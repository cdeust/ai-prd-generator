import Foundation
import Domain

/// Generic token-aware content generator for large inputs
/// Handles chunking, token budget management, and parallel/sequential generation
///
/// **Use Cases:**
/// - PRD section generation (multi-pass, 6 sections)
/// - JIRA ticket generation (large PRDs → multiple ticket batches)
/// - Any AI generation task with token limits
///
/// **Strategy:**
/// 1. Calculate available token budget (total - system prompt - buffer)
/// 2. Chunk content to fit budget
/// 3. Generate content for each chunk
/// 4. Merge results
public struct TokenAwareContentGenerator<Content, Result>: Sendable where Content: Sendable, Result: Sendable {
    private let tokenizer: TokenizerPort?
    private let maxContextTokens: Int
    private let systemPromptTokens: Int
    private let bufferTokens: Int

    public init(
        tokenizer: TokenizerPort?,
        maxContextTokens: Int = 4096,
        systemPromptTokens: Int = 500,
        bufferTokens: Int = 100
    ) {
        self.tokenizer = tokenizer
        self.maxContextTokens = maxContextTokens
        self.systemPromptTokens = systemPromptTokens
        self.bufferTokens = bufferTokens
    }

    /// Generate content in token-aware chunks
    ///
    /// - Parameters:
    ///   - items: Content items to process
    ///   - estimateTokens: Function to estimate tokens for an item
    ///   - processChunk: Function to process a chunk of items
    /// - Returns: Merged results from all chunks
    public func generate(
        items: [Content],
        estimateTokens: @escaping (Content) async throws -> Int,
        processChunk: @escaping ([Content], Int, Int) async throws -> [Result]
    ) async throws -> [Result] {
        // Calculate available token budget
        let availableTokens = maxContextTokens - systemPromptTokens - bufferTokens

        // Chunk items to fit budget
        let chunks = try await chunkItems(items, maxTokens: availableTokens, estimateTokens: estimateTokens)

        print("📊 [TokenAware] Processing \(items.count) items in \(chunks.count) chunks (budget: \(availableTokens) tokens/chunk)")

        // Process each chunk
        var allResults: [Result] = []
        for (index, chunk) in chunks.enumerated() {
            print("🔄 [TokenAware] Processing chunk \(index + 1)/\(chunks.count) (\(chunk.count) items)")
            let results = try await processChunk(chunk, index, chunks.count)
            allResults.append(contentsOf: results)
        }

        print("✅ [TokenAware] Generated \(allResults.count) results total")
        return allResults
    }

    /// Chunk items to fit within token budget
    private func chunkItems(
        _ items: [Content],
        maxTokens: Int,
        estimateTokens: @escaping (Content) async throws -> Int
    ) async throws -> [[Content]] {
        var chunks: [[Content]] = []
        var currentChunk: [Content] = []
        var currentTokens = 0

        for item in items {
            let itemTokens = try await estimateTokens(item)

            // If adding this item exceeds budget, start new chunk
            if currentTokens + itemTokens > maxTokens && !currentChunk.isEmpty {
                chunks.append(currentChunk)
                currentChunk = [item]
                currentTokens = itemTokens
            } else {
                currentChunk.append(item)
                currentTokens += itemTokens
            }
        }

        // Add final chunk
        if !currentChunk.isEmpty {
            chunks.append(currentChunk)
        }

        return chunks.isEmpty ? [[]] : chunks
    }

    /// Estimate tokens for text
    public func countTokens(in text: String) async throws -> Int {
        if let tokenizer = tokenizer {
            return try await tokenizer.countTokens(in: text)
        }
        // Fallback: ~4 chars per token (conservative estimate)
        return text.count / 4
    }
}

/// Specialized token-aware generator for PRD sections
public typealias SectionTokenGenerator = TokenAwareContentGenerator<PRDSection, PRDSection>

/// Specialized token-aware generator for JIRA tickets
public typealias JiraTokenGenerator = TokenAwareContentGenerator<PRDSection, JiraTicket>
