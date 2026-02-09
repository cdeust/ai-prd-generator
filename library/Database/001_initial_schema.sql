-- ============================================================================
-- AI PRD System - Initial Database Schema
-- Migration: 001_initial_schema.sql
-- ============================================================================
--
-- PRODUCTION-READY SCHEMA with:
-- ✅ Namespaced ENUM types
-- ✅ Explicit FK constraint names
-- ✅ CHECK constraints for validation
-- ✅ Row-Level Security (RLS) policies
-- ✅ Comprehensive documentation (COMMENT ON)
-- ✅ Performance-optimized indexes (HNSW, GIN, B-tree)
-- ✅ RPC functions for complex queries
--
-- ============================================================================

-- ============================================================================
-- EXTENSIONS
-- ============================================================================

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";    -- UUID generation
CREATE EXTENSION IF NOT EXISTS "vector";       -- pgvector for embeddings
CREATE EXTENSION IF NOT EXISTS "pg_trgm";      -- Trigram similarity

-- ============================================================================
-- ENUMS (Properly Namespaced)
-- ============================================================================

-- Codebase ENUMs
CREATE TYPE codebase_repository_type AS ENUM ('git', 'github', 'gitlab', 'bitbucket', 'local');
CREATE TYPE code_programming_language AS ENUM (
    'swift', 'kotlin', 'typescript', 'javascript', 'python',
    'java', 'go', 'rust', 'csharp', 'cpp', 'other'
);

-- Project ENUMs
CREATE TYPE project_indexing_status AS ENUM ('pending', 'in_progress', 'completed', 'failed');

-- Code chunk ENUMs
CREATE TYPE code_chunk_type AS ENUM (
    'function', 'class', 'struct', 'enum', 'interface',
    'protocol', 'extension', 'property', 'method',
    'import', 'comment', 'other'
);

-- PRD ENUMs
CREATE TYPE prd_thinking_mode AS ENUM ('none', 'chain_of_thought', 'tree_of_thoughts', 'react', 'reflexion');
CREATE TYPE prd_privacy_level AS ENUM ('public', 'unlisted', 'private');
CREATE TYPE prd_status AS ENUM ('draft', 'in_review', 'approved', 'archived');
CREATE TYPE prd_section_type AS ENUM (
    'overview', 'user_stories', 'features', 'data_model',
    'api_specification', 'test_specification', 'constraints',
    'roadmap', 'validation', 'other'
);

-- Mockup ENUMs
CREATE TYPE mockup_type AS ENUM ('wireframe', 'mockup', 'prototype', 'screenshot');
CREATE TYPE mockup_source AS ENUM ('upload', 'url', 'generated');

-- ============================================================================
-- TABLE 1: Users
-- ============================================================================

CREATE TABLE users (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    email text UNIQUE NOT NULL,
    name text,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),

    CONSTRAINT users_email_valid CHECK (email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$')
);

COMMENT ON TABLE users IS 'System users with authentication';
COMMENT ON COLUMN users.email IS 'Unique email address for authentication';

CREATE INDEX idx_users_email ON users(email);

-- Row-Level Security
ALTER TABLE users ENABLE ROW LEVEL SECURITY;

CREATE POLICY users_select_own
    ON users FOR SELECT
    USING (auth.uid() = id);

CREATE POLICY users_update_own
    ON users FOR UPDATE
    USING (auth.uid() = id);

-- ============================================================================
-- TABLE 2: Codebases
-- ============================================================================

CREATE TABLE codebases (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id uuid NOT NULL,
    name text NOT NULL,
    description text,
    repository_url text,
    repository_type codebase_repository_type,
    default_branch text DEFAULT 'main',
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),

    CONSTRAINT fk_codebases_user
        FOREIGN KEY (user_id)
        REFERENCES users(id)
        ON DELETE CASCADE,

    CONSTRAINT codebases_name_not_empty CHECK (length(trim(name)) > 0)
);

