-- Fix repository_connections table for GitHub/Bitbucket OAuth
-- Run this in Supabase SQL Editor

-- 1. Drop foreign key constraint (GitHub OAuth users don't need entry in users table)
ALTER TABLE repository_connections
DROP CONSTRAINT IF EXISTS fk_repository_connections_user;

-- 2. Drop old unique constraint
ALTER TABLE repository_connections
DROP CONSTRAINT IF EXISTS repository_connections_unique_provider_user;

-- 3. Add new unique constraint (one connection per provider user per provider)
ALTER TABLE repository_connections
DROP CONSTRAINT IF EXISTS repository_connections_unique_provider;

ALTER TABLE repository_connections
ADD CONSTRAINT repository_connections_unique_provider
UNIQUE(provider, provider_user_id);

-- 4. Drop old RLS policies
DROP POLICY IF EXISTS repository_connections_crud_own ON repository_connections;
DROP POLICY IF EXISTS repository_connections_service_role ON repository_connections;
DROP POLICY IF EXISTS repository_connections_backend_access ON repository_connections;

-- 5. Add permissive RLS policy for backend access
CREATE POLICY repository_connections_backend_access
    ON repository_connections FOR ALL
    TO anon
    USING (true)
    WITH CHECK (true);

CREATE POLICY repository_connections_service_role
    ON repository_connections FOR ALL
    TO service_role
    USING (true)
    WITH CHECK (true);

-- 6. Add index for provider_user_id lookups
CREATE INDEX IF NOT EXISTS idx_repository_connections_provider_user_id
    ON repository_connections(provider_user_id);

SELECT 'Fix applied successfully' as status;
