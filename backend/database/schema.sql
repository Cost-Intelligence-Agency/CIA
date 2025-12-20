--JMJ

-- Cost Intelligence Agency - Database Schema v4.0
-- 
-- Changes from v3:
-- - Added procedure_codes table
--
-- Tables: facilities, facility_names, users, bills, line_items, procedure_categories, procedure_codes
-- Views: pricing_intelligence
-- Functions: See functions.sql

-- ============================================================================
-- FACILITIES TABLE (PUBLIC - no names)
-- ============================================================================
CREATE TABLE facilities (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Facility characteristics
    type TEXT NOT NULL CHECK (type IN (
        -- Healthcare facilities
        'academic',           -- University hospitals, teaching hospitals
        'community',          -- Community hospitals
        'imaging_center',     -- Radiology/imaging centers
        'urgent_care',        -- Urgent care clinics
        'clinic',             -- Outpatient clinics, doctor's offices
        'lab',                -- Laboratory facilities
        'surgery_center',     -- Ambulatory surgery centers
        
        -- Vendors/Suppliers
        'dme_supplier',       -- DME equipment suppliers (CPAP, wheelchairs, etc.)
        'pharmacy',           -- Pharmacies
        'medical_supply',     -- Medical supply companies
        'vendor',             -- General medical equipment vendor
        
        -- Other
        'other'
    )),
    
    -- Location
    metro_area TEXT NOT NULL,
    region TEXT NOT NULL CHECK (region IN ('West', 'Southwest', 'Midwest', 'Southeast', 'Northeast')),
    state TEXT NOT NULL,
    
    -- Attributes
    teaching_hospital BOOLEAN DEFAULT false,
    size TEXT CHECK (size IN ('large', 'medium', 'small')),
    
    -- Relationships (for clinic groups, hospital affiliations, etc.)
    parent_facility_id UUID REFERENCES facilities(id),
    billing_entity_id UUID REFERENCES facilities(id),
    independent BOOLEAN DEFAULT true,
    
    -- Metadata
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- ============================================================================
-- FACILITY NAMES TABLE (PRIVATE - will be encrypted)
-- ============================================================================
CREATE TABLE facility_names (
    facility_id UUID PRIMARY KEY REFERENCES facilities(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    name_hash TEXT UNIQUE NOT NULL,  -- SHA256 hash for deduplication without decrypting
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- ============================================================================
-- USERS TABLE (anonymous reputation)
-- ============================================================================
CREATE TABLE users (
    public_key_hash TEXT PRIMARY KEY,
    submissions_count INTEGER DEFAULT 0,
    verified_submissions_count INTEGER DEFAULT 0,
    trust_score DECIMAL(3,2) DEFAULT 0.5 CHECK (trust_score >= 0 AND trust_score <= 1),
    first_seen TIMESTAMP DEFAULT NOW(),
    last_active TIMESTAMP DEFAULT NOW(),
    flags_received INTEGER DEFAULT 0
);

-- ============================================================================
-- BILLS TABLE
-- ============================================================================
CREATE TABLE bills (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_public_key_hash TEXT REFERENCES users(public_key_hash),
    signature TEXT,
    
    -- Bill metadata
    facility_id UUID REFERENCES facilities(id),
    facility_type TEXT NOT NULL,  -- Denormalized for query performance
    metro_area TEXT NOT NULL,
    region TEXT NOT NULL,
    state TEXT NOT NULL,
    
    date_month TEXT NOT NULL,  -- YYYY-MM format
    insurance_type TEXT CHECK (insurance_type IN (
        'private',    -- Commercial insurance
        'medicare',   -- Medicare
        'medicaid',   -- Medicaid
        'tricare',    -- Military (TRICARE)
        'va',         -- Veterans Affairs
        'self_pay',   -- Uninsured/cash
        'other'
    )),
    
    -- Totals (stored for validation against line items)
    total_billed DECIMAL(10,2),
    total_paid DECIMAL(10,2),
    total_patient_responsibility DECIMAL(10,2),
    
    -- Validation
    document_hash TEXT,
    verified BOOLEAN DEFAULT false,
    totals_validated BOOLEAN DEFAULT false,  -- Do line items sum to totals?
    
    -- Community signals
    upvotes INTEGER DEFAULT 0,
    flags INTEGER DEFAULT 0,
    
    -- Timing
    created_at TIMESTAMP DEFAULT NOW(),
    publish_after TIMESTAMP DEFAULT NOW(),
    published BOOLEAN DEFAULT true,
    
    CONSTRAINT positive_totals CHECK (
        total_billed >= 0 AND 
        total_paid >= 0 AND 
        total_patient_responsibility >= 0
    )
);

-- ============================================================================
-- LINE_ITEMS TABLE (individual procedures on a bill)
-- ============================================================================
CREATE TABLE line_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    bill_id UUID REFERENCES bills(id) ON DELETE CASCADE,
    
    -- Procedure details
    procedure_code TEXT NOT NULL,
    code_type TEXT CHECK (code_type IN ('cpt', 'revenue', 'hcpcs', 'ndc', 'other')) DEFAULT 'cpt',
    procedure_name TEXT NOT NULL,
    procedure_category TEXT,
    
    -- Line item pricing
    amount_billed DECIMAL(10,2) NOT NULL,
    amount_paid DECIMAL(10,2) NOT NULL,
    patient_responsibility DECIMAL(10,2) DEFAULT 0,
    
    -- Additional details
    units INTEGER DEFAULT 1,
    
    -- Denial/bundling tracking
    denial_reason TEXT,
    included_in_bundle BOOLEAN DEFAULT false,
    bundled_with_line_item_id UUID REFERENCES line_items(id),
    
    CONSTRAINT positive_amounts CHECK (
        amount_billed >= 0 AND 
        amount_paid >= 0 AND 
        patient_responsibility >= 0
    )
);

-- ============================================================================
-- PROCEDURE_CATEGORIES (reference table for standardization)
-- ============================================================================
CREATE TABLE procedure_categories (
    code TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    parent_category TEXT,
    description TEXT,
    typical_cpt_codes TEXT[],
    typical_revenue_codes TEXT[]
);

-- Seed common categories
INSERT INTO procedure_categories (code, name, parent_category, typical_revenue_codes) VALUES
    ('imaging', 'Imaging', NULL, ARRAY['040', '061']),
    ('imaging_mri', 'MRI Scan', 'imaging', ARRAY['0610', '0611', '0612', '0613', '0614', '0619']),
    ('imaging_ct', 'CT Scan', 'imaging', ARRAY['0350', '0351', '0352', '0359']),
    ('imaging_xray', 'X-Ray', 'imaging', ARRAY['0320', '0321', '0329']),
    ('imaging_ultrasound', 'Ultrasound', 'imaging', ARRAY['0400', '0401', '0402', '0409']),
    ('lab', 'Laboratory', NULL, ARRAY['030']),
    ('lab_blood', 'Blood Test', 'lab', ARRAY['0300', '0301', '0302', '0305', '0306']),
    ('lab_urine', 'Urinalysis', 'lab', ARRAY['0309']),
    ('office_visit', 'Office Visit', NULL, NULL),
    ('office_visit_simple', 'Brief Office Visit', 'office_visit', NULL),
    ('office_visit_complex', 'Extended Office Visit', 'office_visit', NULL),
    ('specialist_visit', 'Specialist Consultation', 'office_visit', NULL),
    ('surgery', 'Surgery', NULL, ARRAY['036']),
    ('surgery_minor', 'Minor Surgery', 'surgery', ARRAY['0360', '0361']),
    ('surgery_major', 'Major Surgery', 'surgery', ARRAY['0360', '0361', '0362', '0369']),
    ('anesthesia', 'Anesthesia', NULL, ARRAY['037']),
    ('facility_fee', 'Facility Fee', NULL, ARRAY['076']),
    ('pharmacy', 'Pharmacy', NULL, ARRAY['025', '063']),
    ('dme', 'Durable Medical Equipment', NULL, ARRAY['027', '029']),
    ('dme_equipment', 'DME Equipment', 'dme', ARRAY['0274', '0275']),
    ('dme_supplies', 'DME Supplies', 'dme', ARRAY['0270', '0271', '0272', '0278']),
    ('emergency', 'Emergency Room', NULL, ARRAY['045']),
    ('physical_therapy', 'Physical Therapy', NULL, ARRAY['042']),
    ('vaccination', 'Vaccination', NULL, NULL),
    ('other', 'Other', NULL, NULL);

-- ============================================================================
-- PROCEDURE_CODES (reference table for procedure codes; remove variance in procedure names)
-- ============================================================================

CREATE TABLE procedure_codes (
    code TEXT PRIMARY KEY,
    code_type TEXT NOT NULL CHECK (code_type IN ('cpt', 'revenue', 'hcpcs', 'ndc', 'other')),
    short_description TEXT NOT NULL,
    long_description TEXT,
    category TEXT,
    notes TEXT
);

-- Seed with common DME codes
INSERT INTO procedure_codes (code, code_type, short_description, category) VALUES
    ('A7030', 'hcpcs', 'Full face mask', 'dme_supplies'),
    ('A7031', 'hcpcs', 'Full face mask cushion/membrane', 'dme_supplies'),
    ('A7032', 'hcpcs', 'Nasal mask cushion/membrane', 'dme_supplies'),
    ('A7033', 'hcpcs', 'Nasal pillow mask', 'dme_supplies'),
    ('A7034', 'hcpcs', 'Nasal interface (mask or cannula)', 'dme_supplies'),
    ('A7035', 'hcpcs', 'Headgear replacement', 'dme_supplies'),
    ('A7036', 'hcpcs', 'Chinstrap', 'dme_supplies'),
    ('A7037', 'hcpcs', 'Tubing', 'dme_supplies'),
    ('A7038', 'hcpcs', 'Filter, disposable', 'dme_supplies'),
    ('A7039', 'hcpcs', 'Filter, non-disposable', 'dme_supplies'),
    ('A7044', 'hcpcs', 'Oral interface', 'dme_supplies'),
    ('A7045', 'hcpcs', 'Exhalation port', 'dme_supplies'),
    ('A7046', 'hcpcs', 'Water chamber for humidifier', 'dme_supplies'),
    ('A4604', 'hcpcs', 'Tubing with integrated heating', 'dme_supplies'),
    ('E0601', 'hcpcs', 'CPAP device', 'dme_equipment'),
    
    -- Common imaging
    ('70553', 'cpt', 'MRI brain without contrast', 'imaging_mri'),
    ('70552', 'cpt', 'MRI brain with contrast', 'imaging_mri'),
    ('71250', 'cpt', 'CT chest without contrast', 'imaging_ct'),
    
    -- Revenue codes
    ('0614', 'revenue', 'MRI', 'imaging_mri'),
    ('0402', 'revenue', 'Ultrasound', 'imaging_ultrasound'),
    ('0636', 'revenue', 'Pharmacy', 'pharmacy');

-- ============================================================================
-- INDEXES
-- ============================================================================

-- Facilities
CREATE INDEX idx_facilities_type ON facilities(type);
CREATE INDEX idx_facilities_metro ON facilities(metro_area);
CREATE INDEX idx_facilities_parent ON facilities(parent_facility_id);
CREATE INDEX idx_facilities_billing ON facilities(billing_entity_id);

-- Facility Names
CREATE INDEX idx_facility_names_hash ON facility_names(name_hash);

-- Bills
CREATE INDEX idx_bills_facility ON bills(facility_id);
CREATE INDEX idx_bills_metro ON bills(metro_area, published);
CREATE INDEX idx_bills_user ON bills(user_public_key_hash);
CREATE INDEX idx_bills_insurance ON bills(insurance_type);
CREATE INDEX idx_bills_validated ON bills(totals_validated);

-- Line Items
CREATE INDEX idx_line_items_bill ON line_items(bill_id);
CREATE INDEX idx_line_items_procedure ON line_items(procedure_code);
CREATE INDEX idx_line_items_category ON line_items(procedure_category);
CREATE INDEX idx_line_items_code_type ON line_items(code_type);

-- ============================================================================
-- VIEWS
-- ============================================================================

-- Pricing intelligence view (joins everything for easy querying)
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

-- DME unit cost
CREATE OR REPLACE VIEW dme_pricing_per_unit AS
SELECT 
    fn.name as supplier,
    f.id as facility_id,
    li.procedure_code,
    li.procedure_name,
    li.units,
    li.amount_billed,
    li.amount_paid,
    li.patient_responsibility,
    ROUND(li.amount_billed / NULLIF(li.units, 0), 2) as billed_per_unit,
    ROUND(li.amount_paid / NULLIF(li.units, 0), 2) as paid_per_unit,
    b.date_month,
    b.insurance_type,
    b.id as bill_id,
    li.id as line_item_id
FROM line_items li
JOIN bills b ON li.bill_id = b.id
JOIN facilities f ON b.facility_id = f.id
JOIN facility_names fn ON f.id = fn.facility_id
WHERE f.type = 'dme_supplier'
  AND b.published = true
  AND b.totals_validated = true;

-- Success message
SELECT 'Database schema v4.0 created successfully! 🎉' AS status;