COMMENT ON TABLE codebases IS 'Code repositories indexed for PRD generation';
COMMENT ON COLUMN codebases.repository_url IS 'Git repository URL';
COMMENT ON COLUMN codebases.default_branch IS 'Default branch to index (e.g., main, master)';

CREATE INDEX idx_codebases_user_id ON codebases(user_id);
CREATE INDEX idx_codebases_created_at ON codebases(created_at DESC);

-- Row-Level Security
ALTER TABLE codebases ENABLE ROW LEVEL SECURITY;

CREATE POLICY codebases_crud_own
    ON codebases
    USING (auth.uid() = user_id);

-- ============================================================================
-- TABLE 3: Codebase Projects
-- ============================================================================

CREATE TABLE codebase_projects (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    codebase_id uuid NOT NULL,
    name text NOT NULL,
    repository_url text NOT NULL,
    branch text NOT NULL,
    commit_sha text,
    indexing_status project_indexing_status NOT NULL DEFAULT 'pending',
    indexing_started_at timestamptz,
    indexing_completed_at timestamptz,
    indexing_error text,
    total_files int DEFAULT 0,
    total_chunks int DEFAULT 0,
    total_tokens bigint DEFAULT 0,
    merkle_root_hash text,
    detected_languages text[],
    detected_patterns text[],
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),

    CONSTRAINT fk_codebase_projects_codebase
        FOREIGN KEY (codebase_id)
        REFERENCES codebases(id)
        ON DELETE CASCADE,

    CONSTRAINT codebase_projects_totals_non_negative CHECK (
        total_files >= 0 AND
        total_chunks >= 0 AND
        total_tokens >= 0
    ),
    CONSTRAINT codebase_projects_unique_repo_branch UNIQUE(repository_url, branch)
);

COMMENT ON TABLE codebase_projects IS 'Indexed snapshots of codebases at specific commits';
COMMENT ON COLUMN codebase_projects.merkle_root_hash IS 'Root hash of Merkle tree for integrity verification';

CREATE INDEX idx_codebase_projects_codebase_id ON codebase_projects(codebase_id);
CREATE INDEX idx_codebase_projects_status ON codebase_projects(indexing_status);

-- Row-Level Security
ALTER TABLE codebase_projects ENABLE ROW LEVEL SECURITY;

CREATE POLICY codebase_projects_crud_via_codebase
    ON codebase_projects
    USING (
        EXISTS (
            SELECT 1 FROM codebases
            WHERE codebases.id = codebase_projects.codebase_id
            AND codebases.user_id = auth.uid()
        )
    );

-- ============================================================================
-- TABLE 4: Code Files
-- ============================================================================

CREATE TABLE code_files (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    codebase_id uuid NOT NULL,
    project_id uuid NOT NULL,
    file_path text NOT NULL,
    file_hash text NOT NULL,
    file_size int NOT NULL,
    language text,
    is_parsed boolean NOT NULL DEFAULT false,
    parse_error text,
    file_path_tsv tsvector GENERATED ALWAYS AS (
        to_tsvector('english', coalesce(file_path, ''))
    ) STORED,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),

    CONSTRAINT fk_code_files_codebase
        FOREIGN KEY (codebase_id)
        REFERENCES codebases(id)
        ON DELETE CASCADE,

    CONSTRAINT fk_code_files_project
        FOREIGN KEY (project_id)
        REFERENCES codebase_projects(id)
        ON DELETE CASCADE,

    CONSTRAINT code_files_size_non_negative CHECK (file_size >= 0),
    CONSTRAINT code_files_unique_path_per_project UNIQUE(project_id, file_path)
);

COMMENT ON TABLE code_files IS 'Individual files within indexed codebase projects';
COMMENT ON COLUMN code_files.file_path_tsv IS 'Full-text search vector for file paths';

