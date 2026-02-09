import AIPRDSharedUtilities
import Foundation
import AIPRDSharedUtilities

struct CodeChunkingState {
    var chunks: [TextChunk]
    var currentChunk: String
    var currentStart: Int

    init() {
        self.chunks = []
        self.currentChunk = ""
        self.currentStart = 0
    }

    func withChunk(_ chunk: TextChunk) -> CodeChunkingState {
        var new = self
        new.chunks.append(chunk)
        return new
    }

    func withCurrentChunk(_ content: String, start: Int) -> CodeChunkingState {
        var new = self
        new.currentChunk = content
        new.currentStart = start
        return new
    }

    func withAppendedChunk(_ content: String) -> CodeChunkingState {
        var new = self
        if !new.currentChunk.isEmpty {
            new.currentChunk += "\n\n"
        }
        new.currentChunk += content
        return new
    }
}
