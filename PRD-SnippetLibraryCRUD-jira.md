# JIRA Tickets: Snippet Library - Core CRUD

**Generated:** 2026-02-05
**Total Story Points:** 13 SP
**Estimated Duration:** 3 sprints (~6 weeks, 1 developer)

---

## Epic: SNIP-CRUD - Core CRUD Operations [13 SP]

**Description:** Enable users to create, read, update, and delete snippets with title, content, type, and tags. Foundation for the Snippet Library feature.

**Labels:** `snippet-library`, `mvp`, `foundation`

---

### STORY-001: Create New Snippet

**Type:** Story | **Priority:** P0 | **SP:** 3

**Description:**
As a Product Manager
I want to create a new snippet with title, content, type, and tags
So that I can save reusable content for future PRDs

**Acceptance Criteria:**

**AC-001:** Form Access
- [ ] GIVEN I am on the Snippets screen WHEN I tap the "+" button THEN the New Snippet form opens as a modal
| Baseline | N/A | Target | 100% | Measurement | UI test | Impact | FR-001 |

**AC-002:** Valid Snippet Creation
- [ ] GIVEN I enter a valid title (1-200 chars) and tap Save THEN the snippet is created and appears in the list
| Baseline | N/A | Target | 100% success | Measurement | Integration test | Impact | FR-001, BG-003 |

**AC-003:** Title Validation (Too Long)
- [ ] GIVEN I enter a title > 200 characters WHEN I attempt to save THEN an inline validation error is shown
| Baseline | N/A | Target | 100% rejection | Measurement | Unit test | Impact | FR-006 |

**AC-004:** Content Validation (Too Long)
- [ ] GIVEN I enter content > 5,000 characters WHEN I attempt to save THEN an inline validation error is shown
| Baseline | N/A | Target | 100% rejection | Measurement | Unit test | Impact | FR-007 |

**AC-005:** Tag Limit Enforcement
- [ ] GIVEN I add 10 tags WHEN I attempt to add the 11th tag THEN the system prevents addition with feedback
| Baseline | N/A | Target | 100% enforcement | Measurement | UI test | Impact | FR-008 |

**AC-006:** List Update
- [ ] GIVEN I save a valid snippet WHEN viewing the list THEN the new snippet appears at the top
| Baseline | N/A | Target | Immediate update | Measurement | UI test | Impact | PG-001 |

**Tasks:**
- [ ] Create Snippet domain model with validation
- [ ] Create SnippetError enum with all error cases
- [ ] Create SnippetInput DTO
- [ ] Define SnippetRepository protocol
- [ ] Implement SwiftData SnippetModel
- [ ] Implement SwiftDataSnippetRepository.save()
- [ ] Create SnippetViewModel with createSnippet()
- [ ] Create CreateSnippetView UI
- [ ] Implement form validation with inline errors
- [ ] Write unit tests for Snippet domain model
- [ ] Write integration tests for repository

**Dependencies:** None
**Labels:** `backend`, `frontend`, `p0`, `sprint-1`

---

### STORY-002: View Snippet List

**Type:** Story | **Priority:** P0 | **SP:** 2

**Description:**
As a Product Manager
I want to see a list of all my snippets
So that I can browse and find the content I need

**Acceptance Criteria:**

**AC-007:** List Display
- [ ] GIVEN I have snippets WHEN I open the Snippets tab THEN I see a scrollable list of all snippets
| Baseline | N/A | Target | 100% snippets shown | Measurement | UI test | Impact | FR-002 |

**AC-008:** Row Content
- [ ] GIVEN a snippet in the list THEN I see its title, type badge, and tag chips (max 3 + "+N")
| Baseline | N/A | Target | All metadata visible | Measurement | UI test | Impact | FR-020 |

**AC-009:** Empty State
- [ ] GIVEN I have 0 snippets WHEN I open the Snippets tab THEN I see an empty state with guidance
| Baseline | N/A | Target | Empty state shown | Measurement | UI test | Impact | FR-019 |

**AC-010:** Performance
- [ ] GIVEN I have 2,000 snippets WHEN I open the list THEN it loads in < 300ms
| Baseline | N/A | Target | < 300ms | Measurement | Instruments | Impact | NFR-001, TG-001 |

**AC-011:** Infinite Scroll
- [ ] GIVEN I scroll to the bottom WHEN more snippets exist THEN additional snippets load automatically
| Baseline | N/A | Target | Seamless loading | Measurement | UI test | Impact | FR-013 |

**Tasks:**
- [ ] Implement SwiftDataSnippetRepository.fetchAll()
- [ ] Add loadSnippets() to SnippetViewModel
- [ ] Create SnippetListView with LazyVStack
- [ ] Create SnippetRowView component
- [ ] Create TypeBadgeView component
- [ ] Create TagChipView component
- [ ] Implement infinite scroll with batch loading
- [ ] Create EmptyStateView
- [ ] Write UI tests for list view
- [ ] Performance test with 2,000 items