CREATE INDEX idx_code_files_codebase_id ON code_files(codebase_id);
CREATE INDEX idx_code_files_project_id ON code_files(project_id);
CREATE INDEX idx_code_files_language ON code_files(language);
CREATE INDEX idx_code_files_path_tsv ON code_files USING GIN(file_path_tsv);

-- Row-Level Security
ALTER TABLE code_files ENABLE ROW LEVEL SECURITY;

CREATE POLICY code_files_crud_via_codebase
    ON code_files
    USING (
        EXISTS (
            SELECT 1 FROM codebases
            WHERE codebases.id = code_files.codebase_id
            AND codebases.user_id = auth.uid()
        )
    );

-- ============================================================================
-- TABLE 5: Code Chunks (RAG Core)
-- ============================================================================

CREATE TABLE code_chunks (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    file_id uuid NOT NULL,
    codebase_id uuid NOT NULL,
    project_id uuid NOT NULL,
    file_path text NOT NULL,
    content text NOT NULL,
    enriched_content text NULL,
    content_hash text NOT NULL,
    start_line int NOT NULL,
    end_line int NOT NULL,
    chunk_type code_chunk_type NOT NULL,
    language text NOT NULL,
    symbols text[] DEFAULT '{}',
    imports text[] DEFAULT '{}',
    token_count int NOT NULL,
    content_tsv tsvector GENERATED ALWAYS AS (
        setweight(to_tsvector('english', coalesce(content, '')), 'A')
    ) STORED,
    enriched_content_tsv tsvector GENERATED ALWAYS AS (
        setweight(to_tsvector('english', coalesce(enriched_content, content)), 'A')
    ) STORED,
    created_at timestamptz NOT NULL DEFAULT now(),

    CONSTRAINT fk_code_chunks_file
        FOREIGN KEY (file_id)
        REFERENCES code_files(id)
        ON DELETE CASCADE,

    CONSTRAINT fk_code_chunks_codebase
        FOREIGN KEY (codebase_id)
        REFERENCES codebases(id)
        ON DELETE CASCADE,

    CONSTRAINT fk_code_chunks_project
        FOREIGN KEY (project_id)
        REFERENCES codebase_projects(id)
        ON DELETE CASCADE,

    CONSTRAINT code_chunks_valid_line_range CHECK (start_line <= end_line AND start_line > 0),
    CONSTRAINT code_chunks_token_count_positive CHECK (token_count > 0)
);

COMMENT ON TABLE code_chunks IS 'Semantic code chunks for RAG retrieval';
COMMENT ON COLUMN code_chunks.file_path IS 'Denormalized for query performance in hybrid search';
COMMENT ON COLUMN code_chunks.content_tsv IS 'BM25 full-text search vector';
COMMENT ON COLUMN code_chunks.enriched_content IS 'Contextual Retrieval enriched content for BM25 (+49% precision improvement)';
COMMENT ON COLUMN code_chunks.enriched_content_tsv IS 'BM25 full-text search vector using enriched content (falls back to original content)';

CREATE INDEX idx_code_chunks_file_id ON code_chunks(file_id);
CREATE INDEX idx_code_chunks_codebase_id ON code_chunks(codebase_id);
CREATE INDEX idx_code_chunks_project_id ON code_chunks(project_id);
CREATE INDEX idx_code_chunks_type ON code_chunks(chunk_type);
CREATE INDEX idx_code_chunks_content_tsv ON code_chunks USING GIN(content_tsv);
CREATE INDEX idx_code_chunks_enriched_content_tsv ON code_chunks USING GIN(enriched_content_tsv);
CREATE INDEX idx_code_chunks_line_range ON code_chunks(file_id, start_line, end_line);
CREATE INDEX idx_code_chunks_file_path_lines ON code_chunks(codebase_id, file_path, start_line, end_line);

-- Row-Level Security
ALTER TABLE code_chunks ENABLE ROW LEVEL SECURITY;

CREATE POLICY code_chunks_crud_via_codebase
    ON code_chunks
    USING (
        EXISTS (
            SELECT 1 FROM codebases
            WHERE codebases.id = code_chunks.codebase_id
            AND codebases.user_id = auth.uid()
        )
    );

