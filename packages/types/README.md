# Types Package

Shared TypeScript type definitions for Cost Intelligence Agency.

## Status

**Phase:** Planning  
**Language:** TypeScript (tentative)

## Purpose

Define shared data structures used across mobile apps, web, and backend to ensure type safety and consistency.

## Type Categories (Planned)

### Submission Types
```typescript
interface Submission {
  submission_id: string;
  user_public_key_hash: string;
  signature: string;
  procedure_code: string;
  procedure_name: string;
  facility_id: string;
  facility_type: FacilityType;
  metro_area: string;
  region: string;
  state: string;
  date_month: string; // YYYY-MM
  amount_billed: number;
  amount_paid: number;
  patient_responsibility: number;
  insurance_type: InsuranceType;
  device_validation: ValidationMetadata;
  document_hash: string;
  verified: boolean;
  created_at: string; // ISO 8601
  publish_after: string; // ISO 8601
  published: boolean;
}
```

### Pricing Types
```typescript
interface PricingAggregate {
  procedure_code: string;
  aggregation_level: AggregationLevel;
  aggregation_id: string;
  facility_type?: FacilityType;
  count: number;
  min_price: number;
  max_price: number;
  median_price: number;
  p25_price: number;
  p75_price: number;
  confidence: ConfidenceLevel;
  last_updated: string; // ISO 8601
}
```

### User Types
```typescript
interface User {
  public_key_hash: string;
  submissions_count: number;
  verified_submissions_count: number;
  trust_score: number; // 0-1
  first_seen: string; // ISO 8601
  last_active: string; // ISO 8601
}
```

### API Types
Request and response types for all endpoints.

## Enums
```typescript
enum FacilityType {
  Academic = 'academic',
  Community = 'community',
  ImagingCenter = 'imaging_center',
  UrgentCare = 'urgent_care',
  Clinic = 'clinic',
}

enum InsuranceType {
  Private = 'private',
  Medicare = 'medicare',
  Medicaid = 'medicaid',
  SelfPay = 'self_pay',
  Other = 'other',
}

enum ConfidenceLevel {
  High = 'high',
  Medium = 'medium',
  Low = 'low',
}
```

## Development Status

- [ ] Complete type definitions
- [ ] Documentation for each type
- [ ] Validation schemas (Zod, Yup, or similar)
- [ ] Export strategy
- [ ] Versioning strategy

## Contributing

See [CONTRIBUTING.md](../../CONTRIBUTING.md) for how to get involved.
