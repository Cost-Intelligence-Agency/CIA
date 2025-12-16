# Validation Package

Shared data validation logic for Cost Intelligence Agency.

## Status

**Phase:** Planning

## Purpose

Validate submission data consistently across mobile apps and backend:
- Document format detection
- Required field validation
- Mathematical correctness
- Procedure code validation
- Plausibility checks

## Features (Planned)

### Document Validation
- Detect EOB vs bill format
- Identify insurance company from format/logo
- Validate document structure
- Confidence scoring (0-1)

### Field Validation
- Required fields present
- Procedure codes valid (CPT code database)
- Amounts are numeric and positive
- Math checks: `billed - adjustments = paid + patient_responsibility`
- Date formats correct

### Plausibility Checks
- Amounts within reasonable ranges (not $0.01 or $999,999)
- Procedure code matches procedure name
- Insurance type matches document type
- Geographic data valid

### Statistical Validation
- Compare to existing data for procedure/region
- Outlier detection
- Flag suspiciously low/high amounts

## Technical Requirements

- Fast (< 100ms for most validations)
- Works offline (mobile apps)
- No external API calls required
- Clear error messages
- Confidence scoring for ambiguous cases

## Development Status

- [ ] Validation rule catalog
- [ ] CPT code database integration
- [ ] Document format patterns
- [ ] Mathematical validation
- [ ] Statistical validation approach
- [ ] API design
- [ ] Test suite

## Contributing

See [CONTRIBUTING.md](../../CONTRIBUTING.md) for how to get involved.
