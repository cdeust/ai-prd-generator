-- ============================================================================
-- AI PRD System - PRD Templates
-- Migration: 003_prd_templates.sql
-- ============================================================================
--
-- FEATURE: Reusable PRD Template System
-- ✅ Template storage with section configuration
-- ✅ Default template support
-- ✅ Custom prompt overrides per section
-- ✅ Section ordering and required flags
-- ✅ Row-Level Security (RLS)
--
-- ============================================================================

-- ============================================================================
-- TABLES
-- ============================================================================

-- PRD Templates table
CREATE TABLE IF NOT EXISTS prd_templates (
    -- Identity
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

    -- Template metadata
    name TEXT NOT NULL UNIQUE,
    description TEXT NOT NULL,
    is_default BOOLEAN NOT NULL DEFAULT FALSE,

    -- Section configuration (JSONB for flexible structure)
    -- Schema: [{ sectionType, order, isRequired, customPrompt? }]
    sections JSONB NOT NULL,

    -- Timestamps
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    -- Constraints
    CONSTRAINT prd_templates_name_not_empty CHECK (TRIM(name) <> ''),
    CONSTRAINT prd_templates_description_not_empty CHECK (TRIM(description) <> ''),
    CONSTRAINT prd_templates_sections_not_empty CHECK (jsonb_array_length(sections) > 0)
);

COMMENT ON TABLE prd_templates IS 'Reusable PRD templates with section configuration';
COMMENT ON COLUMN prd_templates.id IS 'Unique template identifier';
COMMENT ON COLUMN prd_templates.name IS 'Template name (unique, no length limit)';
COMMENT ON COLUMN prd_templates.description IS 'Template description (no length limit)';
COMMENT ON COLUMN prd_templates.is_default IS 'Whether this is a system default template';
COMMENT ON COLUMN prd_templates.sections IS 'Array of section configurations with type, order, required flag, and optional custom prompt';

-- ============================================================================
-- INDEXES
-- ============================================================================

-- Index for default templates lookup
CREATE INDEX idx_prd_templates_is_default
ON prd_templates(is_default)
WHERE is_default = TRUE;

-- Index for name lookup
CREATE INDEX idx_prd_templates_name
ON prd_templates(name);

-- Index for chronological ordering
CREATE INDEX idx_prd_templates_created_at
ON prd_templates(created_at DESC);

-- ============================================================================
-- ROW-LEVEL SECURITY (RLS)
-- ============================================================================

ALTER TABLE prd_templates ENABLE ROW LEVEL SECURITY;

-- Policy: Allow authenticated users to read all templates
CREATE POLICY "Allow authenticated read access"
ON prd_templates
FOR SELECT
TO authenticated
USING (TRUE);

-- Policy: Allow authenticated users to create templates
CREATE POLICY "Allow authenticated create access"
ON prd_templates
FOR INSERT
TO authenticated
WITH CHECK (TRUE);

-- Policy: Allow authenticated users to update non-default templates
CREATE POLICY "Allow authenticated update access"
ON prd_templates
FOR UPDATE
TO authenticated
USING (is_default = FALSE);

-- Policy: Allow authenticated users to delete non-default templates
CREATE POLICY "Allow authenticated delete access"
ON prd_templates
FOR DELETE
TO authenticated
USING (is_default = FALSE);

-- ============================================================================
-- TRIGGERS
-- ============================================================================

-- Automatically update updated_at timestamp
CREATE OR REPLACE FUNCTION update_prd_templates_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_prd_templates_updated_at
BEFORE UPDATE ON prd_templates
FOR EACH ROW
EXECUTE FUNCTION update_prd_templates_updated_at();

-- ============================================================================
-- SEED DATA: Default Templates
-- ============================================================================

-- Default Template: Comprehensive PRD
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
    ]'::jsonb
) ON CONFLICT (name) DO NOTHING;

-- Default Template: Mobile App PRD
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
    ]'::jsonb
) ON CONFLICT (name) DO NOTHING;

-- Default Template: API Service PRD
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
    ]'::jsonb
) ON CONFLICT (name) DO NOTHING;

-- Default Template: Feature Request PRD
INSERT INTO prd_templates (name, description, is_default, sections) VALUES (
    'Feature Request PRD',
    'Lightweight template for adding new features to existing products',
    TRUE,
    '[
        {"section_type": "overview", "order": 0, "is_required": true, "custom_prompt": null},
        {"section_type": "goals", "order": 1, "is_required": true, "custom_prompt": null},
        {"section_type": "user_stories", "order": 2, "is_required": true, "custom_prompt": null},
        {"section_type": "requirements", "order": 3, "is_required": true, "custom_prompt": null},
        {"section_type": "technical_specification", "order": 4, "is_required": true, "custom_prompt": null},
        {"section_type": "testing", "order": 5, "is_required": false, "custom_prompt": null},
        {"section_type": "risks", "order": 6, "is_required": false, "custom_prompt": null}
    ]'::jsonb
) ON CONFLICT (name) DO NOTHING;

-- ============================================================================
-- VALIDATION FUNCTIONS
-- ============================================================================

-- Validate section configuration structure
CREATE OR REPLACE FUNCTION validate_template_sections(sections_json JSONB)
RETURNS BOOLEAN AS $$
DECLARE
    section JSONB;
    valid_types TEXT[] := ARRAY[
        'overview', 'goals', 'requirements', 'user_stories',
        'technical_specification', 'data_model', 'api_specification',
        'security_considerations', 'performance_requirements',
        'testing', 'deployment', 'risks', 'timeline'
    ];
BEGIN
    -- Check each section has required fields
    FOR section IN SELECT jsonb_array_elements(sections_json)
    LOOP
        -- Must have section_type
        IF NOT (section ? 'section_type') THEN
            RETURN FALSE;
        END IF;

        -- section_type must be valid
        IF NOT (section->>'section_type' = ANY(valid_types)) THEN
            RETURN FALSE;
        END IF;

        -- Must have order
        IF NOT (section ? 'order') THEN
            RETURN FALSE;
        END IF;

        -- Must have is_required
        IF NOT (section ? 'is_required') THEN
            RETURN FALSE;
        END IF;

        -- order must be non-negative integer
        IF (section->>'order')::INT < 0 THEN
            RETURN FALSE;
        END IF;
    END LOOP;

    RETURN TRUE;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

COMMENT ON FUNCTION validate_template_sections IS 'Validates template section configuration structure';

-- Add validation constraint
ALTER TABLE prd_templates
ADD CONSTRAINT prd_templates_valid_sections
CHECK (validate_template_sections(sections));
