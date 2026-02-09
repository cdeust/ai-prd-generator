import AIPRDSharedUtilities
import Foundation

// MARK: - Public API Re-exports
//
// This file re-exports Domain and Application types that Presenter Layer needs.
// Presenters (Backend, CLI, etc.) should ONLY import Composition module.
//
// This enforces Layered Isolation Architecture:
// - Presenters cannot bypass LibraryComposition interface
// - Presenters cannot access internal Application/Domain implementation
// - Business Layer is protected from presenter corruption

@_exported import AIPRDSharedUtilities
@_exported import Application
