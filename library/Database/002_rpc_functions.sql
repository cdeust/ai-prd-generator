-- RPC Functions for AI PRD System
-- Optimized database-level queries for performance-critical operations

-- ============================================================================
-- 1. CONTEXTUAL RETRIEVAL - Find chunks in file by line range
-- ============================================================================

-- Find chunks BEFORE a given line (for context expansion)
CREATE OR REPLACE FUNCTION find_chunks_before_line(
    p_codebase_id uuid,
    p_file_path text,
    p_end_line_before int,
    p_limit int DEFAULT 3
)
RETURNS TABLE (
    id uuid,
    file_id uuid,
    codebase_id uuid,
    file_path text,
    content text,
    content_hash text,
    start_line int,
    end_line int,
    chunk_type code_chunk_type,
    language text,
    symbols text[],
    imports text[],
    token_count int,
    created_at timestamptz
)
LANGUAGE sql
STABLE
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

-- Find chunks AFTER a given line (for context expansion)
CREATE OR REPLACE FUNCTION find_chunks_after_line(
    p_codebase_id uuid,
    p_file_path text,
    p_start_line_after int,
    p_limit int DEFAULT 3
)
RETURNS TABLE (
    id uuid,
    file_id uuid,
    codebase_id uuid,
    file_path text,
    content text,
    content_hash text,
    start_line int,
    end_line int,
    chunk_type code_chunk_type,
    language text,
    symbols text[],
    imports text[],
    token_count int,
    created_at timestamptz
)
LANGUAGE sql
STABLE
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

-- ============================================================================
-- 2. FULL-TEXT SEARCH - BM25 ranking with ts_rank
-- ============================================================================

CREATE OR REPLACE FUNCTION search_chunks_bm25(
    p_project_id uuid,
    p_query text,
    p_limit int DEFAULT 100,
    p_min_score float DEFAULT 0.01
)
RETURNS TABLE (
    chunk_id uuid,
    file_id uuid,
    codebase_id uuid,
    file_path text,
    content text,
    content_hash text,
    start_line int,
    end_line int,
    chunk_type code_chunk_type,
    language text,
    symbols text[],
    imports text[],
    token_count int,
    created_at timestamptz,
    bm25_score real
)
LANGUAGE sql
STABLE
AS $$
    SELECT
        id, file_id, codebase_id, file_path, content, content_hash,
        start_line, end_line, chunk_type, language, symbols, imports,
        token_count, created_at,
        ts_rank(content_tsv, websearch_to_tsquery('english', p_query))::real AS bm25_score
    FROM code_chunks
    WHERE project_id = p_project_id
        AND content_tsv @@ websearch_to_tsquery('english', p_query)
        AND ts_rank(content_tsv, websearch_to_tsquery('english', p_query)) >= p_min_score
    ORDER BY bm25_score DESC
    LIMIT p_limit;
$$;

COMMENT ON FUNCTION search_chunks_bm25 IS 'Full-text search with BM25 ranking using ts_rank';

-- File-level full-text search
CREATE OR REPLACE FUNCTION search_files_bm25(
    p_project_id uuid,
    p_query text,
    p_limit int DEFAULT 50,
    p_min_score float DEFAULT 0.01
)
RETURNS TABLE (
    file_id uuid,
    codebase_id uuid,
    file_path text,
    file_hash text,
    file_size int,
    language text,
    is_parsed boolean,
    parse_error text,
    created_at timestamptz,
    updated_at timestamptz,
    bm25_score real
)
LANGUAGE sql
STABLE
AS $$
    SELECT
        id, codebase_id, file_path, file_hash, file_size,
        language, is_parsed, parse_error, created_at, updated_at,
        ts_rank(file_path_tsv, websearch_to_tsquery('english', p_query))::real AS bm25_score
    FROM code_files
    WHERE project_id = p_project_id
        AND file_path_tsv @@ websearch_to_tsquery('english', p_query)
        AND ts_rank(file_path_tsv, websearch_to_tsquery('english', p_query)) >= p_min_score
    ORDER BY bm25_score DESC
    LIMIT p_limit;
$$;

COMMENT ON FUNCTION search_files_bm25 IS 'Full-text search on file paths with BM25 ranking';

-- ============================================================================
-- 3. VECTOR SEARCH - Optimized semantic search
-- ============================================================================

CREATE OR REPLACE FUNCTION search_chunks_vector(
    p_project_id uuid,
    p_query_embedding vector(1536),
    p_limit int DEFAULT 100,
    p_similarity_threshold float DEFAULT 0.5
)
RETURNS TABLE (
    chunk_id uuid,
    similarity float
)
LANGUAGE sql
STABLE
AS $$
    SELECT
        ce.chunk_id,
        1 - (ce.embedding <=> p_query_embedding) AS similarity
    FROM code_embeddings ce
    WHERE ce.project_id = p_project_id
        AND 1 - (ce.embedding <=> p_query_embedding) >= p_similarity_threshold
    ORDER BY ce.embedding <=> p_query_embedding
    LIMIT p_limit;
$$;

COMMENT ON FUNCTION search_chunks_vector IS 'Vector similarity search using cosine distance';

-- ============================================================================
-- 4. HYBRID SEARCH - Combine vector + BM25 (RRF)
-- ============================================================================

-- Note: RRF fusion happens in application layer for flexibility
-- This function provides raw data for hybrid search

