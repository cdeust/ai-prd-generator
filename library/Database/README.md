# Database Schema Documentation

## Overview

This directory contains the PostgreSQL/Supabase database schema for the AI PRD system. The schema supports:

- **RAG System**: Vector search (pgvector) + Full-text search (tsvector/GIN)
- **Codebase Indexing**: Store parsed code chunks with embeddings
- **PRD Generation**: Store PRD documents with sections and metadata
- **Contextual Retrieval**: 8-stage pipeline with hybrid search and reranking

## Architecture Principles

### Clean Architecture Compliance
- **Domain defines ports** - Application layer depends on abstractions
- **Infrastructure implements** - Supabase adapters implement domain ports
- **Schema is infrastructure** - SQL migrations are deployment artifacts, not domain models

### Migration Strategy
- **Sequential migrations** - Each file is a transaction, applied in order
- **Idempotent operations** - Safe to re-run (CREATE IF NOT EXISTS, DROP IF EXISTS)
- **Rollback support** - Each migration includes rollback instructions

## Schema Design

### Extensions
```sql
uuid-ossp   -- UUID generation (gen_random_uuid)
vector      -- pgvector for semantic search (HNSW index)
pg_trgm     -- Trigram similarity for fuzzy matching
```

### Core Tables

**Codebase Domain:**
- `users` - System users with authentication
- `codebases` - Repository metadata
- `codebase_projects` - Indexing projects with status tracking
- `code_files` - Parsed files with language detection
- `code_chunks` - Parsed code segments (functions, classes, etc.)
- `code_embeddings` - Vector embeddings for semantic search

**PRD Domain:**
- `prd_requests` - PRD generation requests with metadata
- `prd_documents` - Generated PRDs with thinking metadata
- `prd_sections` - Document sections (features, user stories, etc.)
- `prd_templates` - Reusable PRD structures with section configuration
- `mockups` - Design mockups linked to PRDs
- `sessions` - Conversational PRD generation sessions with message history

**Repository Integration Domain:**
- `repository_connections` - OAuth connections to GitHub, GitLab, Bitbucket
- `repository_connection_status` - ENUM (connected, disconnected, expired, failed)

### Performance Optimizations

**Vector Search (pgvector):**
- HNSW index on `code_embeddings.embedding`
- Sub-100ms similarity search on millions of vectors
- Cosine similarity via `match_code_chunks()` RPC

**Full-Text Search (PostgreSQL):**
- GIN index on `code_chunks.content_tsv` (tsvector)
- BM25 ranking via `ts_rank_cd()`
- <10ms keyword search on millions of chunks

**Hybrid Search (RRF):**
- Reciprocal Rank Fusion combines vector + keyword results
- Balances semantic understanding with exact matching
- Optimized for RAG retrieval

### RPC Functions

**Contextual Retrieval:**
- `find_chunks_before_line()` - Get context before a chunk
- `find_chunks_after_line()` - Get context after a chunk
- `find_related_chunks()` - Graph-based relationship tracking

**Search Operations:**
- `match_code_chunks()` - Vector similarity search (cosine)
- `search_chunks_bm25()` - Full-text search with BM25 ranking
- `hybrid_search_chunks()` - Combined vector + keyword with RRF

**Aggregations:**
- `get_codebase_stats()` - File counts, language distribution
- `get_indexing_progress()` - Real-time indexing metrics

## Migration Files

### Naming Convention
```
XXX_descriptive_name.sql
```

Where:
- `XXX` = Sequential number (001, 002, etc.)
- `descriptive_name` = What the migration does (snake_case)

### Structure
Each migration file contains:
1. **Header** - Description, purpose, dependencies
2. **Transaction BEGIN** - Ensures atomicity
3. **Operations** - DDL statements (CREATE, ALTER, etc.)
4. **Comments** - `COMMENT ON` for documentation
5. **Indexes** - Performance optimizations
6. **RLS Policies** - Row-Level Security rules
7. **Transaction COMMIT** - Apply changes
8. **Rollback** - How to undo (as SQL comment)

### Current Migrations

**000_complete_schema.sql** - Complete schema (initial deployment)
- All tables, indexes, and RPC functions in one file
- Used for fresh database setups

**001_initial_schema.sql** - Foundation
- Core tables (users, codebases, code_chunks, embeddings)
- PRD tables (requests, documents, sections, sessions)
- ENUMs (properly namespaced)
- Indexes (HNSW, GIN, B-tree)
- RLS policies

**002_rpc_functions.sql** - Queries
- Contextual retrieval functions
- Full-text search with BM25
- Vector similarity search
- Hybrid search with RRF

**003_prd_templates.sql** - PRD Template System
- `prd_templates` table with JSONB section configuration
- 4 default templates (Comprehensive, Mobile App, API Service, Feature Request)
- Validation functions for section structure
- Row-Level Security policies
- No arbitrary size limits (uses TEXT)

**004_repository_connections.sql** - Repository Integration
- `repository_connections` table for OAuth connections
- Support for GitHub, GitLab, Bitbucket
- Token refresh and expiration tracking
- Connection status management