-- ============================================================================
-- TABLE 6: Code Embeddings (Vector Search)
-- ============================================================================

CREATE TABLE code_embeddings (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    chunk_id uuid NOT NULL,
    project_id uuid NOT NULL,
    embedding vector(1536) NOT NULL,
    model text NOT NULL DEFAULT 'text-embedding-ada-002',
    created_at timestamptz NOT NULL DEFAULT now(),

    CONSTRAINT fk_code_embeddings_chunk
        FOREIGN KEY (chunk_id)
        REFERENCES code_chunks(id)
        ON DELETE CASCADE,

    CONSTRAINT fk_code_embeddings_project
        FOREIGN KEY (project_id)
        REFERENCES codebase_projects(id)
        ON DELETE CASCADE,

    CONSTRAINT code_embeddings_unique_chunk_model UNIQUE(chunk_id, model)
);

COMMENT ON TABLE code_embeddings IS 'Vector embeddings for semantic code search';
COMMENT ON COLUMN code_embeddings.embedding IS '1536-dimensional vector (OpenAI ada-002)';

-- HNSW index for <30ms vector search on millions of chunks
CREATE INDEX idx_code_embeddings_vector ON code_embeddings
USING hnsw (embedding vector_cosine_ops)
WITH (m = 16, ef_construction = 64);

CREATE INDEX idx_code_embeddings_chunk_id ON code_embeddings(chunk_id);
CREATE INDEX idx_code_embeddings_project_id ON code_embeddings(project_id);

-- Row-Level Security
ALTER TABLE code_embeddings ENABLE ROW LEVEL SECURITY;

CREATE POLICY code_embeddings_crud_via_project
    ON code_embeddings
    USING (
        EXISTS (
            SELECT 1 FROM codebase_projects cp
            JOIN codebases c ON c.id = cp.codebase_id
            WHERE cp.id = code_embeddings.project_id
            AND c.user_id = auth.uid()
        )
    );

-- ============================================================================
-- TABLE 7: Merkle Nodes (Integrity)
-- ============================================================================

CREATE TABLE merkle_nodes (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    project_id uuid NOT NULL,
    node_hash text NOT NULL,
    left_hash text,
    right_hash text,
    chunk_id uuid,
    level int NOT NULL,
    position int NOT NULL,
    created_at timestamptz NOT NULL DEFAULT now(),

    CONSTRAINT fk_merkle_nodes_project
        FOREIGN KEY (project_id)
        REFERENCES codebase_projects(id)
        ON DELETE CASCADE,

    CONSTRAINT fk_merkle_nodes_chunk
        FOREIGN KEY (chunk_id)
        REFERENCES code_chunks(id)
        ON DELETE CASCADE,

    CONSTRAINT merkle_nodes_level_non_negative CHECK (level >= 0),
    CONSTRAINT merkle_nodes_position_non_negative CHECK (position >= 0),
    CONSTRAINT merkle_nodes_unique_position UNIQUE(project_id, level, position)
);

COMMENT ON TABLE merkle_nodes IS 'Merkle tree for code integrity verification';
COMMENT ON COLUMN merkle_nodes.chunk_id IS 'Only set for leaf nodes';

CREATE INDEX idx_merkle_nodes_project_id ON merkle_nodes(project_id);
CREATE INDEX idx_merkle_nodes_chunk_id ON merkle_nodes(chunk_id);

-- Row-Level Security
ALTER TABLE merkle_nodes ENABLE ROW LEVEL SECURITY;

CREATE POLICY merkle_nodes_crud_via_project
    ON merkle_nodes
    USING (
        EXISTS (
            SELECT 1 FROM codebase_projects cp
            JOIN codebases c ON c.id = cp.codebase_id
            WHERE cp.id = merkle_nodes.project_id
            AND c.user_id = auth.uid()
        )
    );

