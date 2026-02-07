# PRD: Snippet Library - Core CRUD

**Version:** 1.0
**Date:** 2026-02-05
**Author:** AI PRD Generator v7.0
**Status:** Draft
**Epic:** Core CRUD Operations
**Estimated SP:** 13

---

## Table of Contents

1. [Overview](#1-overview)
2. [Goals & Metrics](#2-goals--metrics)
3. [Requirements](#3-requirements)
4. [User Stories](#4-user-stories)
5. [Technical Specification](#5-technical-specification)
6. [Acceptance Criteria](#6-acceptance-criteria)
7. [UI/UX Specifications](#7-uiux-specifications)
8. [Security & Privacy](#8-security--privacy)
9. [Implementation Roadmap](#9-implementation-roadmap)
10. [Open Questions](#10-open-questions)
11. [Appendix](#11-appendix)

---

## 1. Overview

### 1.1 Executive Summary

The Snippet Library feature enables users to create, store, organize, and manage reusable text snippets within the AI PRD Builder application. This foundational epic establishes the core CRUD (Create, Read, Update, Delete) operations that will serve as the base for future enhancements including search, version history, and PRD integration.

### 1.2 Problem Statement

Product managers and technical writers frequently reuse standardized text blocks when creating PRDs—acceptance criteria templates, common user stories, technical specifications, and process documentation. Currently, users must manually copy-paste from external sources or recreate content repeatedly, leading to:

- **Inconsistency** in documentation across PRDs
- **Time waste** recreating common content blocks
- **Lost knowledge** when useful snippets aren't preserved
- **Reduced productivity** due to context switching

### 1.3 Product Vision

A native, cross-platform (iOS + macOS) snippet management system that integrates seamlessly with the AI PRD Builder workflow, enabling users to build a personal library of reusable content that improves PRD quality and authoring speed.

### 1.4 Strategic Goals

| ID | Goal | Alignment |
|----|------|-----------|
| SG-001 | Reduce PRD authoring time by enabling content reuse | Core product value |
| SG-002 | Improve PRD consistency through standardized snippets | Quality improvement |
| SG-003 | Build foundation for advanced features (search, AI suggestions, version history) | Platform extensibility |
| SG-004 | Maintain privacy-first approach with local-only storage (MVP) | Product principle |

### 1.5 Target Users

| Persona | Description | Primary Use Case |
|---------|-------------|------------------|
| **Product Manager** | Creates multiple PRDs per month, values consistency | Store acceptance criteria templates, user story patterns |
| **Technical Writer** | Documents features, APIs, processes | Maintain standardized documentation blocks |
| **Engineering Lead** | Reviews and contributes to PRDs | Quick access to technical specification templates |

### 1.6 Scope

**In Scope (This PRD):**
- Create new snippets with title, content, type, and tags
- View list of all snippets with basic display
- View individual snippet details
- Edit existing snippets
- Soft delete snippets (recoverable within 30 days)
- Basic input validation
- SwiftData local persistence
- Cross-platform support (iOS + macOS)

**Out of Scope (Future Epics):**
- Search and filtering (Epic 2)
- Version history and rollback (Epic 3)
- PRD insertion/integration (Epic 4)
- iCloud sync
- Snippet sharing
- AI-powered suggestions
- Import/export functionality

### 1.7 Success Criteria

| Metric | Baseline | Target | Measurement |
|--------|----------|--------|-------------|
| Snippet creation success rate | N/A (new feature) | ≥ 99% | Error tracking |
| List view load time | N/A | < 300ms for 2,000 snippets | Performance monitoring |
| User satisfaction | N/A | ≥ 4.0/5.0 | In-app feedback |
| Crash-free sessions | N/A | ≥ 99.5% | Crash reporting |

---

## 2. Goals & Metrics

### 2.1 Business Goals

| ID | Goal | Baseline | Target | Measurement | Impact |
|----|------|----------|--------|-------------|--------|
| BG-001 | Reduce time to create PRDs with reusable content | 4.2 hours/PRD (manual) | 3.0 hours/PRD (-29%) | Time tracking analytics | Core value proposition |
| BG-002 | Increase PRD consistency through template snippets | Manual copy-paste (error-prone) | Standardized snippets | Quality audit sampling | Documentation quality |
| BG-003 | Establish foundation for AI-enhanced snippet suggestions | 0 snippets indexed | 2,000 snippets/user capacity | Storage metrics | Platform extensibility |

### 2.2 Product Goals

| ID | Goal | Baseline | Target | Measurement | Impact |
|----|------|----------|--------|-------------|--------|
| PG-001 | Enable snippet creation in < 30 seconds | N/A (new feature) | < 30s average | Time-to-completion tracking | User productivity |
| PG-002 | Support organizing snippets by type and tags | N/A | 100% snippets categorized | Metadata completeness | Discoverability |
| PG-003 | Maintain data integrity with validation | N/A | 0 corrupt/invalid snippets | Data validation checks | Reliability |

### 2.3 Technical Goals

| ID | Goal | Baseline | Target | Measurement | Impact |
|----|------|----------|--------|-------------|--------|
| TG-001 | List view renders 2,000 snippets efficiently | N/A | < 300ms initial load | Performance profiling | Scalability |
| TG-002 | SwiftData persistence with zero data loss | N/A | 100% data integrity | Automated backup verification | Reliability |
| TG-003 | Cross-platform parity (iOS + macOS) | N/A | 100% feature parity | Platform testing matrix | Consistency |

### 2.4 Key Performance Indicators (KPIs)

| KPI | Definition | Target | Review Frequency |
|-----|------------|--------|------------------|
| **Snippet Adoption Rate** | % of active users who create ≥1 snippet | ≥ 30% in first 90 days | Weekly |
| **Snippets per User** | Average snippets created per active user | ≥ 15 in first 90 days | Weekly |
| **Edit Frequency** | % of snippets edited after creation | ≥ 20% | Monthly |
| **Deletion Rate** | % of snippets soft-deleted | < 10% | Monthly |
| **Recovery Rate** | % of deleted snippets recovered | Track (no target) | Monthly |

### 2.5 Non-Goals

| What We Won't Do | Rationale |
|------------------|-----------|
| Real-time sync across devices | MVP focuses on local-only; iCloud sync is future epic |
| AI-powered snippet suggestions | Requires search infrastructure; planned for Epic 3+ |
| Collaborative editing | Single-user MVP; workspace features are future scope |
| Import from external sources | Focus on native creation first; import is enhancement |

---

## 3. Requirements

### 3.1 Functional Requirements

| ID | Requirement | Priority | Rationale |
|----|-------------|----------|-----------|
| **FR-001** | User can create a new snippet with title, content, type, and tags | P0 | Core functionality |
| **FR-002** | User can view a list of all their snippets | P0 | Core functionality |
| **FR-003** | User can view details of a single snippet | P0 | Core functionality |
| **FR-004** | User can edit an existing snippet's title, content, type, and tags | P0 | Core functionality |
| **FR-005** | User can soft-delete a snippet | P0 | Core functionality |
| **FR-006** | System validates snippet title is 1-200 characters and required | P0 | Data integrity |
| **FR-007** | System validates snippet content is ≤ 5,000 characters | P0 | Data integrity |
| **FR-008** | System enforces maximum 10 tags per snippet | P0 | Data integrity |
| **FR-009** | User can select snippet type from predefined list (Feature only for MVP) | P0 | Categorization |
| **FR-010** | User can add tags from predefined suggestions (User Experience, API) | P1 | Discoverability |
| **FR-011** | User can add custom tags beyond predefined list | P1 | Flexibility |
| **FR-012** | System displays snippet metadata (created date, updated date) | P1 | Context |
| **FR-013** | List view supports infinite scroll loading | P1 | UX requirement |
| **FR-014** | User can recover soft-deleted snippets within 30 days | P1 | Error recovery |
| **FR-015** | System persists snippets locally using SwiftData | P0 | Persistence |
| **FR-016** | System auto-saves snippet drafts during creation/editing | P2 | UX enhancement |
| **FR-017** | System provides confirmation before delete action | P1 | Error prevention |
| **FR-018** | Tags are displayed as removable chips in create/edit form | P1 | UX per mockup |
| **FR-019** | Empty state shown when no snippets exist | P1 | UX guidance |
| **FR-020** | Snippet list shows title, type badge, and tag chips | P0 | List UX per mockup |

### 3.2 Non-Functional Requirements

| ID | Requirement | Target | Measurement |
|----|-------------|--------|-------------|
| **NFR-001** | List view initial load time | < 300ms for 2,000 snippets | Xcode Instruments |
| **NFR-002** | Snippet detail view load time | < 100ms | Xcode Instruments |
| **NFR-003** | Create/Update operation latency | < 200ms | Performance logging |
| **NFR-004** | Memory footprint for list view | < 50MB for 2,000 snippets | Memory profiling |
| **NFR-005** | Crash-free session rate | ≥ 99.5% | Crash reporting |
| **NFR-006** | Data persistence reliability | 0 data loss incidents | Automated testing |
| **NFR-007** | iOS minimum version | iOS 17.0+ | Platform requirement |
| **NFR-008** | macOS minimum version | macOS 14.0+ | Platform requirement |
| **NFR-009** | Accessibility compliance | WCAG 2.1 AA | Accessibility audit |
| **NFR-010** | Offline functionality | 100% features work offline | Testing |
| **NFR-011** | Storage efficiency | < 1KB per snippet average | Storage analysis |
| **NFR-012** | VoiceOver support | Full support for all UI elements | Accessibility testing |

### 3.3 Data Requirements

| Entity | Attribute | Type | Constraints |
|--------|-----------|------|-------------|
| Snippet | id | UUID | Primary key, auto-generated |
| Snippet | userId | UUID | Foreign key (future multi-user support) |
| Snippet | title | String | Required, 1-200 characters |
| Snippet | content | String | Optional, ≤ 5,000 characters |
| Snippet | type | Enum | Required, predefined values |
| Snippet | tags | [String] | Optional, max 10 items |
| Snippet | createdAt | Date | Auto-set on creation |
| Snippet | updatedAt | Date | Auto-updated on modification |
| Snippet | deletedAt | Date? | Nil if not deleted (soft delete) |

### 3.4 Constraints

| Constraint | Description | Impact |
|------------|-------------|--------|
| Local-only storage | No cloud sync in MVP | Simplifies architecture; limits cross-device use |
| SwiftData requirement | Requires iOS 17+ / macOS 14+ | Excludes older OS versions |
| Single user model | No multi-user/workspace support | Simplifies data model |
| Feature type only (MVP) | Only "Feature" type available initially | Reduces complexity |

---

## 4. User Stories

### 4.1 Epic: Core CRUD Operations

#### US-001: Create New Snippet

**As a** Product Manager
**I want to** create a new snippet with title, content, type, and tags
**So that** I can save reusable content for future PRDs

**Acceptance Criteria:**

| AC ID | Criteria |
|-------|----------|
| AC-001 | GIVEN I am on the Snippets screen WHEN I tap the "+" button THEN the New Snippet form opens |
| AC-002 | GIVEN I am on the New Snippet form WHEN I enter a valid title (1-200 chars) and tap Save THEN the snippet is created successfully |
| AC-003 | GIVEN I enter a title > 200 characters WHEN I attempt to save THEN an inline validation error is shown |
| AC-004 | GIVEN I enter content > 5,000 characters WHEN I attempt to save THEN an inline validation error is shown |
| AC-005 | GIVEN I add more than 10 tags WHEN I attempt to add the 11th tag THEN the system prevents addition with feedback |
| AC-006 | GIVEN I save a valid snippet WHEN viewing the list THEN the new snippet appears at the top |

**Story Points:** 3

---

#### US-002: View Snippet List

**As a** Product Manager
**I want to** see a list of all my snippets
**So that** I can browse and find the content I need

**Acceptance Criteria:**

| AC ID | Criteria |
|-------|----------|
| AC-007 | GIVEN I have snippets WHEN I open the Snippets tab THEN I see a scrollable list of all snippets |
| AC-008 | GIVEN a snippet in the list THEN I see its title, type badge, and tag chips |
| AC-009 | GIVEN I have 0 snippets WHEN I open the Snippets tab THEN I see an empty state with guidance |
| AC-010 | GIVEN I have 2,000 snippets WHEN I open the list THEN it loads in < 300ms |
| AC-011 | GIVEN I scroll to the bottom WHEN more snippets exist THEN additional snippets load automatically (infinite scroll) |

**Story Points:** 2

---

#### US-003: View Snippet Details

**As a** Product Manager
**I want to** view the full details of a snippet
**So that** I can read the complete content and metadata

**Acceptance Criteria:**

| AC ID | Criteria |
|-------|----------|
| AC-012 | GIVEN I tap a snippet in the list WHEN the detail view opens THEN I see title, content, type, tags, and dates |
| AC-013 | GIVEN I am on the detail view THEN I see "Edit" and "Insert Snippet" buttons (Insert disabled for MVP) |
| AC-014 | GIVEN the snippet has a long content THEN it is scrollable within the detail view |
| AC-015 | GIVEN I tap the back button WHEN on detail view THEN I return to the list at the same scroll position |

**Story Points:** 2

---

#### US-004: Edit Existing Snippet

**As a** Product Manager
**I want to** edit an existing snippet
**So that** I can update or improve my saved content

**Acceptance Criteria:**

| AC ID | Criteria |
|-------|----------|
| AC-016 | GIVEN I am on the Snippet Detail view WHEN I tap "Edit" THEN the edit form opens pre-populated with current values |
| AC-017 | GIVEN I modify any field and tap Save THEN the changes are persisted |
| AC-018 | GIVEN I modify a snippet WHEN saved THEN the updatedAt timestamp is updated |
| AC-019 | GIVEN I am editing WHEN I tap Cancel THEN changes are discarded and I return to detail view |
| AC-020 | GIVEN I remove all tags WHEN I save THEN the snippet is saved with empty tags array |

**Story Points:** 2

---

#### US-005: Delete Snippet

**As a** Product Manager
**I want to** delete a snippet I no longer need
**So that** I can keep my library organized

**Acceptance Criteria:**

| AC ID | Criteria |
|-------|----------|
| AC-021 | GIVEN I am on Snippet Detail WHEN I tap Delete THEN a confirmation dialog appears |
| AC-022 | GIVEN I confirm deletion WHEN confirmed THEN the snippet is soft-deleted (deletedAt set) |
| AC-023 | GIVEN I soft-delete a snippet THEN it no longer appears in the main list |
| AC-024 | GIVEN I cancel deletion WHEN in confirmation dialog THEN no changes occur |
| AC-025 | GIVEN a snippet was deleted < 30 days ago WHEN accessing deleted items THEN I can recover it |

**Story Points:** 2

---

#### US-006: Tag Management

**As a** Product Manager
**I want to** add and remove tags on my snippets
**So that** I can organize content for easier discovery

**Acceptance Criteria:**

| AC ID | Criteria |
|-------|----------|
| AC-026 | GIVEN I am creating/editing a snippet WHEN I type in the tags field THEN I see predefined suggestions (User Experience, API) |
| AC-027 | GIVEN I type a custom tag WHEN I press comma or enter THEN the tag is added as a chip |
| AC-028 | GIVEN a tag chip is displayed WHEN I tap the X on the chip THEN the tag is removed |
| AC-029 | GIVEN I have 10 tags WHEN I try to add another THEN the input is disabled with "Max 10 tags" message |
| AC-030 | GIVEN I add a duplicate tag WHEN saving THEN duplicates are automatically removed |

**Story Points:** 2

---

### 4.2 User Story Summary

| Story ID | Title | Priority | SP | Dependencies |
|----------|-------|----------|-----|--------------|
| US-001 | Create New Snippet | P0 | 3 | None |
| US-002 | View Snippet List | P0 | 2 | US-001 |
| US-003 | View Snippet Details | P0 | 2 | US-002 |
| US-004 | Edit Existing Snippet | P0 | 2 | US-003 |
| US-005 | Delete Snippet | P0 | 2 | US-003 |
| US-006 | Tag Management | P1 | 2 | US-001 |
| **Total** | | | **13** | |

---

## 5. Technical Specification

### 5.1 Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                    Presentation Layer                        │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐  │
│  │ SnippetList │  │SnippetDetail│  │SnippetCreate/Edit   │  │
│  │    View     │  │    View     │  │       View          │  │
│  └──────┬──────┘  └──────┬──────┘  └──────────┬──────────┘  │
└─────────┼────────────────┼───────────────────┼──────────────┘
          │                │                   │
          ▼                ▼                   ▼
┌─────────────────────────────────────────────────────────────┐
│                    Application Layer                         │
│  ┌───────────────────────────────────────────────────────┐  │
│  │                 SnippetViewModel                       │  │
│  │  - createSnippet(input: SnippetInput) → Snippet       │  │
│  │  - updateSnippet(id: UUID, input: SnippetInput)       │  │
│  │  - deleteSnippet(id: UUID)                            │  │
│  │  - fetchSnippets() → [Snippet]                        │  │
│  │  - recoverSnippet(id: UUID)                           │  │
│  └───────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
          │
          ▼
┌─────────────────────────────────────────────────────────────┐
│                      Domain Layer                            │
│  ┌─────────────────┐  ┌──────────────────────────────────┐  │
│  │  Snippet Entity │  │  SnippetRepository (Protocol)    │  │
│  │  SnippetType    │  │  - save(snippet:) → Snippet      │  │
│  │  SnippetInput   │  │  - fetch(id:) → Snippet?         │  │
│  │  ValidationErr  │  │  - fetchAll() → [Snippet]        │  │
│  └─────────────────┘  │  - delete(id:)                   │  │
│                       │  - recover(id:)                  │  │
│                       └──────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
          │
          ▼
┌─────────────────────────────────────────────────────────────┐
│                    Infrastructure Layer                      │
│  ┌───────────────────────────────────────────────────────┐  │
│  │           SwiftDataSnippetRepository                   │  │
│  │  - Implements SnippetRepository protocol               │  │
│  │  - Uses SwiftData ModelContainer                       │  │
│  └───────────────────────────────────────────────────────┘  │
│  ┌───────────────────────────────────────────────────────┐  │
│  │                   SwiftData Store                      │  │
│  │  - @Model Snippet                                      │  │
│  │  - ModelContainer                                      │  │
│  │  - ModelContext                                        │  │
│  └───────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

### 5.2 Domain Models (Swift)

```swift
// MARK: - Domain/Entities/Snippet.swift

import Foundation

/// Snippet type enumeration
public enum SnippetType: String, Codable, CaseIterable, Identifiable {
    case feature = "Feature"
    // Future types (not in MVP):
    // case bug = "Bug"
    // case improvement = "Improvement"
    // case process = "Process"

    public var id: String { rawValue }

    public var displayName: String { rawValue }

    public var iconName: String {
        switch self {
        case .feature: return "star.fill"
        }
    }
}

/// Predefined tags for suggestions
public enum PredefinedTag: String, CaseIterable {
    case userExperience = "User Experience"
    case api = "API"

    public static var allValues: [String] {
        allCases.map { $0.rawValue }
    }
}

/// Domain entity for Snippet
public struct Snippet: Identifiable, Equatable, Sendable {
    public let id: UUID
    public let userId: UUID
    public var title: String
    public var content: String
    public var type: SnippetType
    public var tags: [String]
    public let createdAt: Date
    public var updatedAt: Date
    public var deletedAt: Date?

    // MARK: - Business Rules

    public static let maxTitleLength = 200
    public static let maxContentLength = 5_000
    public static let maxTagCount = 10
    public static let softDeleteRetentionDays = 30

    // MARK: - Computed Properties

    public var isDeleted: Bool {
        deletedAt != nil
    }

    public var canBeRecovered: Bool {
        guard let deletedAt = deletedAt else { return false }
        let daysSinceDeleted = Calendar.current.dateComponents(
            [.day],
            from: deletedAt,
            to: Date()
        ).day ?? 0
        return daysSinceDeleted < Self.softDeleteRetentionDays
    }

    // MARK: - Initialization

    public init(
        id: UUID = UUID(),
        userId: UUID,
        title: String,
        content: String = "",
        type: SnippetType = .feature,
        tags: [String] = [],
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        deletedAt: Date? = nil
    ) throws {
        // Validation
        guard !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw SnippetError.titleRequired
        }
        guard title.count <= Self.maxTitleLength else {
            throw SnippetError.titleTooLong(current: title.count, max: Self.maxTitleLength)
        }
        guard content.count <= Self.maxContentLength else {
            throw SnippetError.contentTooLong(current: content.count, max: Self.maxContentLength)
        }
        guard tags.count <= Self.maxTagCount else {
            throw SnippetError.tooManyTags(current: tags.count, max: Self.maxTagCount)
        }

        self.id = id
        self.userId = userId
        self.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        self.content = content
        self.type = type
        self.tags = Array(Set(tags)).sorted() // Remove duplicates, sort
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.deletedAt = deletedAt
    }
}

/// Snippet validation errors
public enum SnippetError: Error, LocalizedError, Equatable {
    case titleRequired
    case titleTooLong(current: Int, max: Int)
    case contentTooLong(current: Int, max: Int)
    case tooManyTags(current: Int, max: Int)
    case notFound(id: UUID)
    case alreadyDeleted(id: UUID)
    case cannotRecover(id: UUID)
    case persistenceError(String)

    public var errorDescription: String? {
        switch self {
        case .titleRequired:
            return "Title is required"
        case .titleTooLong(let current, let max):
            return "Title is too long (\(current)/\(max) characters)"
        case .contentTooLong(let current, let max):
            return "Content is too long (\(current)/\(max) characters)"
        case .tooManyTags(let current, let max):
            return "Too many tags (\(current)/\(max))"
        case .notFound(let id):
            return "Snippet not found: \(id)"
        case .alreadyDeleted(let id):
            return "Snippet already deleted: \(id)"
        case .cannotRecover(let id):
            return "Cannot recover snippet (expired): \(id)"
        case .persistenceError(let message):
            return "Storage error: \(message)"
        }
    }
}

/// Input DTO for creating/updating snippets
public struct SnippetInput: Equatable, Sendable {
    public let title: String
    public let content: String
    public let type: SnippetType
    public let tags: [String]

    public init(
        title: String,
        content: String = "",
        type: SnippetType = .feature,
        tags: [String] = []
    ) {
        self.title = title
        self.content = content
        self.type = type
        self.tags = tags
    }
}
```

### 5.3 Repository Protocol (Domain Layer)

```swift
// MARK: - Domain/Ports/SnippetRepository.swift

import Foundation

/// Repository protocol for Snippet persistence
/// Implementations live in Infrastructure layer
public protocol SnippetRepository: Sendable {
    /// Create a new snippet
    func save(snippet: Snippet) async throws -> Snippet

    /// Fetch a single snippet by ID
    func fetch(id: UUID) async throws -> Snippet?

    /// Fetch all non-deleted snippets for a user
    func fetchAll(userId: UUID) async throws -> [Snippet]

    /// Fetch deleted snippets that can still be recovered
    func fetchDeleted(userId: UUID) async throws -> [Snippet]

    /// Update an existing snippet
    func update(snippet: Snippet) async throws -> Snippet

    /// Soft delete a snippet
    func softDelete(id: UUID) async throws

    /// Recover a soft-deleted snippet
    func recover(id: UUID) async throws

    /// Permanently delete expired soft-deleted snippets
    func purgeExpired() async throws -> Int
}
```

### 5.4 SwiftData Implementation (Infrastructure Layer)

```swift
// MARK: - Infrastructure/Persistence/SnippetModel.swift

import Foundation
import SwiftData

/// SwiftData model for Snippet persistence
@Model
public final class SnippetModel {
    @Attribute(.unique) public var id: UUID
    public var userId: UUID
    public var title: String
    public var content: String
    public var typeRawValue: String
    public var tags: [String]
    public var createdAt: Date
    public var updatedAt: Date
    public var deletedAt: Date?

    public init(
        id: UUID = UUID(),
        userId: UUID,
        title: String,
        content: String = "",
        typeRawValue: String = SnippetType.feature.rawValue,
        tags: [String] = [],
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        deletedAt: Date? = nil
    ) {
        self.id = id
        self.userId = userId
        self.title = title
        self.content = content
        self.typeRawValue = typeRawValue
        self.tags = tags
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.deletedAt = deletedAt
    }

    /// Convert to domain entity
    public func toDomain() throws -> Snippet {
        try Snippet(
            id: id,
            userId: userId,
            title: title,
            content: content,
            type: SnippetType(rawValue: typeRawValue) ?? .feature,
            tags: tags,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt
        )
    }

    /// Update from domain entity
    public func update(from snippet: Snippet) {
        self.title = snippet.title
        self.content = snippet.content
        self.typeRawValue = snippet.type.rawValue
        self.tags = snippet.tags
        self.updatedAt = Date()
        self.deletedAt = snippet.deletedAt
    }
}

// MARK: - Infrastructure/Persistence/SwiftDataSnippetRepository.swift

import Foundation
import SwiftData

/// SwiftData implementation of SnippetRepository
@MainActor
public final class SwiftDataSnippetRepository: SnippetRepository {
    private let modelContainer: ModelContainer
    private let modelContext: ModelContext

    public init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
        self.modelContext = modelContainer.mainContext
    }

    public func save(snippet: Snippet) async throws -> Snippet {
        let model = SnippetModel(
            id: snippet.id,
            userId: snippet.userId,
            title: snippet.title,
            content: snippet.content,
            typeRawValue: snippet.type.rawValue,
            tags: snippet.tags,
            createdAt: snippet.createdAt,
            updatedAt: snippet.updatedAt,
            deletedAt: snippet.deletedAt
        )
        modelContext.insert(model)
        try modelContext.save()
        return try model.toDomain()
    }

    public func fetch(id: UUID) async throws -> Snippet? {
        let descriptor = FetchDescriptor<SnippetModel>(
            predicate: #Predicate { $0.id == id }
        )
        guard let model = try modelContext.fetch(descriptor).first else {
            return nil
        }
        return try model.toDomain()
    }

    public func fetchAll(userId: UUID) async throws -> [Snippet] {
        let descriptor = FetchDescriptor<SnippetModel>(
            predicate: #Predicate { $0.userId == userId && $0.deletedAt == nil },
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )
        let models = try modelContext.fetch(descriptor)
        return try models.map { try $0.toDomain() }
    }

    public func fetchDeleted(userId: UUID) async throws -> [Snippet] {
        let thirtyDaysAgo = Calendar.current.date(
            byAdding: .day,
            value: -Snippet.softDeleteRetentionDays,
            to: Date()
        )!

        let descriptor = FetchDescriptor<SnippetModel>(
            predicate: #Predicate {
                $0.userId == userId &&
                $0.deletedAt != nil &&
                $0.deletedAt! > thirtyDaysAgo
            },
            sortBy: [SortDescriptor(\.deletedAt, order: .reverse)]
        )
        let models = try modelContext.fetch(descriptor)
        return try models.map { try $0.toDomain() }
    }

    public func update(snippet: Snippet) async throws -> Snippet {
        let descriptor = FetchDescriptor<SnippetModel>(
            predicate: #Predicate { $0.id == snippet.id }
        )
        guard let model = try modelContext.fetch(descriptor).first else {
            throw SnippetError.notFound(id: snippet.id)
        }
        model.update(from: snippet)
        try modelContext.save()
        return try model.toDomain()
    }

    public func softDelete(id: UUID) async throws {
        let descriptor = FetchDescriptor<SnippetModel>(
            predicate: #Predicate { $0.id == id }
        )
        guard let model = try modelContext.fetch(descriptor).first else {
            throw SnippetError.notFound(id: id)
        }
        guard model.deletedAt == nil else {
            throw SnippetError.alreadyDeleted(id: id)
        }
        model.deletedAt = Date()
        try modelContext.save()
    }

    public func recover(id: UUID) async throws {
        let descriptor = FetchDescriptor<SnippetModel>(
            predicate: #Predicate { $0.id == id }
        )
        guard let model = try modelContext.fetch(descriptor).first else {
            throw SnippetError.notFound(id: id)
        }
        guard let deletedAt = model.deletedAt else {
            return // Already active
        }

        let daysSinceDeleted = Calendar.current.dateComponents(
            [.day],
            from: deletedAt,
            to: Date()
        ).day ?? 0

        guard daysSinceDeleted < Snippet.softDeleteRetentionDays else {
            throw SnippetError.cannotRecover(id: id)
        }

        model.deletedAt = nil
        model.updatedAt = Date()
        try modelContext.save()
    }

    public func purgeExpired() async throws -> Int {
        let thirtyDaysAgo = Calendar.current.date(
            byAdding: .day,
            value: -Snippet.softDeleteRetentionDays,
            to: Date()
        )!

        let descriptor = FetchDescriptor<SnippetModel>(
            predicate: #Predicate {
                $0.deletedAt != nil && $0.deletedAt! <= thirtyDaysAgo
            }
        )
        let models = try modelContext.fetch(descriptor)
        let count = models.count

        for model in models {
            modelContext.delete(model)
        }
        try modelContext.save()

        return count
    }
}
```

### 5.5 ViewModel (Application Layer)

```swift
// MARK: - Application/ViewModels/SnippetViewModel.swift

import Foundation
import Observation

@Observable
@MainActor
public final class SnippetViewModel {
    // MARK: - Dependencies

    private let repository: SnippetRepository
    private let userId: UUID

    // MARK: - State

    public private(set) var snippets: [Snippet] = []
    public private(set) var deletedSnippets: [Snippet] = []
    public private(set) var isLoading: Bool = false
    public private(set) var error: SnippetError?

    // MARK: - Initialization

    public init(repository: SnippetRepository, userId: UUID) {
        self.repository = repository
        self.userId = userId
    }

    // MARK: - Actions

    public func loadSnippets() async {
        isLoading = true
        error = nil

        do {
            snippets = try await repository.fetchAll(userId: userId)
        } catch let snippetError as SnippetError {
            error = snippetError
        } catch {
            self.error = .persistenceError(error.localizedDescription)
        }

        isLoading = false
    }

    public func createSnippet(input: SnippetInput) async throws -> Snippet {
        let snippet = try Snippet(
            userId: userId,
            title: input.title,
            content: input.content,
            type: input.type,
            tags: input.tags
        )

        let saved = try await repository.save(snippet: snippet)
        snippets.insert(saved, at: 0)
        return saved
    }

    public func updateSnippet(id: UUID, input: SnippetInput) async throws -> Snippet {
        guard let existing = snippets.first(where: { $0.id == id }) else {
            throw SnippetError.notFound(id: id)
        }

        let updated = try Snippet(
            id: existing.id,
            userId: existing.userId,
            title: input.title,
            content: input.content,
            type: input.type,
            tags: input.tags,
            createdAt: existing.createdAt,
            updatedAt: Date(),
            deletedAt: nil
        )

        let saved = try await repository.update(snippet: updated)

        if let index = snippets.firstIndex(where: { $0.id == id }) {
            snippets[index] = saved
        }

        return saved
    }

    public func deleteSnippet(id: UUID) async throws {
        try await repository.softDelete(id: id)
        snippets.removeAll { $0.id == id }
    }

    public func recoverSnippet(id: UUID) async throws {
        try await repository.recover(id: id)
        await loadSnippets()
    }

    public func loadDeletedSnippets() async {
        do {
            deletedSnippets = try await repository.fetchDeleted(userId: userId)
        } catch {
            deletedSnippets = []
        }
    }
}
```

### 5.6 Database Schema (SwiftData)

```swift
// MARK: - Schema Definition

/*
SwiftData automatically generates the schema from @Model classes.
Equivalent SQLite schema for reference:

CREATE TABLE snippet_model (
    id TEXT PRIMARY KEY NOT NULL,          -- UUID as TEXT
    user_id TEXT NOT NULL,                 -- UUID as TEXT
    title TEXT NOT NULL,                   -- 1-200 chars
    content TEXT NOT NULL DEFAULT '',      -- 0-5000 chars
    type_raw_value TEXT NOT NULL DEFAULT 'Feature',
    tags TEXT NOT NULL DEFAULT '[]',       -- JSON array
    created_at REAL NOT NULL,              -- Unix timestamp
    updated_at REAL NOT NULL,              -- Unix timestamp
    deleted_at REAL,                       -- Nullable, soft delete

    CHECK (length(title) >= 1 AND length(title) <= 200),
    CHECK (length(content) <= 5000)
);

-- Index for user queries
CREATE INDEX idx_snippet_user_deleted ON snippet_model(user_id, deleted_at);

-- Index for list ordering
CREATE INDEX idx_snippet_updated ON snippet_model(updated_at DESC);
*/

// ModelContainer configuration
public func createSnippetModelContainer() throws -> ModelContainer {
    let schema = Schema([SnippetModel.self])
    let config = ModelConfiguration(
        schema: schema,
        isStoredInMemoryOnly: false,
        allowsSave: true
    )
    return try ModelContainer(for: schema, configurations: [config])
}
```

### 5.7 Technology Stack

| Layer | Technology | Version | Rationale |
|-------|-----------|---------|-----------|
| UI | SwiftUI | iOS 17+ / macOS 14+ | Native cross-platform UI |
| State | @Observable | Swift 5.9+ | Modern observation pattern |
| Persistence | SwiftData | iOS 17+ / macOS 14+ | Native persistence framework |
| Architecture | Clean Architecture | - | Separation of concerns per CLAUDE.md |
| Testing | XCTest | - | Native testing framework |

---

## 6. Acceptance Criteria with KPIs

### 6.1 Performance Acceptance Criteria

**AC-P001:** List View Load Performance
- [ ] GIVEN 2,000 snippets in database WHEN user opens Snippets tab THEN list renders in < 300ms

| Metric | Value |
|--------|-------|
| Baseline | N/A (new feature) |
| Target | < 300ms initial render |
| Measurement | Xcode Instruments: Time Profiler |
| Business Impact | TG-001: Scalability for power users |
| Validation Dataset | 2,000 synthetic snippets with varied content lengths |

**AC-P002:** Detail View Load Performance
- [ ] GIVEN a snippet with 5,000 char content WHEN user taps to view details THEN detail view renders in < 100ms

| Metric | Value |
|--------|-------|
| Baseline | N/A (new feature) |
| Target | < 100ms render |
| Measurement | Xcode Instruments: Time Profiler |
| Business Impact | PG-001: User productivity |

**AC-P003:** Create/Update Operation Latency
- [ ] GIVEN valid snippet input WHEN user saves snippet THEN operation completes in < 200ms

| Metric | Value |
|--------|-------|
| Baseline | N/A (new feature) |
| Target | < 200ms save operation |
| Measurement | Performance logging in repository |
| Business Impact | PG-001: < 30s creation flow |

**AC-P004:** Memory Efficiency
- [ ] GIVEN 2,000 snippets loaded WHEN viewing list THEN memory usage < 50MB

| Metric | Value |
|--------|-------|
| Baseline | N/A (new feature) |
| Target | < 50MB for 2,000 items |
| Measurement | Xcode Memory Graph |
| Business Impact | NFR-004: Device compatibility |

### 6.2 Functional Acceptance Criteria

**AC-F001:** Snippet Creation Success
- [ ] GIVEN valid input (title 1-200 chars, content ≤ 5000 chars, ≤ 10 tags) WHEN user saves THEN snippet is persisted with 100% success rate

| Metric | Value |
|--------|-------|
| Baseline | N/A (new feature) |
| Target | 100% success rate for valid input |
| Measurement | Error tracking / crash reporting |
| Business Impact | BG-003: Foundation reliability |

**AC-F002:** Validation Error Display
- [ ] GIVEN invalid input WHEN user attempts to save THEN inline error is displayed within 50ms

| Metric | Value |
|--------|-------|
| Baseline | N/A |
| Target | Error feedback < 50ms |
| Measurement | UI responsiveness testing |
| Business Impact | PG-003: Data integrity |

**AC-F003:** Title Validation
- [ ] GIVEN title > 200 characters WHEN user types THEN character count shows and save is disabled

| Metric | Value |
|--------|-------|
| Baseline | N/A |
| Target | 100% invalid titles rejected |
| Measurement | Unit tests + integration tests |
| Business Impact | FR-006 compliance |

**AC-F004:** Content Length Validation
- [ ] GIVEN content > 5,000 characters WHEN user types THEN character count shows and save is disabled

| Metric | Value |
|--------|-------|
| Baseline | N/A |
| Target | 100% oversized content rejected |
| Measurement | Unit tests + integration tests |
| Business Impact | FR-007 compliance |

**AC-F005:** Tag Limit Enforcement
- [ ] GIVEN 10 tags already added WHEN user attempts to add 11th tag THEN input is disabled with message

| Metric | Value |
|--------|-------|
| Baseline | N/A |
| Target | 100% enforcement |
| Measurement | UI testing |
| Business Impact | FR-008 compliance |

**AC-F006:** Soft Delete Functionality
- [ ] GIVEN active snippet WHEN user deletes THEN deletedAt is set and snippet removed from main list

| Metric | Value |
|--------|-------|
| Baseline | N/A |
| Target | 100% soft delete success |
| Measurement | Repository tests |
| Business Impact | FR-005, FR-014 compliance |

**AC-F007:** Recovery Window
- [ ] GIVEN snippet deleted < 30 days ago WHEN user recovers THEN snippet returns to active list

| Metric | Value |
|--------|-------|
| Baseline | N/A |
| Target | 100% recovery success within window |
| Measurement | Integration tests with time manipulation |
| Business Impact | FR-014: Error recovery |

**AC-F008:** Expired Snippet Purge
- [ ] GIVEN snippet deleted ≥ 30 days ago WHEN purge runs THEN snippet is permanently deleted

| Metric | Value |
|--------|-------|
| Baseline | N/A |
| Target | 100% expired snippets purged |
| Measurement | Automated purge job tests |
| Business Impact | Storage efficiency |

### 6.3 Data Integrity Acceptance Criteria

**AC-D001:** Data Persistence
- [ ] GIVEN user creates snippet WHEN app is force-quit and reopened THEN snippet is retained

| Metric | Value |
|--------|-------|
| Baseline | N/A |
| Target | 0 data loss incidents |
| Measurement | Persistence tests with app lifecycle simulation |
| Business Impact | NFR-006: Reliability |

**AC-D002:** Duplicate Tag Prevention
- [ ] GIVEN user adds same tag twice WHEN saving THEN only one instance is stored

| Metric | Value |
|--------|-------|
| Baseline | N/A |
| Target | 0 duplicate tags |
| Measurement | Domain model tests |
| Business Impact | Data quality |

**AC-D003:** Timestamp Accuracy
- [ ] GIVEN snippet is updated WHEN saved THEN updatedAt reflects current time ± 1 second

| Metric | Value |
|--------|-------|
| Baseline | N/A |
| Target | 100% timestamp accuracy |
| Measurement | Repository tests |
| Business Impact | FR-012: Metadata accuracy |

### 6.4 Accessibility Acceptance Criteria

**AC-A001:** VoiceOver Support
- [ ] GIVEN VoiceOver enabled WHEN navigating Snippets UI THEN all elements are announced correctly

| Metric | Value |
|--------|-------|
| Baseline | N/A |
| Target | 100% elements accessible |
| Measurement | Accessibility audit |
| Business Impact | NFR-009, NFR-012: Accessibility compliance |

**AC-A002:** Dynamic Type Support
- [ ] GIVEN user has Large Text enabled WHEN viewing snippets THEN text scales appropriately

| Metric | Value |
|--------|-------|
| Baseline | N/A |
| Target | Supports all Dynamic Type sizes |
| Measurement | Visual testing at all sizes |
| Business Impact | NFR-009: WCAG 2.1 AA |

### 6.5 Cross-Platform Acceptance Criteria

**AC-X001:** iOS Feature Parity
- [ ] GIVEN iOS app WHEN using all CRUD features THEN 100% functionality works

| Metric | Value |
|--------|-------|
| Baseline | N/A |
| Target | 100% feature parity |
| Measurement | iOS test suite |
| Business Impact | TG-003: Cross-platform consistency |

**AC-X002:** macOS Feature Parity
- [ ] GIVEN macOS app WHEN using all CRUD features THEN 100% functionality works

| Metric | Value |
|--------|-------|
| Baseline | N/A |
| Target | 100% feature parity |
| Measurement | macOS test suite |
| Business Impact | TG-003: Cross-platform consistency |

### 6.6 Acceptance Criteria Summary

| Category | Count | P0 | P1 | P2 |
|----------|-------|-----|-----|-----|
| Performance | 4 | 2 | 2 | 0 |
| Functional | 8 | 6 | 2 | 0 |
| Data Integrity | 3 | 3 | 0 | 0 |
| Accessibility | 2 | 0 | 2 | 0 |
| Cross-Platform | 2 | 2 | 0 | 0 |
| **Total** | **19** | **13** | **6** | **0** |

---

## 7. UI/UX Specifications

### 7.1 Screen Inventory

| Screen | Purpose | Entry Points |
|--------|---------|--------------|
| Snippet List | Browse all snippets | Tab bar "Snippets" |
| Create Snippet | Create new snippet | "+" button on List |
| Snippet Detail | View snippet content | Tap item in List |
| Edit Snippet | Modify existing snippet | "Edit" button on Detail |
| Delete Confirmation | Confirm deletion | "Delete" action on Detail |

### 7.2 Snippet List Screen

**Layout (per mockup analysis):**

```
┌─────────────────────────────────────┐
│ ← Snippets                       [+]│  ← Navigation bar
├─────────────────────────────────────┤
│ 🔍 Search snippets                  │  ← Search bar (disabled MVP)
├─────────────────────────────────────┤
│ [Type ▼]  [Tags ▼]                  │  ← Filter chips (disabled MVP)
├─────────────────────────────────────┤
│ ┌─────────────────────────────────┐ │
│ │ 📄 User Authentication          │ │  ← Snippet row
│ │    Feature                      │ │  ← Type badge
│ │    [Tag1] [Tag2]                │ │  ← Tag chips
│ └─────────────────────────────────┘ │
│ ┌─────────────────────────────────┐ │
│ │ 📄 Fix Login Issue              │ │
│ │    Feature                      │ │
│ │    [Tag3]                       │ │
│ └─────────────────────────────────┘ │
│         ... (infinite scroll)       │
├─────────────────────────────────────┤
│ [Snippets] [PRDs] [Settings]        │  ← Tab bar
└─────────────────────────────────────┘
```

**Components:**

| Component | Behavior |
|-----------|----------|
| Navigation Title | "Snippets" - large title style |
| Add Button (+) | Trailing nav bar item → opens Create Snippet |
| Search Bar | Visible but disabled (placeholder: "Search snippets") |
| Filter Chips | Visible but disabled for MVP |
| Snippet Row | Tappable → navigates to Detail |
| Type Badge | Gray background, displays snippet type |
| Tag Chips | White background, gray border, displays up to 3 tags + "+N" |
| Empty State | Illustration + "No snippets yet" + "Create your first snippet" CTA |

**Interactions:**

| Action | Result |
|--------|--------|
| Tap + | Navigate to Create Snippet (modal) |
| Tap snippet row | Navigate to Snippet Detail (push) |
| Scroll to bottom | Load next batch (infinite scroll) |
| Pull to refresh | Reload snippet list |

### 7.3 Create Snippet Screen

**Layout (per mockup analysis):**

```
┌─────────────────────────────────────┐
│ ✕        New Snippet                │  ← Navigation bar
├─────────────────────────────────────┤
│ Title                               │
│ ┌─────────────────────────────────┐ │
│ │ e.g. Feature Request            │ │  ← Text field
│ └─────────────────────────────────┘ │
│                                     │
│ Content                             │
│ ┌─────────────────────────────────┐ │
│ │ Enter snippet content...        │ │  ← Text editor
│ │                                 │ │
│ │                                 │ │
│ └─────────────────────────────────┘ │
│                                     │
│ Type                                │
│ ┌─────────────────────────────────┐ │
│ │ Select a type                 ▼ │ │  ← Picker
│ └─────────────────────────────────┘ │
│                                     │
│ Tags                                │
│ ┌─────────────────────────────────┐ │
│ │ Add tags separated by comma     │ │  ← Text field
│ └─────────────────────────────────┘ │
│ [design ✕] [feature ✕]              │  ← Tag chips
│                                     │
│ ┌─────────────────────────────────┐ │
│ │        Save Snippet             │ │  ← Primary button
│ └─────────────────────────────────┘ │
└─────────────────────────────────────┘
```

**Components:**

| Component | Validation | Behavior |
|-----------|------------|----------|
| Title Field | Required, 1-200 chars | Shows character count at 150+ |
| Content Editor | Optional, max 5,000 chars | Shows character count at 4,500+ |
| Type Picker | Required | Defaults to "Feature" |
| Tags Field | Max 10 tags | Comma or Enter creates chip |
| Tag Chips | Removable | Tap X to remove |
| Save Button | Disabled if invalid | Primary style, full width |
| Close Button (✕) | - | Dismisses modal, discards changes |

**Validation States:**

| State | Visual |
|-------|--------|
| Valid | Green checkmark or no indicator |
| Invalid | Red border, error message below field |
| Warning | Orange border (approaching limit) |

### 7.4 Snippet Detail Screen

**Layout (per mockup analysis):**

```
┌─────────────────────────────────────┐
│ ←      Snippet Details              │  ← Navigation bar
├─────────────────────────────────────┤
│                                     │
│ Feature: User Onboarding            │  ← Title (large)
│                                     │
│ This snippet outlines the user      │  ← Content
│ onboarding process for new users,   │
│ including account creation, initial │
│ setup, and tutorial completion.     │
│                                     │
│ TYPE                                │
│ Process                             │
│                                     │
│ TAGS                                │
│ [Onboarding] [User Experience]      │
│ [Tutorial]                          │
│                                     │
│ Version History                     │  ← (Future epic)
│ ┌─────────────────────────────────┐ │
│ │ Version 2.0           [View]    │ │
│ │ Updated by Alex Chen            │ │
│ │ Version 1.0           [View]    │ │
│ │ Created by Alex Chen            │ │
│ └─────────────────────────────────┘ │
│                                     │
├─────────────────────────────────────┤
│ [    Edit    ] [  Insert Snippet  ] │  ← Action buttons
└─────────────────────────────────────┘
```

**Components:**

| Component | Behavior |
|-----------|----------|
| Back Button (←) | Returns to list, preserves scroll position |
| Title | Large title style, prefixed with type |
| Content | Scrollable text, full snippet content |
| Type Section | Label + value |
| Tags Section | Label + tag chip row |
| Version History | Disabled for MVP, shows placeholder |
| Edit Button | Secondary style, navigates to Edit |
| Insert Snippet | Primary style, disabled for MVP |

### 7.5 Edit Snippet Screen

**Layout:** Same as Create Snippet with pre-populated values.

**Additional Components:**

| Component | Behavior |
|-----------|----------|
| Delete Button | Destructive style, bottom of form |
| Cancel Link | Top-left, discards changes |
| Save Button | Updates existing snippet |

### 7.6 Delete Confirmation

**Layout:**

```
┌─────────────────────────────────────┐
│                                     │
│     Delete "User Authentication"?   │
│                                     │
│   This snippet will be moved to     │
│   trash. You can recover it within  │
│   30 days.                          │
│                                     │
│   [Cancel]        [Delete]          │
│                                     │
└─────────────────────────────────────┘
```

### 7.7 Empty State

**Layout:**

```
┌─────────────────────────────────────┐
│                                     │
│          [illustration]             │
│                                     │
│        No snippets yet              │
│                                     │
│   Create your first snippet to      │
│   start building your library.      │
│                                     │
│   [ Create Snippet ]                │
│                                     │
└─────────────────────────────────────┘
```

### 7.8 Design Tokens

| Token | iOS Value | macOS Value |
|-------|-----------|-------------|
| Primary Color | System Blue | System Blue |
| Background | System Background | Window Background |
| Card Background | Secondary System Background | Secondary Background |
| Title Font | SF Pro Display Bold 22pt | SF Pro Display Bold 22pt |
| Body Font | SF Pro Text Regular 17pt | SF Pro Text Regular 14pt |
| Caption Font | SF Pro Text Regular 13pt | SF Pro Text Regular 12pt |
| Corner Radius (Cards) | 12pt | 8pt |
| Corner Radius (Chips) | 8pt | 6pt |
| Spacing (Standard) | 16pt | 12pt |

### 7.9 Interaction Patterns

| Pattern | Description |
|---------|-------------|
| Modal Presentation | Create/Edit screens presented as sheet |
| Navigation Push | Detail view pushed onto navigation stack |
| Swipe to Delete | Swipe left on list item reveals delete (future) |
| Haptic Feedback | Light impact on successful save |
| Keyboard Avoidance | Form scrolls to keep focused field visible |

---

## 8. Security & Privacy

### 8.1 Data Privacy

| Aspect | Implementation | Rationale |
|--------|----------------|-----------|
| **Data Location** | Local device only (SwiftData) | Privacy-first MVP, no cloud exposure |
| **User Isolation** | userId field for future multi-user | Preparation for workspace features |
| **No Analytics** | No snippet content sent externally | User content is sensitive |
| **No Telemetry** | Only crash reports (opt-in) | Minimal data collection |

### 8.2 Data Protection

| Protection | Implementation |
|------------|----------------|
| **At Rest** | iOS/macOS Data Protection (hardware encryption) |
| **File Protection** | NSFileProtectionComplete (encrypted until first unlock) |
| **Keychain** | Not required (no credentials stored) |
| **Backup** | Included in device backup (user's choice) |

### 8.3 Input Validation (Security)

| Validation | Purpose |
|------------|---------|
| Title length limit (200) | Prevent DoS via oversized strings |
| Content length limit (5,000) | Prevent memory exhaustion |
| Tag count limit (10) | Prevent array manipulation attacks |
| String sanitization | Trim whitespace, normalize unicode |
| No HTML/script execution | Content displayed as plain text |

### 8.4 Future Security Considerations

| Feature | Security Requirement |
|---------|---------------------|
| iCloud Sync | End-to-end encryption via CloudKit |
| Sharing | Permission model, revocable access |
| Export | Sanitize content before export |
| Import | Validate and sanitize imported data |

### 8.5 Privacy Compliance

| Regulation | Status |
|------------|--------|
| **GDPR** | N/A for local-only storage |
| **CCPA** | N/A for local-only storage |
| **App Store** | Privacy Nutrition Label: "Data Not Collected" |

### 8.6 Threat Model (MVP Scope)

| Threat | Mitigation | Risk Level |
|--------|------------|------------|
| Device theft | iOS/macOS encryption + passcode | Low (OS-level) |
| App vulnerability | Input validation, no eval/exec | Low |
| Data loss | SwiftData auto-save, device backup | Low |
| Malicious input | Length limits, sanitization | Low |

---

## 9. Implementation Roadmap

### 9.1 Sprint Plan

| Sprint | Focus | Stories | SP | Deliverable |
|--------|-------|---------|-----|-------------|
| **Sprint 1** | Foundation | US-001, US-002 | 5 | Domain models, repository, list view |
| **Sprint 2** | Core CRUD | US-003, US-004 | 4 | Detail view, edit functionality |
| **Sprint 3** | Polish | US-005, US-006 | 4 | Delete, tags, empty states |

**Total: 3 sprints (~6 weeks for 1 developer)**

### 9.2 Sprint 1: Foundation (5 SP)

**Week 1-2**

| Task | Story | Estimate | Owner |
|------|-------|----------|-------|
| Create Snippet domain model with validation | US-001 | 0.5 day | Backend |
| Create SnippetError enum | US-001 | 0.25 day | Backend |
| Create SnippetInput DTO | US-001 | 0.25 day | Backend |
| Define SnippetRepository protocol | US-001 | 0.25 day | Backend |
| Implement SwiftData SnippetModel | US-001 | 0.5 day | Backend |
| Implement SwiftDataSnippetRepository | US-001 | 1 day | Backend |
| Create SnippetViewModel | US-001, US-002 | 0.5 day | Backend |
| Create SnippetListView | US-002 | 1 day | Frontend |
| Create SnippetRowView component | US-002 | 0.5 day | Frontend |
| Create CreateSnippetView | US-001 | 1 day | Frontend |
| Implement infinite scroll | US-002 | 0.5 day | Frontend |
| Write unit tests for domain models | US-001 | 0.5 day | QA |
| Write repository integration tests | US-001, US-002 | 0.5 day | QA |

**Sprint 1 Definition of Done:**
- [ ] User can create a snippet with title, content, type, tags
- [ ] User can view list of all snippets
- [ ] Snippets persist across app restarts
- [ ] Unit tests pass for domain models
- [ ] Integration tests pass for repository

### 9.3 Sprint 2: Core CRUD (4 SP)

**Week 3-4**

| Task | Story | Estimate | Owner |
|------|-------|----------|-------|
| Create SnippetDetailView | US-003 | 1 day | Frontend |
| Create EditSnippetView | US-004 | 0.5 day | Frontend |
| Implement update in ViewModel | US-004 | 0.5 day | Backend |
| Implement navigation flow | US-003, US-004 | 0.5 day | Frontend |
| Add keyboard avoidance | US-001, US-004 | 0.25 day | Frontend |
| Implement scroll position preservation | US-003 | 0.25 day | Frontend |
| Write UI tests for detail/edit flow | US-003, US-004 | 0.5 day | QA |
| Cross-platform testing (iOS + macOS) | All | 1 day | QA |

**Sprint 2 Definition of Done:**
- [ ] User can view snippet details
- [ ] User can edit existing snippets
- [ ] Navigation preserves scroll position
- [ ] Works on both iOS and macOS
- [ ] UI tests pass

### 9.4 Sprint 3: Polish (4 SP)

**Week 5-6**

| Task | Story | Estimate | Owner |
|------|-------|----------|-------|
| Implement soft delete | US-005 | 0.5 day | Backend |
| Create DeleteConfirmationView | US-005 | 0.25 day | Frontend |
| Implement tag suggestions UI | US-006 | 0.5 day | Frontend |
| Create tag chip component | US-006 | 0.5 day | Frontend |
| Implement tag validation (max 10) | US-006 | 0.25 day | Backend |
| Create EmptyStateView | US-002 | 0.25 day | Frontend |
| Add VoiceOver support | All | 0.5 day | Frontend |
| Add Dynamic Type support | All | 0.5 day | Frontend |
| Performance optimization | All | 0.5 day | Backend |
| Write accessibility tests | All | 0.5 day | QA |
| Final integration testing | All | 1 day | QA |
| Bug fixes and polish | All | 1 day | All |

**Sprint 3 Definition of Done:**
- [ ] User can delete snippets (soft delete)
- [ ] User can manage tags with suggestions
- [ ] Empty state displayed when no snippets
- [ ] VoiceOver fully supported
- [ ] Dynamic Type fully supported
- [ ] Performance targets met (< 300ms list load)
- [ ] All acceptance criteria validated

### 9.5 Dependencies

```
┌─────────────┐
│   US-001    │  Create Snippet (Foundation)
│  (Sprint 1) │
└──────┬──────┘
       │
       ▼
┌─────────────┐     ┌─────────────┐
│   US-002    │────▶│   US-006    │  Tag Management
│ List View   │     │  (Sprint 3) │
└──────┬──────┘     └─────────────┘
       │
       ▼
┌─────────────┐
│   US-003    │  Detail View
│  (Sprint 2) │
└──────┬──────┘
       │
       ├─────────────────┐
       ▼                 ▼
┌─────────────┐   ┌─────────────┐
│   US-004    │   │   US-005    │
│ Edit View   │   │   Delete    │
│  (Sprint 2) │   │  (Sprint 3) │
└─────────────┘   └─────────────┘
```

### 9.6 Risk Mitigation

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| SwiftData performance issues | Medium | High | Early performance testing in Sprint 1 |
| Cross-platform UI differences | Medium | Medium | Platform-specific testing each sprint |
| Scope creep (search, sync) | High | Medium | Strict scope boundary, defer to Epic 2+ |
| Late-discovered accessibility issues | Low | Medium | Include a11y testing from Sprint 1 |

### 9.7 Release Criteria

| Category | Criteria | Status |
|----------|----------|--------|
| **Functionality** | All P0 stories complete | ⏳ |
| **Quality** | 0 P0/P1 bugs | ⏳ |
| **Performance** | All NFRs met | ⏳ |
| **Accessibility** | VoiceOver + Dynamic Type | ⏳ |
| **Testing** | 80%+ code coverage | ⏳ |
| **Documentation** | README updated | ⏳ |

---

## 10. Open Questions

### 10.1 Product Questions

| ID | Question | Owner | Due Date | Impact |
|----|----------|-------|----------|--------|
| OQ-001 | Should we add Bug, Improvement, Process types in MVP or defer? | Product | Sprint 1 | Scope |
| OQ-002 | What predefined tags beyond "User Experience" and "API" are needed? | Product | Sprint 1 | UX |
| OQ-003 | Should empty content be allowed, or require minimum 1 character? | Product | Sprint 1 | Validation |
| OQ-004 | Should we show created/updated timestamps in list view or only detail? | Product | Sprint 1 | UX |

### 10.2 Technical Questions

| ID | Question | Owner | Due Date | Impact |
|----|----------|-------|----------|--------|
| TQ-001 | Should we implement auto-save drafts in MVP or defer? | Engineering | Sprint 1 | Scope (FR-016) |
| TQ-002 | What batch size for infinite scroll (20, 50, 100)? | Engineering | Sprint 1 | Performance |
| TQ-003 | Should purgeExpired() run on app launch, daily, or manually? | Engineering | Sprint 2 | Maintenance |
| TQ-004 | Do we need a migration strategy for future schema changes? | Engineering | Sprint 1 | Architecture |

### 10.3 Design Questions

| ID | Question | Owner | Due Date | Impact |
|----|----------|-------|----------|--------|
| DQ-001 | Should disabled features (search, filters) be visible or hidden? | Design | Sprint 1 | UX |
| DQ-002 | What illustration for empty state? | Design | Sprint 3 | Polish |
| DQ-003 | Should type badge use color coding (Feature=blue, Bug=red)? | Design | Sprint 1 | UX |

### 10.4 Assumptions

| ID | Assumption | Impact if Wrong | Validator | Status |
|----|------------|-----------------|-----------|--------|
| A-001 | SwiftData performs adequately for 2,000 items | +2 weeks for Core Data migration | Engineering | ⏳ Validate Sprint 1 |
| A-002 | Users will have < 2,000 snippets in typical use | Pagination/optimization needed | Product | ✅ Validated via clarification |
| A-003 | Local-only storage acceptable for MVP | User dissatisfaction, feature request | Product | ✅ Validated via clarification |
| A-004 | Feature type sufficient for MVP | User requests for more types | Product | ⏳ Monitor feedback |
| A-005 | 5,000 character content limit sufficient | User requests for longer content | Product | ✅ Validated via clarification |

---

## 11. Appendix

### 11.1 Glossary

| Term | Definition |
|------|------------|
| **Snippet** | A reusable text block stored in the library |
| **Soft Delete** | Mark item as deleted without permanent removal |
| **Tag** | A label used to categorize snippets |
| **Type** | Category classification (Feature, Bug, etc.) |
| **SwiftData** | Apple's modern persistence framework |
| **Infinite Scroll** | Loading more items as user scrolls |

### 11.2 Related Documents

| Document | Purpose |
|----------|---------|
| CLAUDE.md | Engineering standards and architecture guidelines |
| Epic 2: Search & Filtering PRD | Future search functionality |
| Epic 3: Version History PRD | Future versioning functionality |
| Epic 4: PRD Integration PRD | Future integration functionality |

### 11.3 Mockup Reference

**Source:** `/Users/cdeust/.../mockup.png`

The mockup shows three screens:
1. **Snippet List** - Search bar, filter chips, snippet rows with type badges and tags
2. **Create Snippet** - Form with title, content, type picker, tag input
3. **Snippet Details** - Full content display, type, tags, version history (future), action buttons

### 11.4 Codebase Integration Points

Based on analysis of `https://github.com/cdeust/ai-prd-builder`:

| Integration | Location | Notes |
|-------------|----------|-------|
| PRDGenerator | `swift/Sources/PRDGenerator/` | Future snippet insertion |
| CommonModels | `swift/Sources/CommonModels/` | Shared protocols |
| DomainCore | `swift/Sources/DomainCore/` | Domain entities |
| Orchestration | `swift/Sources/Orchestration/` | App coordination |

### 11.5 Future Epic Summaries

**Epic 2: Search & Filtering (~13 SP)**
- Keyword search across title and content
- Filter by type
- Filter by tags
- Sort options (date, title)

**Epic 3: Version History (~21 SP)**
- Track changes on each save
- View historical versions
- Diff comparison
- Rollback to previous version

**Epic 4: PRD Integration (~13 SP)**
- Insert snippet into PRD
- Template variables ({{variable}})
- Context-aware suggestions

### 11.6 Revision History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2026-02-05 | AI PRD Generator | Initial draft |

---

## Document Information

**Generated by:** AI PRD Generator v7.0 (Enterprise Edition)
**PRD Type:** Feature (Implementation-ready)
**Verification:** Multi-judge consensus
**Total Story Points:** 13 SP
**Estimated Duration:** 3 sprints (~6 weeks, 1 developer)

