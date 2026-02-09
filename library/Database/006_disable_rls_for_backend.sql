-- ============================================================================
-- Migration: Disable RLS for backend service access
-- ============================================================================
--
-- The backend service uses service_role key but Supabase's auth.role() function
-- doesn't always work correctly with PostgREST. Disabling RLS on backend-only
-- tables since authentication is handled at the application layer.
--
-- Run: psql $DATABASE_URL -f library/Database/006_disable_rls_for_backend.sql
-- Or paste in Supabase Dashboard → SQL Editor
--
-- ============================================================================

-- Disable RLS on codebase tables (backend-only access)
ALTER TABLE codebases DISABLE ROW LEVEL SECURITY;
ALTER TABLE codebase_projects DISABLE ROW LEVEL SECURITY;
ALTER TABLE code_files DISABLE ROW LEVEL SECURITY;
ALTER TABLE code_chunks DISABLE ROW LEVEL SECURITY;
ALTER TABLE code_embeddings DISABLE ROW LEVEL SECURITY;
ALTER TABLE merkle_nodes DISABLE ROW LEVEL SECURITY;

-- Also disable on repository connections (managed by backend)
ALTER TABLE repository_connections DISABLE ROW LEVEL SECURITY;

-- Disable RLS on PRD tables (backend handles authentication)
ALTER TABLE prd_documents DISABLE ROW LEVEL SECURITY;
ALTER TABLE prd_sections DISABLE ROW LEVEL SECURITY;
ALTER TABLE prd_templates DISABLE ROW LEVEL SECURITY;

-- Disable RLS on session tables (backend handles authentication)
ALTER TABLE sessions DISABLE ROW LEVEL SECURITY;

-- Keep RLS enabled on user-facing tables that require it
-- users table keeps RLS for direct user access

-- ============================================================================
-- END OF MIGRATION
-- ============================================================================
