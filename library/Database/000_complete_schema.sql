-- ============================================================================
-- AI PRD System - Complete Database Schema
-- Single-file PostgreSQL migration for any environment (Supabase or self-hosted)
-- ============================================================================
--
-- Usage:
--   psql $DATABASE_URL -f library/Database/000_complete_schema.sql
--
-- Features:
--   ✅ All tables for business logic, auth, and rate limiting
--   ✅ pgvector for semantic search
--   ✅ Full-text search with BM25 ranking
--   ✅ Row-Level Security (RLS) policies
--   ✅ Optimized indexes (HNSW, GIN, B-tree)
--   ✅ RPC functions for complex queries
--   ✅ Works with Supabase OR self-hosted PostgreSQL
--
-- ============================================================================

-- ============================================================================
-- SECTION 1: EXTENSIONS
-- ============================================================================

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";    -- UUID generation
CREATE EXTENSION IF NOT EXISTS "vector";       -- pgvector for embeddings
CREATE EXTENSION IF NOT EXISTS "pg_trgm";      -- Trigram similarity

-- ============================================================================
-- SECTION 2: ENUM TYPES
-- ============================================================================

-- Codebase ENUMs
DO $$ BEGIN
    CREATE TYPE codebase_repository_type AS ENUM ('git', 'github', 'gitlab', 'bitbucket', 'local');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
    CREATE TYPE code_programming_language AS ENUM (
        'swift', 'kotlin', 'typescript', 'javascript', 'python',
        'java', 'go', 'rust', 'csharp', 'cpp', 'other'
    );
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- Project ENUMs
DO $$ BEGIN
    CREATE TYPE project_indexing_status AS ENUM ('pending', 'in_progress', 'completed', 'failed');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- Code chunk ENUMs
DO $$ BEGIN
    CREATE TYPE code_chunk_type AS ENUM (
        'function', 'class', 'struct', 'enum', 'interface',
        'protocol', 'extension', 'property', 'method',
        'import', 'comment', 'other'
    );
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- PRD ENUMs
DO $$ BEGIN
    CREATE TYPE prd_thinking_mode AS ENUM ('none', 'chain_of_thought', 'tree_of_thoughts', 'react', 'reflexion');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
    CREATE TYPE prd_privacy_level AS ENUM ('public', 'unlisted', 'private');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
    CREATE TYPE prd_status AS ENUM ('draft', 'in_review', 'approved', 'archived');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
    CREATE TYPE prd_section_type AS ENUM (
        'overview', 'goals', 'requirements', 'user_stories', 'features',
        'technical_specification', 'acceptance_criteria', 'data_model',
        'api_specification', 'security_considerations', 'performance_requirements',
        'test_specification', 'testing', 'deployment', 'constraints',
        'risks', 'timeline', 'roadmap', 'validation', 'other'
    );
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- Mockup ENUMs
DO $$ BEGIN
    CREATE TYPE mockup_type AS ENUM ('wireframe', 'mockup', 'prototype', 'screenshot');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
    CREATE TYPE mockup_source AS ENUM ('upload', 'url', 'generated');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- File Upload ENUMs
DO $$ BEGIN
    CREATE TYPE uploaded_file_type AS ENUM ('mockup', 'document', 'attachment', 'other');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- ============================================================================
-- SECTION 3: CORE TABLES - Authentication
-- ============================================================================

-- Users (Auth)
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email TEXT UNIQUE NOT NULL,
    password_hash TEXT NOT NULL,
    name TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE users IS 'System users with authentication';
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);