CREATE OR REPLACE FUNCTION search_chunks_hybrid_data(
    p_project_id uuid,
    p_query_text text,
    p_query_embedding vector(1536),
    p_limit int DEFAULT 100
)
RETURNS TABLE (
    chunk_id uuid,
    file_id uuid,
    codebase_id uuid,
    file_path text,
    content text,
    content_hash text,
    start_line int,
    end_line int,
    chunk_type code_chunk_type,
    language text,
    symbols text[],
    imports text[],
    token_count int,
    created_at timestamptz,
    vector_similarity float,
    bm25_score float
)
LANGUAGE sql
STABLE
AS $$
    WITH vector_results AS (
        SELECT
            ce.chunk_id,
            1 - (ce.embedding <=> p_query_embedding) AS similarity
        FROM code_embeddings ce
        WHERE ce.project_id = p_project_id
        ORDER BY ce.embedding <=> p_query_embedding
        LIMIT p_limit
    ),
    bm25_results AS (
        SELECT
            cc.id AS chunk_id,
            ts_rank(cc.content_tsv, websearch_to_tsquery('english', p_query_text))::float AS score
        FROM code_chunks cc
        WHERE cc.project_id = p_project_id
            AND cc.content_tsv @@ websearch_to_tsquery('english', p_query_text)
        ORDER BY score DESC
        LIMIT p_limit
    )
    SELECT DISTINCT
        cc.id,
        cc.file_id,
        cc.codebase_id,
        cc.file_path,
        cc.content,
        cc.content_hash,
        cc.start_line,
        cc.end_line,
        cc.chunk_type,
        cc.language,
        cc.symbols,
        cc.imports,
        cc.token_count,
        cc.created_at,
        COALESCE(vr.similarity, 0.0)::float AS vector_similarity,
        COALESCE(br.score, 0.0)::float AS bm25_score
    FROM code_chunks cc
    LEFT JOIN vector_results vr ON vr.chunk_id = cc.id
    LEFT JOIN bm25_results br ON br.chunk_id = cc.id
    WHERE vr.chunk_id IS NOT NULL OR br.chunk_id IS NOT NULL;
$$;

COMMENT ON FUNCTION search_chunks_hybrid_data IS 'Provides data for hybrid search (app does RRF fusion)';

-- ============================================================================
-- 5. STATISTICS & MONITORING
-- ============================================================================

CREATE OR REPLACE FUNCTION get_project_statistics(p_project_id uuid)
RETURNS TABLE (
    total_files bigint,
    total_chunks bigint,
    total_embeddings bigint,
    total_tokens bigint,
    languages_count bigint,
    avg_chunk_size numeric,
    avg_chunks_per_file numeric
)
LANGUAGE sql
STABLE
AS $$
    SELECT
        COUNT(DISTINCT cf.id)::bigint AS total_files,
        COUNT(DISTINCT cc.id)::bigint AS total_chunks,
        COUNT(DISTINCT ce.id)::bigint AS total_embeddings,
        COALESCE(SUM(cc.token_count), 0)::bigint AS total_tokens,
        COUNT(DISTINCT cf.language)::bigint AS languages_count,
        COALESCE(AVG(cc.token_count), 0)::numeric AS avg_chunk_size,
        CASE
            WHEN COUNT(DISTINCT cf.id) > 0
            THEN (COUNT(DISTINCT cc.id)::numeric / COUNT(DISTINCT cf.id)::numeric)
            ELSE 0
        END AS avg_chunks_per_file
    FROM code_files cf
    LEFT JOIN code_chunks cc ON cc.file_id = cf.id
    LEFT JOIN code_embeddings ce ON ce.chunk_id = cc.id
    WHERE cf.project_id = p_project_id;
$$;

COMMENT ON FUNCTION get_project_statistics IS 'Get project indexing statistics';

-- ============================================================================
-- 6. CHUNK VALIDATION & INTEGRITY
-- ============================================================================

CREATE OR REPLACE FUNCTION validate_chunk_integrity(p_chunk_id uuid)
RETURNS TABLE (
    is_valid boolean,
    has_embedding boolean,
    has_merkle_node boolean,
    content_matches_hash boolean
)
LANGUAGE sql
STABLE
AS $$
    SELECT
        (cc.id IS NOT NULL) AS is_valid,
        (ce.id IS NOT NULL) AS has_embedding,
        (mn.id IS NOT NULL) AS has_merkle_node,
        (md5(cc.content) = cc.content_hash) AS content_matches_hash
    FROM code_chunks cc
    LEFT JOIN code_embeddings ce ON ce.chunk_id = cc.id
    LEFT JOIN merkle_nodes mn ON mn.chunk_id = cc.id
    WHERE cc.id = p_chunk_id;
$$;

COMMENT ON FUNCTION validate_chunk_integrity IS 'Validate chunk data integrity';

-- ============================================================================
-- GRANTS (Supabase authenticated users)
-- ============================================================================

-- Grant execute permissions to authenticated users
GRANT EXECUTE ON FUNCTION find_chunks_before_line TO authenticated;
GRANT EXECUTE ON FUNCTION find_chunks_after_line TO authenticated;
GRANT EXECUTE ON FUNCTION search_chunks_bm25 TO authenticated;
GRANT EXECUTE ON FUNCTION search_files_bm25 TO authenticated;
GRANT EXECUTE ON FUNCTION search_chunks_vector TO authenticated;
GRANT EXECUTE ON FUNCTION search_chunks_hybrid_data TO authenticated;
GRANT EXECUTE ON FUNCTION get_project_statistics TO authenticated;
GRANT EXECUTE ON FUNCTION validate_chunk_integrity TO authenticated;