-- ============================================================================
-- TABLE 8: PRD Documents
-- ============================================================================

CREATE TABLE prd_documents (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id uuid NOT NULL,
    codebase_id uuid,
    title text NOT NULL,
    description text,
    version text DEFAULT '1.0.0',
    status prd_status NOT NULL DEFAULT 'draft',
    metadata_json jsonb,
    thinking_chain_json jsonb,
    professional_analysis_json jsonb,
    thinking_mode prd_thinking_mode DEFAULT 'chain_of_thought',
    privacy_level prd_privacy_level DEFAULT 'private',
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),

    CONSTRAINT fk_prd_documents_user
        FOREIGN KEY (user_id)
        REFERENCES users(id)
        ON DELETE CASCADE,

    CONSTRAINT fk_prd_documents_codebase
        FOREIGN KEY (codebase_id)
        REFERENCES codebases(id)
        ON DELETE SET NULL,

    CONSTRAINT prd_documents_title_not_empty CHECK (length(trim(title)) > 0)
);

COMMENT ON TABLE prd_documents IS 'Generated Product Requirement Documents';
COMMENT ON COLUMN prd_documents.thinking_chain_json IS 'Complete reasoning chain (ThoughtChain entity)';
COMMENT ON COLUMN prd_documents.professional_analysis_json IS 'Professional validation analysis';

CREATE INDEX idx_prd_documents_user_id ON prd_documents(user_id);
CREATE INDEX idx_prd_documents_codebase_id ON prd_documents(codebase_id);
CREATE INDEX idx_prd_documents_status ON prd_documents(status);
CREATE INDEX idx_prd_documents_created_at ON prd_documents(created_at DESC);
CREATE INDEX idx_prd_documents_metadata_json ON prd_documents USING GIN(metadata_json);
CREATE INDEX idx_prd_documents_thinking_json ON prd_documents USING GIN(thinking_chain_json);
CREATE INDEX idx_prd_documents_analysis_json ON prd_documents USING GIN(professional_analysis_json);

-- Row-Level Security
ALTER TABLE prd_documents ENABLE ROW LEVEL SECURITY;

CREATE POLICY prd_documents_crud_own
    ON prd_documents
    USING (auth.uid() = user_id);

CREATE POLICY prd_documents_select_public
    ON prd_documents FOR SELECT
    USING (privacy_level = 'public');

-- ============================================================================
-- TABLE 9: PRD Sections
-- ============================================================================

CREATE TABLE prd_sections (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    prd_document_id uuid NOT NULL,
    section_type prd_section_type NOT NULL,
    title text NOT NULL,
    content text NOT NULL,
    order_index int NOT NULL,
    openapi_spec_json jsonb,
    test_suite_json jsonb,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),

    CONSTRAINT fk_prd_sections_document
        FOREIGN KEY (prd_document_id)
        REFERENCES prd_documents(id)
        ON DELETE CASCADE,

    CONSTRAINT prd_sections_order_non_negative CHECK (order_index >= 0),
    CONSTRAINT prd_sections_unique_type_per_doc UNIQUE(prd_document_id, section_type)
);

COMMENT ON TABLE prd_sections IS 'Individual sections within PRD documents';
COMMENT ON COLUMN prd_sections.openapi_spec_json IS 'OpenAPI specification for API sections';
COMMENT ON COLUMN prd_sections.test_suite_json IS 'Test suite for test specification sections';

CREATE INDEX idx_prd_sections_document_id ON prd_sections(prd_document_id);
CREATE INDEX idx_prd_sections_type ON prd_sections(section_type);
CREATE INDEX idx_prd_sections_order ON prd_sections(prd_document_id, order_index);
CREATE INDEX idx_prd_sections_openapi_json ON prd_sections USING GIN(openapi_spec_json);
CREATE INDEX idx_prd_sections_test_json ON prd_sections USING GIN(test_suite_json);

