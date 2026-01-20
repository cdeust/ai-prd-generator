import Foundation
import Domain

/// CLI implementation of user interaction for clarification questions
public actor CLIInteractionHandler: UserInteractionPort {
    public init() {}

    public func askQuestion(_ question: ClarificationQuestion<String, Int, String>) async -> String? {
        let separator = String(repeating: "─", count: 60)

        print("\n\(separator)")
        print("📋 \(question.category.value.capitalized) Question (Priority: \(question.priority.value))")
        print("\n\(question.question)")
        print("\n💡 Why: \(question.rationale)")

        if !question.examples.isEmpty {
            print("\n📝 Examples:")
            for example in question.examples {
                print("  • \(example)")
            }
        }

        print(separator)
        print("\nYour answer (or 'skip'): ", terminator: "")
        fflush(stdout)

        guard let answer = readLine()?.trimmingCharacters(in: .whitespaces),
              !answer.isEmpty,
              answer.lowercased() != "skip" else {
            return nil
        }

        return answer
    }

    public func notifyProgress(_ message: String) async {
        print("ℹ️  \(message)")
        fflush(stdout)
    }
}