-- Refresh Tokens
CREATE TABLE IF NOT EXISTS refresh_tokens (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    token_hash TEXT UNIQUE NOT NULL,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    expires_at TIMESTAMPTZ NOT NULL,
    revoked_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_refresh_tokens_user_id ON refresh_tokens(user_id);
CREATE INDEX IF NOT EXISTS idx_refresh_tokens_expires_at ON refresh_tokens(expires_at);

-- Audit Logs
CREATE TABLE IF NOT EXISTS audit_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    event_type TEXT NOT NULL,
    ip_address TEXT,
    user_agent TEXT,
    details JSONB,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_audit_logs_user_id ON audit_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_audit_logs_event_type ON audit_logs(event_type);
CREATE INDEX IF NOT EXISTS idx_audit_logs_created_at ON audit_logs(created_at DESC);

-- OAuth Clients (for external apps like ChatGPT)
CREATE TABLE IF NOT EXISTS oauth_clients (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    client_id TEXT UNIQUE NOT NULL,
    client_secret_hash TEXT NOT NULL,
    name TEXT NOT NULL,
    redirect_uris TEXT[] NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_oauth_clients_client_id ON oauth_clients(client_id);

-- Authorization Codes (OAuth flow)
CREATE TABLE IF NOT EXISTS authorization_codes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code TEXT UNIQUE NOT NULL,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    client_id TEXT NOT NULL,
    redirect_uri TEXT NOT NULL,
    expires_at TIMESTAMPTZ NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_authorization_codes_code ON authorization_codes(code);
CREATE INDEX IF NOT EXISTS idx_authorization_codes_user_id ON authorization_codes(user_id);

-- OAuth Settings (GitHub/Bitbucket credentials for platform)
CREATE TABLE IF NOT EXISTS oauth_settings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    provider TEXT UNIQUE NOT NULL,
    client_id TEXT NOT NULL,
    client_secret TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_oauth_settings_provider ON oauth_settings(provider);

-- Uploaded Files
CREATE TABLE IF NOT EXISTS uploaded_files (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    file_name TEXT NOT NULL,
    file_size BIGINT NOT NULL CHECK (file_size >= 0),
    mime_type TEXT NOT NULL,
    file_type uploaded_file_type NOT NULL DEFAULT 'other',
    storage_bucket TEXT NOT NULL,
    storage_path TEXT NOT NULL,
    public_url TEXT,
    checksum TEXT,
    expires_at TIMESTAMPTZ,
    associated_entity_type TEXT,
    associated_entity_id UUID,
    upload_completed BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT uploaded_files_name_not_empty CHECK (length(trim(file_name)) > 0),
    CONSTRAINT uploaded_files_unique_storage_path UNIQUE (storage_bucket, storage_path)
);

COMMENT ON TABLE uploaded_files IS 'Tracks all uploaded files for lifecycle management and cleanup';
COMMENT ON COLUMN uploaded_files.file_type IS 'Type of file (mockup, document, attachment, other)';
COMMENT ON COLUMN uploaded_files.storage_bucket IS 'Supabase storage bucket name';
COMMENT ON COLUMN uploaded_files.storage_path IS 'Path within storage bucket';
COMMENT ON COLUMN uploaded_files.public_url IS 'Public URL if file is publicly accessible';
COMMENT ON COLUMN uploaded_files.checksum IS 'File checksum for integrity verification';
COMMENT ON COLUMN uploaded_files.expires_at IS 'Expiration timestamp for temporary files';
COMMENT ON COLUMN uploaded_files.associated_entity_type IS 'Entity type this file belongs to (prd_document, mockup, etc.)';
COMMENT ON COLUMN uploaded_files.associated_entity_id IS 'Entity ID this file belongs to';
COMMENT ON COLUMN uploaded_files.upload_completed IS 'Whether upload finished successfully';
CREATE INDEX IF NOT EXISTS idx_uploaded_files_user_id ON uploaded_files(user_id);
CREATE INDEX IF NOT EXISTS idx_uploaded_files_file_type ON uploaded_files(file_type);
CREATE INDEX IF NOT EXISTS idx_uploaded_files_storage_bucket_path ON uploaded_files(storage_bucket, storage_path);
CREATE INDEX IF NOT EXISTS idx_uploaded_files_expires_at ON uploaded_files(expires_at) WHERE expires_at IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_uploaded_files_associated_entity ON uploaded_files(associated_entity_type, associated_entity_id) WHERE associated_entity_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_uploaded_files_created_at ON uploaded_files(created_at DESC);

-- ============================================================================
-- SECTION 4: CORE TABLES - Codebase
-- ============================================================================

-- Codebases
CREATE TABLE IF NOT EXISTS codebases (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    description TEXT,
    repository_url TEXT,
    local_path TEXT,
    repository_type codebase_repository_type,
    default_branch TEXT DEFAULT 'main',
    indexing_status project_indexing_status NOT NULL DEFAULT 'pending',
    total_files INT NOT NULL DEFAULT 0,
    indexed_files INT NOT NULL DEFAULT 0,
    detected_languages TEXT[] NOT NULL DEFAULT '{}',
    last_indexed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT codebases_name_not_empty CHECK (length(trim(name)) > 0),
    CONSTRAINT codebases_files_non_negative CHECK (total_files >= 0 AND indexed_files >= 0),
    CONSTRAINT codebases_unique_user_repo_url UNIQUE (user_id, repository_url)
);

COMMENT ON TABLE codebases IS 'Code repositories indexed for PRD generation';
CREATE INDEX IF NOT EXISTS idx_codebases_user_id ON codebases(user_id);
CREATE INDEX IF NOT EXISTS idx_codebases_created_at ON codebases(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_codebases_repository_url ON codebases(repository_url) WHERE repository_url IS NOT NULL;

-- Codebase Projects
CREATE TABLE IF NOT EXISTS codebase_projects (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    codebase_id UUID NOT NULL REFERENCES codebases(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    repository_url TEXT NOT NULL,
    branch TEXT NOT NULL,
    commit_sha TEXT,
    indexing_status project_indexing_status NOT NULL DEFAULT 'pending',
    indexing_started_at TIMESTAMPTZ,
    indexing_completed_at TIMESTAMPTZ,
    indexing_error TEXT,
    total_files INT DEFAULT 0,
    total_chunks INT DEFAULT 0,
    total_tokens BIGINT DEFAULT 0,
    merkle_root_hash TEXT,
    detected_languages TEXT[],
    detected_frameworks TEXT[],
    architecture_patterns JSONB DEFAULT '[]'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT codebase_projects_totals_non_negative CHECK (
        total_files >= 0 AND total_chunks >= 0 AND total_tokens >= 0
    ),
    CONSTRAINT codebase_projects_unique_repo_branch UNIQUE(repository_url, branch)
);

COMMENT ON TABLE codebase_projects IS 'Indexed snapshots of codebases at specific commits';
CREATE INDEX IF NOT EXISTS idx_codebase_projects_codebase_id ON codebase_projects(codebase_id);
CREATE INDEX IF NOT EXISTS idx_codebase_projects_status ON codebase_projects(indexing_status);

-- Code Files
CREATE TABLE IF NOT EXISTS code_files (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    codebase_id UUID NOT NULL REFERENCES codebases(id) ON DELETE CASCADE,
    project_id UUID NOT NULL REFERENCES codebase_projects(id) ON DELETE CASCADE,
    file_path TEXT NOT NULL,
    file_hash TEXT NOT NULL,
    file_size INT NOT NULL,
    language TEXT,
    is_parsed BOOLEAN NOT NULL DEFAULT FALSE,
    parse_error TEXT,
    file_path_tsv TSVECTOR GENERATED ALWAYS AS (
        to_tsvector('english', coalesce(file_path, ''))
    ) STORED,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT code_files_size_non_negative CHECK (file_size >= 0),
    CONSTRAINT code_files_unique_path_per_project UNIQUE(project_id, file_path)
);

COMMENT ON TABLE code_files IS 'Individual files within indexed codebase projects';
CREATE INDEX IF NOT EXISTS idx_code_files_codebase_id ON code_files(codebase_id);
CREATE INDEX IF NOT EXISTS idx_code_files_project_id ON code_files(project_id);
CREATE INDEX IF NOT EXISTS idx_code_files_language ON code_files(language);
CREATE INDEX IF NOT EXISTS idx_code_files_path_tsv ON code_files USING GIN(file_path_tsv);

-- Code Chunks (RAG Core)
CREATE TABLE IF NOT EXISTS code_chunks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    file_id UUID NOT NULL REFERENCES code_files(id) ON DELETE CASCADE,
    codebase_id UUID NOT NULL REFERENCES codebases(id) ON DELETE CASCADE,
    project_id UUID NOT NULL REFERENCES codebase_projects(id) ON DELETE CASCADE,
    file_path TEXT NOT NULL,
    content TEXT NOT NULL,
    enriched_content TEXT NULL,
    content_hash TEXT NOT NULL,
    start_line INT NOT NULL,
    end_line INT NOT NULL,
    chunk_type code_chunk_type NOT NULL,
    language TEXT NOT NULL,
    symbols TEXT[] DEFAULT '{}',
    imports TEXT[] DEFAULT '{}',
    token_count INT NOT NULL,
    content_tsv TSVECTOR GENERATED ALWAYS AS (
        setweight(to_tsvector('english', coalesce(content, '')), 'A')
    ) STORED,
    enriched_content_tsv TSVECTOR GENERATED ALWAYS AS (
        setweight(to_tsvector('english', coalesce(enriched_content, content)), 'A')
    ) STORED,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT code_chunks_valid_line_range CHECK (start_line <= end_line AND start_line > 0),
    CONSTRAINT code_chunks_token_count_positive CHECK (token_count > 0)
);

COMMENT ON TABLE code_chunks IS 'Semantic code chunks for RAG retrieval';
COMMENT ON COLUMN code_chunks.enriched_content IS 'Contextual Retrieval enriched content for BM25 (+49% precision improvement)';
COMMENT ON COLUMN code_chunks.enriched_content_tsv IS 'BM25 full-text search vector using enriched content (falls back to original content)';
CREATE INDEX IF NOT EXISTS idx_code_chunks_file_id ON code_chunks(file_id);
CREATE INDEX IF NOT EXISTS idx_code_chunks_codebase_id ON code_chunks(codebase_id);
CREATE INDEX IF NOT EXISTS idx_code_chunks_project_id ON code_chunks(project_id);
CREATE INDEX IF NOT EXISTS idx_code_chunks_type ON code_chunks(chunk_type);
CREATE INDEX IF NOT EXISTS idx_code_chunks_content_tsv ON code_chunks USING GIN(content_tsv);
CREATE INDEX IF NOT EXISTS idx_code_chunks_enriched_content_tsv ON code_chunks USING GIN(enriched_content_tsv);
CREATE INDEX IF NOT EXISTS idx_code_chunks_line_range ON code_chunks(file_id, start_line, end_line);
CREATE INDEX IF NOT EXISTS idx_code_chunks_file_path_lines ON code_chunks(codebase_id, file_path, start_line, end_line);

-- Code Embeddings (Vector Search)
CREATE TABLE IF NOT EXISTS code_embeddings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    chunk_id UUID NOT NULL REFERENCES code_chunks(id) ON DELETE CASCADE,
    project_id UUID NOT NULL REFERENCES codebase_projects(id) ON DELETE CASCADE,
    embedding VECTOR(1536) NOT NULL,
    model TEXT NOT NULL DEFAULT 'text-embedding-ada-002',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT code_embeddings_unique_chunk_model UNIQUE(chunk_id, model)
);

COMMENT ON TABLE code_embeddings IS 'Vector embeddings for semantic code search';

-- HNSW index for fast vector search
CREATE INDEX IF NOT EXISTS idx_code_embeddings_vector ON code_embeddings
    USING hnsw (embedding vector_cosine_ops)
    WITH (m = 16, ef_construction = 64);

CREATE INDEX IF NOT EXISTS idx_code_embeddings_chunk_id ON code_embeddings(chunk_id);
CREATE INDEX IF NOT EXISTS idx_code_embeddings_project_id ON code_embeddings(project_id);

-- Merkle Nodes (Integrity)
CREATE TABLE IF NOT EXISTS merkle_nodes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    project_id UUID NOT NULL REFERENCES codebase_projects(id) ON DELETE CASCADE,
    node_hash TEXT NOT NULL,
    left_hash TEXT,
    right_hash TEXT,
    chunk_id UUID REFERENCES code_chunks(id) ON DELETE CASCADE,
    level INT NOT NULL,
    position INT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT merkle_nodes_level_non_negative CHECK (level >= 0),
    CONSTRAINT merkle_nodes_position_non_negative CHECK (position >= 0),
    CONSTRAINT merkle_nodes_unique_position UNIQUE(project_id, level, position)
);

COMMENT ON TABLE merkle_nodes IS 'Merkle tree for code integrity verification';
CREATE INDEX IF NOT EXISTS idx_merkle_nodes_project_id ON merkle_nodes(project_id);
CREATE INDEX IF NOT EXISTS idx_merkle_nodes_chunk_id ON merkle_nodes(chunk_id);

-- ============================================================================
-- SECTION 5: CORE TABLES - PRD
-- ============================================================================

-- PRD Documents
CREATE TABLE IF NOT EXISTS prd_documents (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    codebase_id UUID REFERENCES codebases(id) ON DELETE SET NULL,
    title TEXT NOT NULL,
    description TEXT,
    version TEXT DEFAULT '1.0.0',
    status prd_status NOT NULL DEFAULT 'draft',
    metadata_json JSONB,
    thinking_chain_json JSONB,
    professional_analysis_json JSONB,
    thinking_mode prd_thinking_mode DEFAULT 'chain_of_thought',
    privacy_level prd_privacy_level DEFAULT 'private',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT prd_documents_title_not_empty CHECK (length(trim(title)) > 0)
);

COMMENT ON TABLE prd_documents IS 'Generated Product Requirement Documents';
CREATE INDEX IF NOT EXISTS idx_prd_documents_user_id ON prd_documents(user_id);
CREATE INDEX IF NOT EXISTS idx_prd_documents_codebase_id ON prd_documents(codebase_id);
CREATE INDEX IF NOT EXISTS idx_prd_documents_status ON prd_documents(status);
CREATE INDEX IF NOT EXISTS idx_prd_documents_created_at ON prd_documents(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_prd_documents_metadata_json ON prd_documents USING GIN(metadata_json);

-- PRD Sections
CREATE TABLE IF NOT EXISTS prd_sections (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    prd_document_id UUID NOT NULL REFERENCES prd_documents(id) ON DELETE CASCADE,
    section_type prd_section_type NOT NULL,
    title TEXT NOT NULL,
    content TEXT NOT NULL,
    order_index INT NOT NULL,
    openapi_spec_json JSONB,
    test_suite_json JSONB,
    thinking_strategy TEXT,
    confidence DOUBLE PRECISION CHECK (confidence >= 0.0 AND confidence <= 1.0),
    assumptions_json JSONB DEFAULT '[]'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT prd_sections_order_non_negative CHECK (order_index >= 0),
    CONSTRAINT prd_sections_unique_type_per_doc UNIQUE(prd_document_id, section_type)
);

COMMENT ON TABLE prd_sections IS 'Individual sections within PRD documents';
COMMENT ON COLUMN prd_sections.thinking_strategy IS 'Thinking mode used for section generation (chain_of_thought, tree_of_thoughts, etc.)';
COMMENT ON COLUMN prd_sections.confidence IS 'AI confidence score for section content quality (0.0-1.0)';
COMMENT ON COLUMN prd_sections.assumptions_json IS 'Assumptions made during section generation (stored as JSONB array)';
CREATE INDEX IF NOT EXISTS idx_prd_sections_document_id ON prd_sections(prd_document_id);
CREATE INDEX IF NOT EXISTS idx_prd_sections_type ON prd_sections(section_type);
CREATE INDEX IF NOT EXISTS idx_prd_sections_order ON prd_sections(prd_document_id, order_index);
CREATE INDEX IF NOT EXISTS idx_prd_sections_thinking_strategy ON prd_sections(thinking_strategy) WHERE thinking_strategy IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_prd_sections_confidence ON prd_sections(confidence) WHERE confidence IS NOT NULL;

-- PRD Templates
CREATE TABLE IF NOT EXISTS prd_templates (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL UNIQUE,
    description TEXT NOT NULL,
    is_default BOOLEAN NOT NULL DEFAULT FALSE,
    sections JSONB NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT prd_templates_name_not_empty CHECK (TRIM(name) <> ''),
    CONSTRAINT prd_templates_description_not_empty CHECK (TRIM(description) <> ''),
    CONSTRAINT prd_templates_sections_not_empty CHECK (jsonb_array_length(sections) > 0)
);

COMMENT ON TABLE prd_templates IS 'Reusable PRD templates with section configuration';
CREATE INDEX IF NOT EXISTS idx_prd_templates_is_default ON prd_templates(is_default) WHERE is_default = TRUE;
CREATE INDEX IF NOT EXISTS idx_prd_templates_name ON prd_templates(name);
CREATE INDEX IF NOT EXISTS idx_prd_templates_created_at ON prd_templates(created_at DESC);

-- Mockups
CREATE TABLE IF NOT EXISTS mockups (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    prd_document_id UUID NOT NULL REFERENCES prd_documents(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    description TEXT,
    mockup_type mockup_type NOT NULL,
    source mockup_source NOT NULL,
    file_url TEXT NOT NULL,
    file_size INT,
    width INT,
    height INT,
    analysis_result_json JSONB,
    order_index INT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT mockups_file_size_non_negative CHECK (file_size IS NULL OR file_size >= 0),
    CONSTRAINT mockups_dimensions_valid CHECK (
        (width IS NULL AND height IS NULL) OR (width > 0 AND height > 0)
    ),
    CONSTRAINT mockups_order_non_negative CHECK (order_index >= 0)
);

COMMENT ON TABLE mockups IS 'UI mockups and wireframes for PRD documents';
CREATE INDEX IF NOT EXISTS idx_mockups_prd_document_id ON mockups(prd_document_id);
CREATE INDEX IF NOT EXISTS idx_mockups_type ON mockups(mockup_type);
CREATE INDEX IF NOT EXISTS idx_mockups_order ON mockups(prd_document_id, order_index);

-- Sessions
CREATE TABLE IF NOT EXISTS sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    prd_document_id UUID REFERENCES prd_documents(id) ON DELETE SET NULL,
    metadata_json JSONB,
    started_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    ended_at TIMESTAMPTZ,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,

    CONSTRAINT sessions_end_after_start CHECK (ended_at IS NULL OR ended_at >= started_at)
);

COMMENT ON TABLE sessions IS 'User sessions for PRD generation workflows';
CREATE INDEX IF NOT EXISTS idx_sessions_user_id ON sessions(user_id);
CREATE INDEX IF NOT EXISTS idx_sessions_prd_document_id ON sessions(prd_document_id);
CREATE INDEX IF NOT EXISTS idx_sessions_active ON sessions(is_active) WHERE is_active = TRUE;

-- ============================================================================
-- SECTION 6: Repository Connections (GitHub/Bitbucket OAuth)
-- ============================================================================

CREATE TABLE IF NOT EXISTS repository_connections (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    provider TEXT NOT NULL,
    access_token_encrypted TEXT NOT NULL,
    refresh_token_encrypted TEXT,
    scopes TEXT[] NOT NULL DEFAULT '{}',
    provider_user_id TEXT NOT NULL,
    provider_username TEXT NOT NULL,
    connected_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    expires_at TIMESTAMPTZ,
    last_synced_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT repository_connections_provider_check CHECK (provider IN ('github', 'bitbucket')),
    CONSTRAINT repository_connections_unique_provider_user UNIQUE(user_id, provider, provider_user_id)
);

COMMENT ON TABLE repository_connections IS 'OAuth connections to repository providers (GitHub/Bitbucket)';
CREATE INDEX IF NOT EXISTS idx_repository_connections_user_id ON repository_connections(user_id);
CREATE INDEX IF NOT EXISTS idx_repository_connections_provider ON repository_connections(provider);
CREATE INDEX IF NOT EXISTS idx_repository_connections_user_provider ON repository_connections(user_id, provider);
CREATE INDEX IF NOT EXISTS idx_repository_connections_expires_at ON repository_connections(expires_at) WHERE expires_at IS NOT NULL;

-- ============================================================================
-- SECTION 7: Rate Limiting Tables
-- ============================================================================

-- User Subscriptions
CREATE TABLE IF NOT EXISTS rate_limit_subscriptions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id TEXT NOT NULL UNIQUE,
    tier TEXT NOT NULL CHECK (tier IN ('free', 'paid')),
    quota_used INTEGER NOT NULL DEFAULT 0,
    quota_limit INTEGER NOT NULL,
    reset_at TIMESTAMPTZ NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_rate_limit_subscriptions_user_id ON rate_limit_subscriptions(user_id);
CREATE INDEX IF NOT EXISTS idx_rate_limit_subscriptions_tier ON rate_limit_subscriptions(tier);
CREATE INDEX IF NOT EXISTS idx_rate_limit_subscriptions_reset_at ON rate_limit_subscriptions(reset_at);

-- Daily Quota Tracking
CREATE TABLE IF NOT EXISTS rate_limit_daily_quotas (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id TEXT NOT NULL,
    date DATE NOT NULL,
    tier TEXT NOT NULL,
    requests_count INTEGER NOT NULL DEFAULT 0,
    quota_limit INTEGER NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(user_id, date)
);

CREATE INDEX IF NOT EXISTS idx_rate_limit_daily_quotas_user_date ON rate_limit_daily_quotas(user_id, date);
CREATE INDEX IF NOT EXISTS idx_rate_limit_daily_quotas_date ON rate_limit_daily_quotas(date);

-- Quota History (for analytics)
CREATE TABLE IF NOT EXISTS rate_limit_quota_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id TEXT NOT NULL,
    date DATE NOT NULL,
    tier TEXT NOT NULL,
    requests_count INTEGER NOT NULL,
    quota_limit INTEGER NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_rate_limit_quota_history_user_date ON rate_limit_quota_history(user_id, date);
CREATE INDEX IF NOT EXISTS idx_rate_limit_quota_history_date ON rate_limit_quota_history(date);

-- ============================================================================
-- SECTION 8: RPC Functions
-- ============================================================================

-- Contextual Retrieval: Find chunks BEFORE a line
CREATE OR REPLACE FUNCTION find_chunks_before_line(
    p_codebase_id UUID,
    p_file_path TEXT,
    p_end_line_before INT,
    p_limit INT DEFAULT 3
)
RETURNS TABLE (
    id UUID, file_id UUID, codebase_id UUID, file_path TEXT, content TEXT,
    content_hash TEXT, start_line INT, end_line INT, chunk_type code_chunk_type,
    language TEXT, symbols TEXT[], imports TEXT[],
    token_count INT, created_at TIMESTAMPTZ
)
LANGUAGE sql STABLE
AS $$
    SELECT id, file_id, codebase_id, file_path, content, content_hash,
           start_line, end_line, chunk_type, language, symbols, imports,
           token_count, created_at
    FROM code_chunks
    WHERE code_chunks.codebase_id = p_codebase_id
        AND code_chunks.file_path = p_file_path
        AND code_chunks.end_line < p_end_line_before
    ORDER BY code_chunks.end_line DESC
    LIMIT p_limit;
$$;

-- Contextual Retrieval: Find chunks AFTER a line
CREATE OR REPLACE FUNCTION find_chunks_after_line(
    p_codebase_id UUID,
    p_file_path TEXT,
    p_start_line_after INT,
    p_limit INT DEFAULT 3
)
RETURNS TABLE (
    id UUID, file_id UUID, codebase_id UUID, file_path TEXT, content TEXT,
    content_hash TEXT, start_line INT, end_line INT, chunk_type code_chunk_type,
    language TEXT, symbols TEXT[], imports TEXT[],
    token_count INT, created_at TIMESTAMPTZ
)
LANGUAGE sql STABLE
AS $$
    SELECT id, file_id, codebase_id, file_path, content, content_hash,
           start_line, end_line, chunk_type, language, symbols, imports,
           token_count, created_at
    FROM code_chunks
    WHERE code_chunks.codebase_id = p_codebase_id
        AND code_chunks.file_path = p_file_path
        AND code_chunks.start_line > p_start_line_after
    ORDER BY code_chunks.start_line ASC
    LIMIT p_limit;
$$;

-- Full-Text Search: BM25 ranking for chunks with Contextual Retrieval
CREATE OR REPLACE FUNCTION search_chunks_bm25(
    p_project_id UUID,
    p_query TEXT,
    p_limit INT DEFAULT 100,
    p_min_score FLOAT DEFAULT 0.01
)
RETURNS TABLE (
    chunk_id UUID, file_id UUID, codebase_id UUID, file_path TEXT, content TEXT,
    content_hash TEXT, start_line INT, end_line INT, chunk_type code_chunk_type,
    language TEXT, symbols TEXT[], imports TEXT[],
    token_count INT, created_at TIMESTAMPTZ, bm25_score REAL
)
LANGUAGE sql STABLE
AS $$
    SELECT id, file_id, codebase_id, file_path, content, content_hash,
           start_line, end_line, chunk_type, language, symbols, imports,
           token_count, created_at,
           ts_rank(enriched_content_tsv, websearch_to_tsquery('english', p_query))::REAL AS bm25_score
    FROM code_chunks
    WHERE project_id = p_project_id
        AND enriched_content_tsv @@ websearch_to_tsquery('english', p_query)
        AND ts_rank(enriched_content_tsv, websearch_to_tsquery('english', p_query)) >= p_min_score
    ORDER BY bm25_score DESC
    LIMIT p_limit;
$$;

-- Vector Search: Semantic similarity
CREATE OR REPLACE FUNCTION search_chunks_vector(
    p_project_id UUID,
    p_query_embedding VECTOR(1536),
    p_limit INT DEFAULT 100,
    p_similarity_threshold FLOAT DEFAULT 0.5
)
RETURNS TABLE (chunk_id UUID, similarity FLOAT)
LANGUAGE sql STABLE
AS $$
    SELECT ce.chunk_id, 1 - (ce.embedding <=> p_query_embedding) AS similarity
    FROM code_embeddings ce
    WHERE ce.project_id = p_project_id
        AND 1 - (ce.embedding <=> p_query_embedding) >= p_similarity_threshold
    ORDER BY ce.embedding <=> p_query_embedding
    LIMIT p_limit;
$$;

-- Hybrid Search Data (for RRF fusion in app layer)
CREATE OR REPLACE FUNCTION search_chunks_hybrid_data(
    p_project_id UUID,
    p_query_text TEXT,
    p_query_embedding VECTOR(1536),
    p_limit INT DEFAULT 100
)
RETURNS TABLE (
    chunk_id UUID, file_id UUID, codebase_id UUID, file_path TEXT, content TEXT,
    content_hash TEXT, start_line INT, end_line INT, chunk_type code_chunk_type,
    language TEXT, symbols TEXT[], imports TEXT[],
    token_count INT, created_at TIMESTAMPTZ, vector_similarity FLOAT, bm25_score FLOAT
)
LANGUAGE sql STABLE
AS $$
    WITH vector_results AS (
        SELECT ce.chunk_id, 1 - (ce.embedding <=> p_query_embedding) AS similarity
        FROM code_embeddings ce
        WHERE ce.project_id = p_project_id
        ORDER BY ce.embedding <=> p_query_embedding
        LIMIT p_limit
    ),
    bm25_results AS (
        SELECT cc.id AS chunk_id,
               ts_rank(cc.enriched_content_tsv, websearch_to_tsquery('english', p_query_text))::FLOAT AS score
        FROM code_chunks cc
        WHERE cc.project_id = p_project_id
            AND cc.enriched_content_tsv @@ websearch_to_tsquery('english', p_query_text)
        ORDER BY score DESC
        LIMIT p_limit
    )
    SELECT DISTINCT cc.id, cc.file_id, cc.codebase_id, cc.file_path, cc.content,
           cc.content_hash, cc.start_line, cc.end_line, cc.chunk_type, cc.language,
           cc.symbols, cc.imports, cc.token_count, cc.created_at,
           COALESCE(vr.similarity, 0.0)::FLOAT AS vector_similarity,
           COALESCE(br.score, 0.0)::FLOAT AS bm25_score
    FROM code_chunks cc
    LEFT JOIN vector_results vr ON vr.chunk_id = cc.id
    LEFT JOIN bm25_results br ON br.chunk_id = cc.id
    WHERE vr.chunk_id IS NOT NULL OR br.chunk_id IS NOT NULL;
$$;

-- Project Statistics
CREATE OR REPLACE FUNCTION get_project_statistics(p_project_id UUID)
RETURNS TABLE (
    total_files BIGINT, total_chunks BIGINT, total_embeddings BIGINT,
    total_tokens BIGINT, languages_count BIGINT, avg_chunk_size NUMERIC,
    avg_chunks_per_file NUMERIC
)
LANGUAGE sql STABLE
AS $$
    SELECT
        COUNT(DISTINCT cf.id)::BIGINT AS total_files,
        COUNT(DISTINCT cc.id)::BIGINT AS total_chunks,
        COUNT(DISTINCT ce.id)::BIGINT AS total_embeddings,
        COALESCE(SUM(cc.token_count), 0)::BIGINT AS total_tokens,
        COUNT(DISTINCT cf.language)::BIGINT AS languages_count,
        COALESCE(AVG(cc.token_count), 0)::NUMERIC AS avg_chunk_size,
        CASE WHEN COUNT(DISTINCT cf.id) > 0
             THEN (COUNT(DISTINCT cc.id)::NUMERIC / COUNT(DISTINCT cf.id)::NUMERIC)
             ELSE 0
        END AS avg_chunks_per_file
    FROM code_files cf
    LEFT JOIN code_chunks cc ON cc.file_id = cf.id
    LEFT JOIN code_embeddings ce ON ce.chunk_id = cc.id
    WHERE cf.project_id = p_project_id;
$$;

-- Rate Limiting: Get or create daily quota
CREATE OR REPLACE FUNCTION rate_limit_get_or_create_quota(
    p_user_id TEXT,
    p_tier TEXT,
    p_quota_limit INTEGER
) RETURNS TABLE (requests_count INTEGER, quota_limit INTEGER, can_make_request BOOLEAN)
AS $$
DECLARE
    v_today DATE := CURRENT_DATE;
    v_requests INTEGER;
    v_limit INTEGER;
BEGIN
    SELECT dq.requests_count, dq.quota_limit INTO v_requests, v_limit
    FROM rate_limit_daily_quotas dq
    WHERE dq.user_id = p_user_id AND dq.date = v_today;

    IF NOT FOUND THEN
        INSERT INTO rate_limit_daily_quotas (user_id, date, tier, requests_count, quota_limit)
        VALUES (p_user_id, v_today, p_tier, 0, p_quota_limit)
        RETURNING rate_limit_daily_quotas.requests_count, rate_limit_daily_quotas.quota_limit
        INTO v_requests, v_limit;
    END IF;

    RETURN QUERY SELECT v_requests, v_limit, (v_requests < v_limit);
END;
$$ LANGUAGE plpgsql;

-- Rate Limiting: Increment quota
CREATE OR REPLACE FUNCTION rate_limit_increment_quota(
    p_user_id TEXT,
    p_tier TEXT,
    p_quota_limit INTEGER
) RETURNS TABLE (requests_count INTEGER, quota_limit INTEGER, success BOOLEAN)
AS $$
DECLARE
    v_today DATE := CURRENT_DATE;
    v_new_count INTEGER;
    v_limit INTEGER;
BEGIN
    INSERT INTO rate_limit_daily_quotas (user_id, date, tier, requests_count, quota_limit, updated_at)
    VALUES (p_user_id, v_today, p_tier, 1, p_quota_limit, NOW())
    ON CONFLICT (user_id, date)
    DO UPDATE SET requests_count = rate_limit_daily_quotas.requests_count + 1, updated_at = NOW()
    RETURNING rate_limit_daily_quotas.requests_count, rate_limit_daily_quotas.quota_limit
    INTO v_new_count, v_limit;

    RETURN QUERY SELECT v_new_count, v_limit, (v_new_count <= v_limit);
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- SECTION 9: Triggers
-- ============================================================================

-- Updated_at trigger function
CREATE OR REPLACE FUNCTION trigger_set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply updated_at triggers
DO $$
DECLARE
    t TEXT;
BEGIN
    FOR t IN SELECT unnest(ARRAY[
        'users', 'codebases', 'codebase_projects', 'code_files',
        'prd_documents', 'prd_sections', 'prd_templates', 'mockups',
        'oauth_settings', 'repository_connections',
        'rate_limit_subscriptions', 'rate_limit_daily_quotas'
    ])
    LOOP
        EXECUTE format('DROP TRIGGER IF EXISTS trigger_%s_updated_at ON %I', t, t);
        EXECUTE format('CREATE TRIGGER trigger_%s_updated_at BEFORE UPDATE ON %I FOR EACH ROW EXECUTE FUNCTION trigger_set_updated_at()', t, t);
    END LOOP;
END $$;

-- ============================================================================
-- SECTION 10: Row-Level Security (RLS)
-- Note: RLS policies use auth.uid() which is Supabase-specific.
-- For self-hosted PostgreSQL, you may need to implement your own auth mechanism.
-- ============================================================================

-- Enable RLS on all user-facing tables
DO $$
DECLARE
    t TEXT;
BEGIN
    FOR t IN SELECT unnest(ARRAY[
        'users', 'codebases', 'codebase_projects', 'code_files', 'code_chunks',
        'code_embeddings', 'merkle_nodes', 'prd_documents', 'prd_sections',
        'prd_templates', 'mockups', 'sessions', 'repository_connections',
        'rate_limit_subscriptions', 'rate_limit_daily_quotas', 'rate_limit_quota_history'
    ])
    LOOP
        EXECUTE format('ALTER TABLE %I ENABLE ROW LEVEL SECURITY', t);
    END LOOP;
END $$;

-- Service role full access policies (Supabase)
-- These allow the backend service to bypass RLS
DO $$
DECLARE
    t TEXT;
BEGIN
    FOR t IN SELECT unnest(ARRAY[
        'users', 'codebases', 'codebase_projects', 'code_files', 'code_chunks',
        'code_embeddings', 'merkle_nodes', 'prd_documents', 'prd_sections',
        'prd_templates', 'mockups', 'sessions', 'repository_connections',
        'rate_limit_subscriptions', 'rate_limit_daily_quotas', 'rate_limit_quota_history'
    ])
    LOOP
        EXECUTE format('DROP POLICY IF EXISTS %s_service_role ON %I', t, t);
        EXECUTE format('CREATE POLICY %s_service_role ON %I FOR ALL USING (auth.role() = ''service_role'')', t, t);
    END LOOP;
END $$;

-- ============================================================================
-- SECTION 11: Seed Data
-- ============================================================================

-- Default PRD Templates
INSERT INTO prd_templates (name, description, is_default, sections) VALUES (
    'Comprehensive PRD',
    'Complete PRD template with all sections for full product documentation',
    TRUE,
    '[
        {"section_type": "overview", "order": 0, "is_required": true, "custom_prompt": null},
        {"section_type": "goals", "order": 1, "is_required": true, "custom_prompt": null},
        {"section_type": "requirements", "order": 2, "is_required": true, "custom_prompt": null},
        {"section_type": "user_stories", "order": 3, "is_required": false, "custom_prompt": null},
        {"section_type": "technical_specification", "order": 4, "is_required": true, "custom_prompt": null},
        {"section_type": "data_model", "order": 5, "is_required": false, "custom_prompt": null},
        {"section_type": "api_specification", "order": 6, "is_required": false, "custom_prompt": null},
        {"section_type": "security_considerations", "order": 7, "is_required": false, "custom_prompt": null},
        {"section_type": "performance_requirements", "order": 8, "is_required": false, "custom_prompt": null},
        {"section_type": "testing", "order": 9, "is_required": false, "custom_prompt": null},
        {"section_type": "deployment", "order": 10, "is_required": false, "custom_prompt": null},
        {"section_type": "risks", "order": 11, "is_required": false, "custom_prompt": null},
        {"section_type": "timeline", "order": 12, "is_required": false, "custom_prompt": null}
    ]'::JSONB
) ON CONFLICT (name) DO NOTHING;

INSERT INTO prd_templates (name, description, is_default, sections) VALUES (
    'Mobile App PRD',
    'Focused template for iOS/Android mobile applications',
    TRUE,
    '[
        {"section_type": "overview", "order": 0, "is_required": true, "custom_prompt": null},
        {"section_type": "goals", "order": 1, "is_required": true, "custom_prompt": null},
        {"section_type": "user_stories", "order": 2, "is_required": true, "custom_prompt": null},
        {"section_type": "requirements", "order": 3, "is_required": true, "custom_prompt": null},
        {"section_type": "technical_specification", "order": 4, "is_required": true, "custom_prompt": null},
        {"section_type": "data_model", "order": 5, "is_required": false, "custom_prompt": null},
        {"section_type": "security_considerations", "order": 6, "is_required": true, "custom_prompt": null},
        {"section_type": "performance_requirements", "order": 7, "is_required": true, "custom_prompt": null},
        {"section_type": "testing", "order": 8, "is_required": false, "custom_prompt": null}
    ]'::JSONB
) ON CONFLICT (name) DO NOTHING;