**Dependencies:** STORY-001
**Labels:** `frontend`, `performance`, `p0`, `sprint-1`

---

### STORY-003: View Snippet Details

**Type:** Story | **Priority:** P0 | **SP:** 2

**Description:**
As a Product Manager
I want to view the full details of a snippet
So that I can read the complete content and metadata

**Acceptance Criteria:**

**AC-012:** Detail Display
- [ ] GIVEN I tap a snippet in the list WHEN the detail view opens THEN I see title, content, type, tags, and dates
| Baseline | N/A | Target | All fields shown | Measurement | UI test | Impact | FR-003 |

**AC-013:** Action Buttons
- [ ] GIVEN I am on the detail view THEN I see "Edit" and "Insert Snippet" buttons (Insert disabled for MVP)
| Baseline | N/A | Target | Buttons present | Measurement | UI test | Impact | FR-003 |

**AC-014:** Scrollable Content
- [ ] GIVEN the snippet has long content THEN it is scrollable within the detail view
| Baseline | N/A | Target | Content scrollable | Measurement | UI test | Impact | UX |

**AC-015:** Navigation
- [ ] GIVEN I tap the back button WHEN on detail view THEN I return to the list at the same scroll position
| Baseline | N/A | Target | Position preserved | Measurement | UI test | Impact | UX |

**Tasks:**
- [ ] Implement SwiftDataSnippetRepository.fetch(id:)
- [ ] Create SnippetDetailView
- [ ] Display all snippet fields with proper formatting
- [ ] Add Edit button (navigates to edit)
- [ ] Add Insert Snippet button (disabled state)
- [ ] Implement scroll position preservation in list
- [ ] Write UI tests for detail view

**Dependencies:** STORY-002
**Labels:** `frontend`, `p0`, `sprint-2`

---

### STORY-004: Edit Existing Snippet

**Type:** Story | **Priority:** P0 | **SP:** 2

**Description:**
As a Product Manager
I want to edit an existing snippet
So that I can update or improve my saved content

**Acceptance Criteria:**

**AC-016:** Pre-populated Form
- [ ] GIVEN I am on the Snippet Detail view WHEN I tap "Edit" THEN the edit form opens pre-populated with current values
| Baseline | N/A | Target | All fields populated | Measurement | UI test | Impact | FR-004 |

**AC-017:** Save Changes
- [ ] GIVEN I modify any field and tap Save THEN the changes are persisted
| Baseline | N/A | Target | 100% save success | Measurement | Integration test | Impact | FR-004 |

**AC-018:** Timestamp Update
- [ ] GIVEN I modify a snippet WHEN saved THEN the updatedAt timestamp is updated
| Baseline | N/A | Target | Timestamp accurate | Measurement | Unit test | Impact | FR-012 |

**AC-019:** Cancel Edit
- [ ] GIVEN I am editing WHEN I tap Cancel THEN changes are discarded and I return to detail view
| Baseline | N/A | Target | No changes persisted | Measurement | UI test | Impact | UX |

**AC-020:** Empty Tags
- [ ] GIVEN I remove all tags WHEN I save THEN the snippet is saved with empty tags array
| Baseline | N/A | Target | Empty array valid | Measurement | Unit test | Impact | FR-004 |

**Tasks:**
- [ ] Implement SwiftDataSnippetRepository.update()
- [ ] Add updateSnippet() to SnippetViewModel
- [ ] Create EditSnippetView (reuse form components)
- [ ] Pre-populate form with existing snippet data
- [ ] Implement cancel functionality
- [ ] Update updatedAt on save
- [ ] Write unit tests for update logic
- [ ] Write UI tests for edit flow

**Dependencies:** STORY-003
**Labels:** `frontend`, `backend`, `p0`, `sprint-2`

---

### STORY-005: Delete Snippet

**Type:** Story | **Priority:** P0 | **SP:** 2

**Description:**
As a Product Manager
I want to delete a snippet I no longer need
So that I can keep my library organized

**Acceptance Criteria:**

**AC-021:** Confirmation Dialog
- [ ] GIVEN I am on Snippet Detail WHEN I tap Delete THEN a confirmation dialog appears
| Baseline | N/A | Target | Dialog shown | Measurement | UI test | Impact | FR-017 |

**AC-022:** Soft Delete
- [ ] GIVEN I confirm deletion WHEN confirmed THEN the snippet is soft-deleted (deletedAt set)
| Baseline | N/A | Target | deletedAt populated | Measurement | Unit test | Impact | FR-005 |

**AC-023:** List Removal
- [ ] GIVEN I soft-delete a snippet THEN it no longer appears in the main list
| Baseline | N/A | Target | Removed from list | Measurement | UI test | Impact | FR-005 |

**AC-024:** Cancel Delete
- [ ] GIVEN I cancel deletion WHEN in confirmation dialog THEN no changes occur
| Baseline | N/A | Target | No changes | Measurement | UI test | Impact | UX |

