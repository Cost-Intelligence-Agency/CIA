-- FACILITIES TABLE
CREATE TABLE facilities (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    type TEXT NOT NULL CHECK (type IN ('academic', 'community', 'imaging_center', 'urgent_care', 'clinic', 'lab', 'surgery_center')),
    metro_area TEXT NOT NULL,
    region TEXT NOT NULL,
    state TEXT NOT NULL,
    teaching_hospital BOOLEAN DEFAULT false,
    size TEXT CHECK (size IN ('large', 'medium', 'small')),
    created_at TIMESTAMP DEFAULT NOW()
);

-- USERS TABLE (anonymous reputation)
CREATE TABLE users (
    public_key_hash TEXT PRIMARY KEY,
    submissions_count INTEGER DEFAULT 0,
    verified_submissions_count INTEGER DEFAULT 0,
    trust_score DECIMAL(3,2) DEFAULT 0.5 CHECK (trust_score >= 0 AND trust_score <= 1),
    first_seen TIMESTAMP DEFAULT NOW(),
    last_active TIMESTAMP DEFAULT NOW(),
    flags_received INTEGER DEFAULT 0
);

-- SUBMISSIONS TABLE
CREATE TABLE submissions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_public_key_hash TEXT REFERENCES users(public_key_hash),
    signature TEXT,
    
    -- Pricing intelligence
    procedure_code TEXT NOT NULL,
    procedure_name TEXT NOT NULL,
    facility_id UUID REFERENCES facilities(id),
    facility_type TEXT NOT NULL,
    metro_area TEXT NOT NULL,
    region TEXT NOT NULL,
    state TEXT NOT NULL,
    
    date_month TEXT NOT NULL,
    amount_billed DECIMAL(10,2) NOT NULL,
    amount_paid DECIMAL(10,2) NOT NULL,
    patient_responsibility DECIMAL(10,2) DEFAULT 0,
    insurance_type TEXT CHECK (insurance_type IN ('private', 'medicare', 'medicaid', 'self_pay', 'other')),
    
    verified BOOLEAN DEFAULT false,
    
    upvotes INTEGER DEFAULT 0,
    flags INTEGER DEFAULT 0,
    
    created_at TIMESTAMP DEFAULT NOW(),
    publish_after TIMESTAMP DEFAULT NOW(),
    published BOOLEAN DEFAULT true,
    
    CONSTRAINT positive_amounts CHECK (
        amount_billed >= 0 AND 
        amount_paid >= 0 AND 
        patient_responsibility >= 0
    )
);

-- Create indexes for fast queries
CREATE INDEX idx_submissions_procedure ON submissions(procedure_code, metro_area, published);
CREATE INDEX idx_submissions_facility_type ON submissions(procedure_code, facility_type, metro_area);
CREATE INDEX idx_submissions_user ON submissions(user_public_key_hash);

-- Success message
SELECT 'Database tables created successfully! 🎉' AS status;
