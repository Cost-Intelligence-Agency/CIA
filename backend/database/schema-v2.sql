--JMJ

-- FACILITIES TABLE
CREATE TABLE facilities (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    type TEXT NOT NULL CHECK (type IN ('academic', 'community', 'imaging_center', 'urgent_care', 'clinic', 'lab', 'surgery_center', 'other')),
    metro_area TEXT NOT NULL,
    region TEXT NOT NULL,
    state TEXT NOT NULL,
    teaching_hospital BOOLEAN DEFAULT false,
    size TEXT CHECK (size IN ('large', 'medium', 'small')),
    created_at TIMESTAMP DEFAULT NOW()
);

-- USERS TABLE
CREATE TABLE users (
    public_key_hash TEXT PRIMARY KEY,
    submissions_count INTEGER DEFAULT 0,
    verified_submissions_count INTEGER DEFAULT 0,
    trust_score DECIMAL(3,2) DEFAULT 0.5 CHECK (trust_score >= 0 AND trust_score <= 1),
    first_seen TIMESTAMP DEFAULT NOW(),
    last_active TIMESTAMP DEFAULT NOW(),
    flags_received INTEGER DEFAULT 0
);

-- BILLS TABLE
CREATE TABLE bills (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_public_key_hash TEXT REFERENCES users(public_key_hash),
    signature TEXT,
    
    -- Bill metadata
    facility_id UUID REFERENCES facilities(id),
    facility_type TEXT NOT NULL,
    metro_area TEXT NOT NULL,
    region TEXT NOT NULL,
    state TEXT NOT NULL,
    
    date_month TEXT NOT NULL,  -- YYYY-MM
    insurance_type TEXT CHECK (insurance_type IN ('private', 'medicare', 'medicaid', 'tricare', 'va', 'self_pay', 'other')),
    
    -- Totals (can be calculated from line_items or stored for verification)
    total_billed DECIMAL(10,2),
    total_paid DECIMAL(10,2),
    total_patient_responsibility DECIMAL(10,2),
    
    -- Validation
    document_hash TEXT,
    verified BOOLEAN DEFAULT false,
    
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

-- LINE_ITEMS TABLE
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

-- PROCEDURE_CATEGORIES (reference table)
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

-- Indexes for fast queries
CREATE INDEX idx_bills_facility ON bills(facility_id);
CREATE INDEX idx_bills_metro ON bills(metro_area, published);
CREATE INDEX idx_bills_user ON bills(user_public_key_hash);
CREATE INDEX idx_bills_insurance ON bills(insurance_type);
CREATE INDEX idx_line_items_bill ON line_items(bill_id);
CREATE INDEX idx_line_items_procedure ON line_items(procedure_code);
CREATE INDEX idx_line_items_category ON line_items(procedure_category);
CREATE INDEX idx_line_items_code_type ON line_items(code_type);

-- View for easy querying (joins bills + line_items)
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
    f.name as facility_name,
    f.teaching_hospital,
    f.size as facility_size
FROM line_items li
JOIN bills b ON li.bill_id = b.id
JOIN facilities f ON b.facility_id = f.id
WHERE b.published = true;

-- Success message
SELECT 'Database schema v2.1 created successfully! 🎉' AS status;