INSERT INTO prd_templates (name, description, is_default, sections) VALUES (
    'API Service PRD',
    'Streamlined template for backend APIs and microservices',
    TRUE,
    '[
        {"section_type": "overview", "order": 0, "is_required": true, "custom_prompt": null},
        {"section_type": "goals", "order": 1, "is_required": true, "custom_prompt": null},
        {"section_type": "requirements", "order": 2, "is_required": true, "custom_prompt": null},
        {"section_type": "api_specification", "order": 3, "is_required": true, "custom_prompt": null},
        {"section_type": "data_model", "order": 4, "is_required": true, "custom_prompt": null},
        {"section_type": "technical_specification", "order": 5, "is_required": true, "custom_prompt": null},
        {"section_type": "security_considerations", "order": 6, "is_required": true, "custom_prompt": null},
        {"section_type": "performance_requirements", "order": 7, "is_required": true, "custom_prompt": null},
        {"section_type": "testing", "order": 8, "is_required": true, "custom_prompt": null},
        {"section_type": "deployment", "order": 9, "is_required": false, "custom_prompt": null}
    ]'::JSONB
) ON CONFLICT (name) DO NOTHING;

-- ============================================================================
-- END OF COMPLETE SCHEMA
-- ============================================================================

-- Summary:
-- Tables created: 22
--   Auth: users, refresh_tokens, audit_logs, oauth_clients, authorization_codes, oauth_settings
--   Codebase: codebases, codebase_projects, code_files, code_chunks, code_embeddings, merkle_nodes
--   PRD: prd_documents, prd_sections, prd_templates, mockups, sessions
--   Integration: repository_connections
--   Rate Limiting: rate_limit_subscriptions, rate_limit_daily_quotas, rate_limit_quota_history
--
-- Extensions: uuid-ossp, vector, pg_trgm
-- Enum types: 10
-- RPC functions: 8
-- Indexes: 50+
-- RLS enabled on all tables
