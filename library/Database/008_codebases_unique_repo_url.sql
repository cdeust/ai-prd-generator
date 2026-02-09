-- Migration: Add unique constraint on codebases (user_id, repository_url)
-- Prevents duplicate codebases for the same repository per user

-- Add unique constraint (user can only have one codebase per repository URL)
ALTER TABLE codebases
ADD CONSTRAINT codebases_unique_user_repo_url
UNIQUE (user_id, repository_url);

-- Create index for faster lookups by repository_url
CREATE INDEX IF NOT EXISTS idx_codebases_repository_url
ON codebases(repository_url)
WHERE repository_url IS NOT NULL;