-- Row-Level Security
ALTER TABLE prd_sections ENABLE ROW LEVEL SECURITY;

CREATE POLICY prd_sections_crud_via_document
    ON prd_sections
    USING (
        EXISTS (
            SELECT 1 FROM prd_documents
            WHERE prd_documents.id = prd_sections.prd_document_id
            AND prd_documents.user_id = auth.uid()
        )
    );

-- ============================================================================
-- TABLE 10: Mockups
-- ============================================================================

CREATE TABLE mockups (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    prd_document_id uuid NOT NULL,
    name text NOT NULL,
    description text,
    mockup_type mockup_type NOT NULL,
    source mockup_source NOT NULL,
    file_url text NOT NULL,
    file_size int,
    width int,
    height int,
    analysis_result_json jsonb,
    order_index int NOT NULL,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),

    CONSTRAINT fk_mockups_document
        FOREIGN KEY (prd_document_id)
        REFERENCES prd_documents(id)
        ON DELETE CASCADE,

    CONSTRAINT mockups_file_size_non_negative CHECK (file_size IS NULL OR file_size >= 0),
    CONSTRAINT mockups_dimensions_valid CHECK (
        (width IS NULL AND height IS NULL) OR
        (width > 0 AND height > 0)
    ),
    CONSTRAINT mockups_order_non_negative CHECK (order_index >= 0)
);

COMMENT ON TABLE mockups IS 'UI mockups and wireframes for PRD documents';
COMMENT ON COLUMN mockups.analysis_result_json IS 'Vision API analysis result (MockupAnalysisResult)';

CREATE INDEX idx_mockups_prd_document_id ON mockups(prd_document_id);
CREATE INDEX idx_mockups_type ON mockups(mockup_type);
CREATE INDEX idx_mockups_order ON mockups(prd_document_id, order_index);
CREATE INDEX idx_mockups_analysis_json ON mockups USING GIN(analysis_result_json);

-- Row-Level Security
ALTER TABLE mockups ENABLE ROW LEVEL SECURITY;

CREATE POLICY mockups_crud_via_document
    ON mockups
    USING (
        EXISTS (
            SELECT 1 FROM prd_documents
            WHERE prd_documents.id = mockups.prd_document_id
            AND prd_documents.user_id = auth.uid()
        )
    );

-- ============================================================================
-- TABLE 11: Sessions
-- ============================================================================

CREATE TABLE sessions (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id uuid NOT NULL,
    prd_document_id uuid,
    metadata_json jsonb,
    started_at timestamptz NOT NULL DEFAULT now(),
    ended_at timestamptz,
    is_active boolean NOT NULL DEFAULT true,

    CONSTRAINT fk_sessions_user
        FOREIGN KEY (user_id)
        REFERENCES users(id)
        ON DELETE CASCADE,

    CONSTRAINT fk_sessions_document
        FOREIGN KEY (prd_document_id)
        REFERENCES prd_documents(id)
        ON DELETE SET NULL,

    CONSTRAINT sessions_end_after_start CHECK (
        ended_at IS NULL OR ended_at >= started_at
    )
);

COMMENT ON TABLE sessions IS 'User sessions for PRD generation workflows';
COMMENT ON COLUMN sessions.metadata_json IS 'Session metadata (SessionMetadata entity)';

CREATE INDEX idx_sessions_user_id ON sessions(user_id);
CREATE INDEX idx_sessions_prd_document_id ON sessions(prd_document_id);
CREATE INDEX idx_sessions_active ON sessions(is_active) WHERE is_active = true;

-- Row-Level Security
ALTER TABLE sessions ENABLE ROW LEVEL SECURITY;

CREATE POLICY sessions_crud_own
    ON sessions
    USING (auth.uid() = user_id);

-- ============================================================================
-- RPC FUNCTIONS (Optimized Queries)
-- ============================================================================

