--JMJ
-- Migration: v2 → v3
-- Adds facility_names table, relationships, new types
-- Preserves existing data

-- ============================================================================
-- 1. Create facility_names table
-- ============================================================================
CREATE TABLE IF NOT EXISTS facility_names (
    facility_id UUID PRIMARY KEY REFERENCES facilities(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    name_hash TEXT UNIQUE NOT NULL,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_facility_names_hash ON facility_names(name_hash);

-- ============================================================================
-- 2. Migrate existing facility names
-- ============================================================================
INSERT INTO facility_names (facility_id, name, name_hash)
SELECT 
    id,
    name,
    encode(digest(lower(trim(name)), 'sha256'), 'hex')
FROM facilities
WHERE name IS NOT NULL
ON CONFLICT (facility_id) DO NOTHING;

-- ============================================================================
-- 3. Add new columns to facilities
-- ============================================================================
ALTER TABLE facilities ADD COLUMN IF NOT EXISTS parent_facility_id UUID REFERENCES facilities(id);
ALTER TABLE facilities ADD COLUMN IF NOT EXISTS billing_entity_id UUID REFERENCES facilities(id);
ALTER TABLE facilities ADD COLUMN IF NOT EXISTS independent BOOLEAN DEFAULT true;
ALTER TABLE facilities ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP DEFAULT NOW();

CREATE INDEX IF NOT EXISTS idx_facilities_parent ON facilities(parent_facility_id);
CREATE INDEX IF NOT EXISTS idx_facilities_billing ON facilities(billing_entity_id);

-- ============================================================================
-- 4. Add validation flag to bills
-- ============================================================================
ALTER TABLE bills ADD COLUMN IF NOT EXISTS totals_validated BOOLEAN DEFAULT false;

CREATE INDEX IF NOT EXISTS idx_bills_validated ON bills(totals_validated);

-- ============================================================================
-- 5. Update facilities type constraint to include new types
-- ============================================================================
-- This is tricky - PostgreSQL doesn't let you easily modify CHECK constraints
-- Drop the old constraint and add new one

ALTER TABLE facilities DROP CONSTRAINT IF EXISTS facilities_type_check;

ALTER TABLE facilities ADD CONSTRAINT facilities_type_check CHECK (type IN (
    'academic', 'community', 'imaging_center', 'urgent_care', 
    'clinic', 'lab', 'surgery_center',
    'dme_supplier', 'pharmacy', 'medical_supply', 'vendor',
    'other'
));

-- ============================================================================
-- 6. Update region constraint
-- ============================================================================
ALTER TABLE facilities DROP CONSTRAINT IF EXISTS facilities_region_check;

ALTER TABLE facilities ADD CONSTRAINT facilities_region_check CHECK (
    region IN ('West', 'Southwest', 'Midwest', 'Southeast', 'Northeast')
);

-- ============================================================================
-- 7. Recreate pricing_intelligence view with new fields
-- ============================================================================
DROP VIEW IF EXISTS pricing_intelligence;

CREATE VIEW pricing_intelligence AS
SELECT 
    li.id as line_item_id,
    li.procedure_code,
    li.code_type,
    li.procedure_name,
    li.procedure_category,
    li.amount_billed,
    li.amount_paid,
    li.patient_responsibility,
    li.denial_reason,
    li.included_in_bundle,
    b.facility_type,
    b.metro_area,
    b.region,
    b.state,
    b.date_month,
    b.insurance_type,
    f.teaching_hospital,
    f.size as facility_size,
    f.parent_facility_id,
    f.independent
FROM line_items li
JOIN bills b ON li.bill_id = b.id
JOIN facilities f ON b.facility_id = f.id
WHERE b.published = true
  AND b.totals_validated = true;

-- ============================================================================
-- Verify migration
-- ============================================================================
SELECT 
    'Migration complete!' as status,
    (SELECT COUNT(*) FROM facilities) as facility_count,
    (SELECT COUNT(*) FROM facility_names) as facility_names_count,
    (SELECT COUNT(*) FROM bills) as bill_count,
    (SELECT COUNT(*) FROM line_items) as line_item_count;

-- Show your facilities with names
SELECT 
    f.id,
    fn.name,
    f.type,
    f.metro_area,
    f.independent
FROM facilities f
JOIN facility_names fn ON f.id = fn.facility_id
ORDER BY fn.name;
