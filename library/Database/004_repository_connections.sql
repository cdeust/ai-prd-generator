-- ============================================================================
-- AI PRD System - Repository Connections Schema
-- Migration: 004_repository_connections.sql
-- ============================================================================
--
-- OAuth connections for GitHub/Bitbucket repository integration
--
-- ============================================================================

-- ============================================================================
-- TABLE: Repository Connections
-- ============================================================================

CREATE TABLE IF NOT EXISTS repository_connections (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id uuid NOT NULL,
    provider text NOT NULL,
    access_token_encrypted text NOT NULL,
    refresh_token_encrypted text,
    scopes text[] NOT NULL DEFAULT '{}',
    provider_user_id text NOT NULL,
    provider_username text NOT NULL,
    connected_at timestamptz NOT NULL DEFAULT now(),
    expires_at timestamptz,
    last_synced_at timestamptz,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),

    -- No foreign key to users - GitHub/Bitbucket OAuth creates standalone connections
    -- User identity is tracked via provider_user_id (GitHub user ID, etc.)

    CONSTRAINT repository_connections_provider_check
        CHECK (provider IN ('github', 'bitbucket')),

    -- Unique constraint: one connection per provider user per provider
    CONSTRAINT repository_connections_unique_provider
        UNIQUE(provider, provider_user_id)
);

COMMENT ON TABLE repository_connections IS 'OAuth connections to repository providers (GitHub/Bitbucket)';
COMMENT ON COLUMN repository_connections.provider IS 'Repository provider (github, bitbucket)';
COMMENT ON COLUMN repository_connections.access_token_encrypted IS 'Encrypted OAuth access token';
COMMENT ON COLUMN repository_connections.refresh_token_encrypted IS 'Encrypted OAuth refresh token';
COMMENT ON COLUMN repository_connections.scopes IS 'Granted OAuth scopes';
COMMENT ON COLUMN repository_connections.provider_user_id IS 'User ID from provider';
COMMENT ON COLUMN repository_connections.provider_username IS 'Username from provider';
COMMENT ON COLUMN repository_connections.expires_at IS 'Token expiration timestamp';
COMMENT ON COLUMN repository_connections.last_synced_at IS 'Last successful sync timestamp';

-- ============================================================================
-- INDEXES
-- ============================================================================

CREATE INDEX IF NOT EXISTS idx_repository_connections_user_id
    ON repository_connections(user_id);

CREATE INDEX IF NOT EXISTS idx_repository_connections_provider
    ON repository_connections(provider);

CREATE INDEX IF NOT EXISTS idx_repository_connections_user_provider
    ON repository_connections(user_id, provider);

CREATE INDEX IF NOT EXISTS idx_repository_connections_expires_at
    ON repository_connections(expires_at)
    WHERE expires_at IS NOT NULL;

-- ============================================================================
-- ROW LEVEL SECURITY
-- ============================================================================

ALTER TABLE repository_connections ENABLE ROW LEVEL SECURITY;

-- Backend service access (anon key from server-side only)
-- This allows the backend to manage connections on behalf of users
CREATE POLICY repository_connections_backend_access
    ON repository_connections FOR ALL
    TO anon
    USING (true)
    WITH CHECK (true);

-- Service role has full access (alternative for stricter security)
CREATE POLICY repository_connections_service_role
    ON repository_connections FOR ALL
    TO service_role
    USING (true)
    WITH CHECK (true);

-- ============================================================================
-- UPDATED_AT TRIGGER
-- ============================================================================

CREATE OR REPLACE FUNCTION update_repository_connections_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER repository_connections_updated_at
    BEFORE UPDATE ON repository_connections
    FOR EACH ROW
    EXECUTE FUNCTION update_repository_connections_updated_at();
