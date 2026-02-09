-- ============================================================================
-- Migration: Fix codebase indexing schema
-- ============================================================================
--
-- This migration fixes the codebase indexing schema to properly support:
-- 1. Codebase → CodebaseProject → CodeFile → CodeChunk hierarchy
-- 2. Architecture pattern recognition for PRD generation
--
-- Run this on existing databases:
--   psql $DATABASE_URL -f library/Database/005_add_codebase_indexing_columns.sql
--
-- ============================================================================

-- Clean up existing data first (cascades to related tables)
TRUNCATE TABLE codebases CASCADE;

-- ============================================================================
-- CODEBASES TABLE: Add missing columns
-- ============================================================================

ALTER TABLE codebases
ADD COLUMN IF NOT EXISTS local_path TEXT;

ALTER TABLE codebases
ADD COLUMN IF NOT EXISTS indexing_status project_indexing_status NOT NULL DEFAULT 'pending';

ALTER TABLE codebases
ADD COLUMN IF NOT EXISTS total_files INT NOT NULL DEFAULT 0;

ALTER TABLE codebases
ADD COLUMN IF NOT EXISTS indexed_files INT NOT NULL DEFAULT 0;

ALTER TABLE codebases
ADD COLUMN IF NOT EXISTS detected_languages TEXT[] NOT NULL DEFAULT '{}';

ALTER TABLE codebases
ADD COLUMN IF NOT EXISTS last_indexed_at TIMESTAMPTZ;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'codebases_files_non_negative'
    ) THEN
        ALTER TABLE codebases
        ADD CONSTRAINT codebases_files_non_negative
        CHECK (total_files >= 0 AND indexed_files >= 0);
    END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_codebases_indexing_status ON codebases(indexing_status);

-- ============================================================================
-- CODEBASE_PROJECTS TABLE: Fix schema to match Swift entities
-- ============================================================================

-- Add detected_frameworks column
ALTER TABLE codebase_projects
ADD COLUMN IF NOT EXISTS detected_frameworks TEXT[] NOT NULL DEFAULT '{}';

-- Add architecture_patterns JSONB column
ALTER TABLE codebase_projects
ADD COLUMN IF NOT EXISTS architecture_patterns JSONB NOT NULL DEFAULT '[]'::jsonb;

-- Rename detected_patterns to detected_frameworks if it exists
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'codebase_projects' AND column_name = 'detected_patterns'
    ) AND NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'codebase_projects' AND column_name = 'detected_frameworks'
    ) THEN
        ALTER TABLE codebase_projects RENAME COLUMN detected_patterns TO detected_frameworks;
    END IF;
END $$;

-- ============================================================================
-- END OF MIGRATION
-- ============================================================================