**005_add_codebase_indexing_columns.sql** - Codebase Enhancements
- Add indexing metadata columns to codebases table
- Improve indexing status tracking

**006_disable_rls_for_backend.sql** - Backend Access
- Disable RLS for backend service role
- Enable backend to manage all records

**007_update_prd_section_types.sql** - PRD Section Types
- Update ENUM for PRD section types
- Add new section categories

**008_codebases_unique_repo_url.sql** - Codebase Constraints
- Add unique constraint on repository URL
- Prevent duplicate codebase entries

**fix_repository_connections.sql** - Bug Fixes
- Fix repository_connections schema issues
- Resolve data integrity problems

## Integration with Swift Library

### Port Abstractions (Domain Layer)
```swift
CodebaseRepositoryPort
    ├─ findChunksByProject(_:limit:offset:)
    ├─ saveChunks(_:projectId:)
    └─ searchSimilarChunks(embedding:codebaseId:limit:)

FullTextSearchPort
    ├─ searchChunks(in:query:limit:minScore:)
    └─ searchFiles(in:query:limit:)

PRDTemplateRepositoryPort
    ├─ save(_:)
    ├─ findById(_:)
    ├─ findAll()
    ├─ findDefaults()
    ├─ delete(_:)
    └─ existsByName(_:)
```

### Infrastructure Implementations
```swift
SupabaseCodebaseRepository: CodebaseRepositoryPort
    - Uses Supabase client to call RPC functions
    - Maps DTOs to Domain entities
    - Handles connection pooling and retries

PostgreSQLFullTextSearch: FullTextSearchPort
    - Calls search_chunks_bm25() RPC
    - Returns BM25-ranked results
    - No in-memory processing (scalable)

SupabasePRDTemplateRepository: PRDTemplateRepositoryPort
    - Actor-isolated for Swift 6 concurrency
    - Maps JSONB sections to TemplateSectionConfig
    - Enforces unique template names
    - Protects default templates from deletion
```

## Development Workflow

### Local Development
```bash
# Install Supabase CLI
brew install supabase/tap/supabase

# Start local instance
supabase start

# Apply migrations
supabase db reset

# Generate TypeScript types (for backend)
supabase gen types typescript --local
```

### Schema Changes
1. Create new migration file: `00X_description.sql`
2. Write idempotent DDL (CREATE IF NOT EXISTS)
3. Add COMMENT ON for documentation
4. Include rollback instructions in header
5. Test locally with `supabase db reset`
6. Commit migration file only (no instant-T docs)

### Testing Migrations
```sql
-- Test in transaction (auto-rollback)
BEGIN;
\i migrations/003_new_feature.sql
-- Verify changes
SELECT * FROM information_schema.tables WHERE table_name = 'new_table';
ROLLBACK;
```

## Supabase Configuration

### Environment Variables
```bash
SUPABASE_URL=https://xxx.supabase.co
SUPABASE_ANON_KEY=eyJhbGc...
SUPABASE_SERVICE_ROLE_KEY=eyJhbGc... # Server-side only
```

### Connection Pooling
- **Pooler mode**: Transaction (for serverless)
- **Max connections**: 100 (Supabase free tier)
- **Idle timeout**: 60s
- **Connection reuse**: Via Swift Supabase client

### Security

**Row-Level Security (RLS):**
- Enabled on all user-facing tables
- Policies enforce `auth.uid() = user_id`
- Service role bypasses RLS (for migrations)

**API Keys:**
- `anon key` - Public, rate-limited (client apps)
- `service_role key` - Private, unrestricted (backend only)

## References

**PostgreSQL Full-Text Search:**
- [PostgreSQL Text Search Documentation](https://www.postgresql.org/docs/current/textsearch.html)
- [ts_rank_cd() for BM25-like ranking](https://www.postgresql.org/docs/current/textsearch-controls.html#TEXTSEARCH-RANKING)

**pgvector:**
- [GitHub: pgvector](https://github.com/pgvector/pgvector)
- [HNSW index for fast ANN search](https://github.com/pgvector/pgvector#hnsw)

**Supabase:**
- [Database Migrations Guide](https://supabase.com/docs/guides/database/migrations)
- [Row Level Security](https://supabase.com/docs/guides/auth/row-level-security)

## Maintenance

**Index Monitoring:**
```sql
-- Check index usage
SELECT schemaname, tablename, indexname, idx_scan
FROM pg_stat_user_indexes
ORDER BY idx_scan DESC;

-- Check index size
SELECT pg_size_pretty(pg_relation_size('idx_code_chunks_content_tsv'));
```

**Vacuum and Analyze:**
```sql
-- Run after bulk inserts
VACUUM ANALYZE code_chunks;
VACUUM ANALYZE code_embeddings;
```

**Query Performance:**
```sql
-- Enable query timing
EXPLAIN ANALYZE
SELECT * FROM match_code_chunks(
    'project-uuid',
    ARRAY[0.1, 0.2, ...],
    0.7,
    10
);
```

---

**Architecture Alignment:**
- Schema follows Clean Architecture (Infrastructure layer)
- Domain layer remains database-agnostic
- Migrations are deployment artifacts, not domain models
- RPC functions optimize query performance without leaking to domain
