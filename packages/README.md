# Shared Packages

Shared code used across multiple applications.

## Packages

### crypto
Cryptographic identity and signing functionality.
- Key generation (BIP39 recovery phrases)
- Signature creation and verification
- Public key hashing

### validation
Data validation logic shared between mobile and backend.
- Document format validation
- Procedure code validation
- Amount plausibility checks
- Statistical validation

### types
TypeScript type definitions shared across the platform.
- Submission types
- Pricing aggregate types
- API request/response types

## Status

**Phase:** Planning

All packages are in planning phase pending technology stack decisions.

## Design Principles

- **Framework-agnostic** where possible
- **Well-tested** (high coverage)
- **Documented** (clear APIs)
- **Versioned** (semantic versioning)

## Contributing

See [CONTRIBUTING.md](../../CONTRIBUTING.md) for how to get involved.
