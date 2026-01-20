import Foundation
import Domain

/// Reranks retrieved chunks for improved relevance
/// Following Single Responsibility: Only handles result reranking
public struct RerankingService: Sendable {
    private let aiProvider: AIProviderPort

    public init(aiProvider: AIProviderPort) {
        self.aiProvider = aiProvider
    }

    /// Rerank chunks using cross-encoder approach via LLM
    public func rerank(
        chunks: [SimilarCodeChunk],
        query: String,
        topK: Int = 5
    ) async throws -> [RankedChunk] {
        guard !chunks.isEmpty else { return [] }

        // For small result sets, just score each chunk
        var scoredChunks: [ScoredChunk] = []

        for chunk in chunks {
            let relevanceScore = try await scoreRelevance(
                chunk: chunk.chunk,
                query: query
            )

            scoredChunks.append(ScoredChunk(
                chunk: chunk,
                rerankScore: relevanceScore,
                originalScore: Double(chunk.similarity)
            ))
        }

        // Combine original similarity with rerank score (weighted average)
        let reranked = scoredChunks
            .map { scored -> RankedChunk in
                let combinedScore = (scored.originalScore * 0.3) + (scored.rerankScore * 0.7)
                return RankedChunk(
                    chunk: scored.chunk.chunk,
                    originalSimilarity: scored.originalScore,
                    rerankScore: scored.rerankScore,
                    finalScore: combinedScore
                )
            }
            .sorted { $0.finalScore > $1.finalScore }
            .prefix(topK)

        return Array(reranked)
    }

    // MARK: - Private Methods

    /// Score chunk relevance using LLM as cross-encoder
    private func scoreRelevance(
        chunk: CodeChunk,
        query: String
    ) async throws -> Double {
        let prompt = buildRelevancePrompt(chunk: chunk, query: query)

        let response = try await aiProvider.generateText(
            prompt: prompt,
            temperature: 0.0
        )

        return parseRelevanceScore(from: response)
    }

    private func buildRelevancePrompt(chunk: CodeChunk, query: String) -> String {
        """
        Rate the relevance of this code chunk to the given query.

        Query: \(query)

        Code Chunk (\(chunk.filePath), lines \(chunk.startLine)-\(chunk.endLine)):
        ```
        \(chunk.content)
        ```

        Rate relevance on a scale from 0.0 (completely irrelevant) to 1.0 (perfectly relevant).
        Consider:
        - Semantic relevance to the query
        - Code quality and completeness
        - Usefulness for understanding the query context

        Output ONLY a number between 0.0 and 1.0, nothing else.
        """
    }

    private func parseRelevanceScore(from response: String) -> Double {
        let cleaned = response
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: ",", with: ".")

        // Try to extract number from response
        if let score = Double(cleaned), score >= 0.0, score <= 1.0 {
            return score
        }

        // Try to find first number in response
        let pattern = #"(\d+\.?\d*)"#
        if let regex = try? NSRegularExpression(pattern: pattern),
           let match = regex.firstMatch(in: cleaned, range: NSRange(cleaned.startIndex..., in: cleaned)),
           let range = Range(match.range(at: 1), in: cleaned),
           let score = Double(cleaned[range]),
           score >= 0.0, score <= 1.0 {
            return score
        }

        // Fallback to moderate score if parsing fails
        return 0.5
    }
}