-- Contextual Retrieval: Find chunks BEFORE a line
CREATE OR REPLACE FUNCTION find_chunks_before_line(
    p_codebase_id uuid,
    p_file_path text,
    p_end_line_before int,
    p_limit int DEFAULT 3
)
RETURNS TABLE (
    id uuid, file_id uuid, codebase_id uuid, file_path text, content text,
    content_hash text, start_line int, end_line int, chunk_type code_chunk_type,
    language text, symbols text[], imports text[],
    token_count int, created_at timestamptz
)
LANGUAGE sql STABLE
AS $$
    SELECT
        id, file_id, codebase_id, file_path, content, content_hash,
        start_line, end_line, chunk_type, language, symbols, imports,
        token_count, created_at
    FROM code_chunks
    WHERE code_chunks.codebase_id = p_codebase_id
        AND code_chunks.file_path = p_file_path
        AND code_chunks.end_line < p_end_line_before
    ORDER BY code_chunks.end_line DESC
    LIMIT p_limit;
$$;

COMMENT ON FUNCTION find_chunks_before_line IS 'Find chunks ending before a line for contextual retrieval';

-- Contextual Retrieval: Find chunks AFTER a line
CREATE OR REPLACE FUNCTION find_chunks_after_line(
    p_codebase_id uuid,
    p_file_path text,
    p_start_line_after int,
    p_limit int DEFAULT 3
)
RETURNS TABLE (
    id uuid, file_id uuid, codebase_id uuid, file_path text, content text,
    content_hash text, start_line int, end_line int, chunk_type code_chunk_type,
    language text, symbols text[], imports text[],
    token_count int, created_at timestamptz
)
LANGUAGE sql STABLE
AS $$
    SELECT
        id, file_id, codebase_id, file_path, content, content_hash,
        start_line, end_line, chunk_type, language, symbols, imports,
        token_count, created_at
    FROM code_chunks
    WHERE code_chunks.codebase_id = p_codebase_id
        AND code_chunks.file_path = p_file_path
        AND code_chunks.start_line > p_start_line_after
    ORDER BY code_chunks.start_line ASC
    LIMIT p_limit;
$$;

COMMENT ON FUNCTION find_chunks_after_line IS 'Find chunks starting after a line for contextual retrieval';

-- Full-Text Search: BM25 ranking for chunks with Contextual Retrieval
CREATE OR REPLACE FUNCTION search_chunks_bm25(
    p_project_id uuid,
    p_query text,
    p_limit int DEFAULT 100,
    p_min_score float DEFAULT 0.01
)
RETURNS TABLE (
    chunk_id uuid, file_id uuid, codebase_id uuid, file_path text, content text,
    content_hash text, start_line int, end_line int, chunk_type code_chunk_type,
    language text, symbols text[], imports text[],
    token_count int, created_at timestamptz, bm25_score real
)
LANGUAGE sql STABLE
AS $$
    SELECT
        id, file_id, codebase_id, file_path, content, content_hash,
        start_line, end_line, chunk_type, language, symbols, imports,
        token_count, created_at,
        ts_rank(enriched_content_tsv, websearch_to_tsquery('english', p_query))::real AS bm25_score
    FROM code_chunks
    WHERE project_id = p_project_id
        AND enriched_content_tsv @@ websearch_to_tsquery('english', p_query)
        AND ts_rank(enriched_content_tsv, websearch_to_tsquery('english', p_query)) >= p_min_score
    ORDER BY bm25_score DESC
    LIMIT p_limit;
$$;

COMMENT ON FUNCTION search_chunks_bm25 IS 'Full-text search with BM25 ranking using ts_rank on Contextual Retrieval enriched content';

-- Grant Permissions
GRANT EXECUTE ON FUNCTION find_chunks_before_line TO authenticated;
GRANT EXECUTE ON FUNCTION find_chunks_after_line TO authenticated;
GRANT EXECUTE ON FUNCTION search_chunks_bm25 TO authenticated;

-- ============================================================================
-- END OF MIGRATION
-- ============================================================================
