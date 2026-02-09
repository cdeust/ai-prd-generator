-- Migration 007: Update prd_section_type enum
-- Add missing section types to match Swift SectionType enum

-- PostgreSQL doesn't allow easy modification of enum types
-- We need to add each new value individually

DO $$ BEGIN
    -- Add new enum values if they don't exist
    ALTER TYPE prd_section_type ADD VALUE IF NOT EXISTS 'goals';
    ALTER TYPE prd_section_type ADD VALUE IF NOT EXISTS 'requirements';
    ALTER TYPE prd_section_type ADD VALUE IF NOT EXISTS 'technical_specification';
    ALTER TYPE prd_section_type ADD VALUE IF NOT EXISTS 'acceptance_criteria';
    ALTER TYPE prd_section_type ADD VALUE IF NOT EXISTS 'security_considerations';
    ALTER TYPE prd_section_type ADD VALUE IF NOT EXISTS 'performance_requirements';
    ALTER TYPE prd_section_type ADD VALUE IF NOT EXISTS 'testing';
    ALTER TYPE prd_section_type ADD VALUE IF NOT EXISTS 'deployment';
    ALTER TYPE prd_section_type ADD VALUE IF NOT EXISTS 'risks';
    ALTER TYPE prd_section_type ADD VALUE IF NOT EXISTS 'timeline';
EXCEPTION WHEN others THEN
    -- Ignore if values already exist (for idempotency)
    NULL;
END $$;

-- Verify the enum values
COMMENT ON TYPE prd_section_type IS 'PRD section types: overview, goals, requirements, user_stories, technical_specification, acceptance_criteria, data_model, api_specification, security_considerations, performance_requirements, testing, deployment, risks, timeline, features, test_specification, constraints, roadmap, validation, other';
