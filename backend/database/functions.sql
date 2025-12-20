--JMJ
-- Cost Intelligence Agency - Helper Functions v2.0
-- 
-- These functions simplify data entry and validation
-- Run after schema_v4.sql
-- Changes from original:
--  -Updated create_line_item to look up and auto-populate procedure name based on code

-- ============================================================================
-- create_facility()
-- Creates a facility with name in separate table
-- Checks for duplicates via name hash
-- ============================================================================
CREATE OR REPLACE FUNCTION create_facility(
    p_name TEXT,
    p_type TEXT,
    p_metro_area TEXT,
    p_region TEXT,
    p_state TEXT,
    p_teaching_hospital BOOLEAN DEFAULT false,
    p_size TEXT DEFAULT 'medium',
    p_parent_facility_id UUID DEFAULT NULL,
    p_independent BOOLEAN DEFAULT true
)
RETURNS UUID AS $$
DECLARE
    v_facility_id UUID;
    v_name_hash TEXT;
BEGIN
    -- Generate hash for deduplication
    v_name_hash := encode(digest(lower(trim(p_name)), 'sha256'), 'hex');
    
    -- Check if facility with this name already exists
    SELECT facility_id INTO v_facility_id
    FROM facility_names
    WHERE name_hash = v_name_hash;
    
    IF v_facility_id IS NOT NULL THEN
        RAISE NOTICE 'Facility already exists with ID: %', v_facility_id;
        RETURN v_facility_id;
    END IF;
    
    -- Create facility record (no name here)
    INSERT INTO facilities (
        type, metro_area, region, state, 
        teaching_hospital, size, 
        parent_facility_id, independent
    )
    VALUES (
        p_type, p_metro_area, p_region, p_state,
        p_teaching_hospital, p_size,
        p_parent_facility_id, p_independent
    )
    RETURNING id INTO v_facility_id;
    
    -- Create name record (separate table)
    INSERT INTO facility_names (facility_id, name, name_hash)
    VALUES (v_facility_id, p_name, v_name_hash);
    
    RETURN v_facility_id;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- create_bill()
-- Creates a bill, auto-populating facility metadata
-- ============================================================================
CREATE OR REPLACE FUNCTION create_bill(
    p_user_id TEXT,
    p_facility_id UUID,
    p_date_month TEXT,
    p_insurance_type TEXT,
    p_total_billed DECIMAL,
    p_total_paid DECIMAL,
    p_total_patient_resp DECIMAL
)
RETURNS UUID AS $$
DECLARE
    v_bill_id UUID;
    v_facility RECORD;
BEGIN
    -- Get facility info automatically
    SELECT type, metro_area, region, state 
    INTO v_facility
    FROM facilities 
    WHERE id = p_facility_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Facility ID % not found', p_facility_id;
    END IF;
    
    -- Create bill with auto-populated facility info
    INSERT INTO bills (
        user_public_key_hash,
        facility_id,
        facility_type,
        metro_area,
        region,
        state,
        date_month,
        insurance_type,
        total_billed,
        total_paid,
        total_patient_responsibility,
        verified
    )
    VALUES (
        p_user_id,
        p_facility_id,
        v_facility.type,
        v_facility.metro_area,
        v_facility.region,
        v_facility.state,
        p_date_month,
        p_insurance_type,
        p_total_billed,
        p_total_paid,
        p_total_patient_resp,
        true
    )
    RETURNING id INTO v_bill_id;
    
    RETURN v_bill_id;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- create_line_item()
-- Creates a line item for a bill
-- ============================================================================
-- With units (DME supplies)
CREATE OR REPLACE FUNCTION create_line_item(
    p_bill_id UUID,
    p_procedure_code TEXT,
    p_code_type TEXT DEFAULT NULL,
    p_amount_billed DECIMAL,
    p_amount_paid DECIMAL,
    p_patient_resp DECIMAL DEFAULT 0.00,
    p_units INTEGER DEFAULT 1,
    p_denial_reason TEXT DEFAULT NULL,
    p_included_in_bundle BOOLEAN DEFAULT false,
    p_procedure_name_override TEXT DEFAULT NULL,  -- Optional: use if reference table is wrong or doesn't have the procedure yet
    p_procedure_category TEXT DEFAULT NULL  -- Optional: use if reference table is wrong or doesn't have the procedure yet
)
RETURNS UUID AS $$
DECLARE
    v_line_item_id UUID;
    v_code_type TEXT;
    v_procedure_name TEXT;
    v_category TEXT;