**AC-025:** Recovery
- [ ] GIVEN a snippet was deleted < 30 days ago WHEN accessing deleted items THEN I can recover it
| Baseline | N/A | Target | Recovery works | Measurement | Integration test | Impact | FR-014 |

**Tasks:**
- [ ] Implement SwiftDataSnippetRepository.softDelete()
- [ ] Implement SwiftDataSnippetRepository.recover()
- [ ] Implement SwiftDataSnippetRepository.fetchDeleted()
- [ ] Add deleteSnippet() to SnippetViewModel
- [ ] Add recoverSnippet() to SnippetViewModel
- [ ] Create DeleteConfirmationView (alert)
- [ ] Remove deleted snippets from list
- [ ] Write unit tests for soft delete
- [ ] Write integration tests for recovery

**Dependencies:** STORY-003
**Labels:** `backend`, `frontend`, `p0`, `sprint-3`

---

### STORY-006: Tag Management

**Type:** Story | **Priority:** P1 | **SP:** 2

**Description:**
As a Product Manager
I want to add and remove tags on my snippets
So that I can organize content for easier discovery

**Acceptance Criteria:**

**AC-026:** Predefined Suggestions
- [ ] GIVEN I am creating/editing a snippet WHEN I type in the tags field THEN I see predefined suggestions (User Experience, API)
| Baseline | N/A | Target | Suggestions shown | Measurement | UI test | Impact | FR-010 |

**AC-027:** Custom Tag Creation
- [ ] GIVEN I type a custom tag WHEN I press comma or enter THEN the tag is added as a chip
| Baseline | N/A | Target | Chip created | Measurement | UI test | Impact | FR-011 |

**AC-028:** Tag Removal
- [ ] GIVEN a tag chip is displayed WHEN I tap the X on the chip THEN the tag is removed
| Baseline | N/A | Target | Tag removed | Measurement | UI test | Impact | FR-018 |

**AC-029:** Tag Limit
- [ ] GIVEN I have 10 tags WHEN I try to add another THEN the input is disabled with "Max 10 tags" message
| Baseline | N/A | Target | Input disabled | Measurement | UI test | Impact | FR-008 |

**AC-030:** Duplicate Prevention
- [ ] GIVEN I add a duplicate tag WHEN saving THEN duplicates are automatically removed
| Baseline | N/A | Target | 0 duplicates | Measurement | Unit test | Impact | Data quality |

**Tasks:**
- [ ] Create PredefinedTag enum with suggestions
- [ ] Implement tag chip component with X button
- [ ] Implement tag input with comma/enter detection
- [ ] Show predefined tag suggestions
- [ ] Enforce max 10 tags limit
- [ ] Remove duplicates in domain model
- [ ] Write unit tests for tag validation
- [ ] Write UI tests for tag interaction

**Dependencies:** STORY-001
**Labels:** `frontend`, `p1`, `sprint-3`

---

## Summary

| Epic | Stories | Story Points |
|------|---------|--------------|
| SNIP-CRUD: Core CRUD Operations | 6 | 13 SP |
| **Total** | **6** | **13 SP** |

---

## Sprint Assignment

| Sprint | Stories | SP |
|--------|---------|-----|
| Sprint 1 | STORY-001, STORY-002 | 5 |
| Sprint 2 | STORY-003, STORY-004 | 4 |
| Sprint 3 | STORY-005, STORY-006 | 4 |

---

## CSV Export (JIRA Import)

```csv
Summary,Issue Type,Priority,Story Points,Epic Link,Labels,Description
"Create New Snippet",Story,Highest,3,SNIP-CRUD,"backend,frontend,p0,sprint-1","As a Product Manager, I want to create a new snippet with title, content, type, and tags so that I can save reusable content for future PRDs"
"View Snippet List",Story,Highest,2,SNIP-CRUD,"frontend,performance,p0,sprint-1","As a Product Manager, I want to see a list of all my snippets so that I can browse and find the content I need"
"View Snippet Details",Story,Highest,2,SNIP-CRUD,"frontend,p0,sprint-2","As a Product Manager, I want to view the full details of a snippet so that I can read the complete content and metadata"
"Edit Existing Snippet",Story,Highest,2,SNIP-CRUD,"frontend,backend,p0,sprint-2","As a Product Manager, I want to edit an existing snippet so that I can update or improve my saved content"
"Delete Snippet",Story,Highest,2,SNIP-CRUD,"backend,frontend,p0,sprint-3","As a Product Manager, I want to delete a snippet I no longer need so that I can keep my library organized"
"Tag Management",Story,High,2,SNIP-CRUD,"frontend,p1,sprint-3","As a Product Manager, I want to add and remove tags on my snippets so that I can organize content for easier discovery"
```

---

**Generated by:** AI PRD Generator v7.0 (Enterprise Edition)