BEGIN
    -- Lookup code in reference table
    SELECT code_type, short_description, category
    INTO v_code_type, v_procedure_name, v_category
    FROM procedure_codes
    WHERE code = p_procedure_code;
    
       -- If not found in reference table
    IF NOT FOUND THEN
        -- If user provided override info, use it and add to reference table
        IF p_procedure_name_override IS NOT NULL AND p_code_type IS NOT NULL THEN
            v_code_type := p_code_type;
            v_procedure_name := p_procedure_name_override;
            v_category := COALESCE(p_procedure_category, 'other');
            
            -- Add to reference table for future use
            INSERT INTO procedure_codes (code, code_type, short_description, category)
            VALUES (p_procedure_code, v_code_type, v_procedure_name, v_category)
            ON CONFLICT (code) DO NOTHING;
            
            RAISE NOTICE 'Added new procedure code % to reference table', p_procedure_code;
        ELSE
            -- No override provided - set to unknown and warn
            v_code_type := COALESCE(p_code_type, 'other');
            v_procedure_name := 'Unknown procedure';
            v_category := 'other';
            
            RAISE NOTICE 'Procedure code % not found in reference table. Provide p_procedure_name_override and p_code_type to add it.', p_procedure_code;
        END IF;
    ELSE
        -- Found in reference table, but allow override
        v_procedure_name := COALESCE(p_procedure_name_override, v_procedure_name);
        v_category := COALESCE(p_procedure_category, v_category);
    END IF;
    
    INSERT INTO line_items (
        bill_id,
        procedure_code,
        code_type,
        procedure_name,
        procedure_category,
        amount_billed,
        amount_paid,
        patient_responsibility,
        units,
        denial_reason,
        included_in_bundle
    )
    VALUES (
        p_bill_id,
        p_procedure_code,
        v_code_type,
        v_procedure_name,
        v_category,
        p_amount_billed,
        p_amount_paid,
        p_patient_resp,
        p_units,
        p_denial_reason,
        p_included_in_bundle
    )
    RETURNING id INTO v_line_item_id;
    
    RETURN v_line_item_id;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- validate_bill_totals()
-- Check if line items sum to bill totals
-- ============================================================================
CREATE OR REPLACE FUNCTION validate_bill_totals(p_bill_id UUID)
RETURNS TABLE(
    status TEXT,
    bill_total_billed DECIMAL,
    bill_total_paid DECIMAL,
    line_items_total_billed DECIMAL,
    line_items_total_paid DECIMAL,
    billed_matches BOOLEAN,
    paid_matches BOOLEAN,
    line_item_count INTEGER
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        CASE 
            WHEN b.total_billed = COALESCE(SUM(li.amount_billed), 0) 
             AND b.total_paid = COALESCE(SUM(li.amount_paid), 0)
            THEN '✅ VALID - Totals match'
            ELSE '❌ MISMATCH - Check your line items'
        END as status,
        b.total_billed,
        b.total_paid,
        COALESCE(SUM(li.amount_billed), 0) as line_items_billed,
        COALESCE(SUM(li.amount_paid), 0) as line_items_paid,
        b.total_billed = COALESCE(SUM(li.amount_billed), 0) as billed_matches,
        b.total_paid = COALESCE(SUM(li.amount_paid), 0) as paid_matches,
        COUNT(li.id)::INTEGER as line_count
    FROM bills b
    LEFT JOIN line_items li ON b.id = li.bill_id
    WHERE b.id = p_bill_id
    GROUP BY b.id, b.total_billed, b.total_paid;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- mark_bill_validated()
-- Automatically set totals_validated flag
-- ============================================================================
CREATE OR REPLACE FUNCTION mark_bill_validated(p_bill_id UUID)
RETURNS BOOLEAN AS $$
DECLARE
    v_bill_total_billed DECIMAL;
    v_bill_total_paid DECIMAL;
    v_line_total_billed DECIMAL;
    v_line_total_paid DECIMAL;
    v_matches BOOLEAN;
BEGIN
    -- Get bill totals
    SELECT total_billed, total_paid 
    INTO v_bill_total_billed, v_bill_total_paid
    FROM bills 
    WHERE id = p_bill_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Bill ID % not found', p_bill_id;
    END IF;
    
    -- Get line item totals
    SELECT 
        COALESCE(SUM(amount_billed), 0),
        COALESCE(SUM(amount_paid), 0)
    INTO v_line_total_billed, v_line_total_paid
    FROM line_items
    WHERE bill_id = p_bill_id;
    
    -- Check if they match
    v_matches := (v_bill_total_billed = v_line_total_billed) 
                 AND (v_bill_total_paid = v_line_total_paid);
    
    -- Update flag
    UPDATE bills 
    SET totals_validated = v_matches
    WHERE id = p_bill_id;
    
    RETURN v_matches;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- get_facility_name() - Helper to lookup names (internal use)
-- ============================================================================
CREATE OR REPLACE FUNCTION get_facility_name(p_facility_id UUID)
RETURNS TEXT AS $$
DECLARE
    v_name TEXT;
BEGIN
    SELECT name INTO v_name
    FROM facility_names
    WHERE facility_id = p_facility_id;
    
    RETURN v_name;
END;
$$ LANGUAGE plpgsql;

-- Success message
SELECT 'Helper functions created successfully! 🎉' AS status;
