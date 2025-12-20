# Database

PostgreSQL database (tentative) for structured pricing data.

## Status

**Phase:** Prototyping
**Database:** PostgreSQL (preferred) or alternatives

## Schema Overview (Draft)

### Core Tables
- `facilities` - Healthcare facilities (indexed by hash)
- `facility_names` - Reference table tying the hash to the real name - for internal use only
- `users` - Anonymous user reputation (public key hashes only)
- `bills` - Top-level EOB/bill metadata, including facility, month, and pricing totals as a checksum
- `line_items` - Each line on a bill, with amounts charged and paid along with standard codes
- `procedure_categories` - Tie common codes into categories of procedures to aid intel reports
- `procedure_codes` - Reference table for billing codes - streamlines data entry by allowing filling in by code

### Audit Tables (to be added)
- `audit_log` - All database modifications 
- `moderation_log` - Review decisions

## Design Principles

- **No PII** - Only structured pricing data
- **Anonymous users** - Public key hashes only, no emails/names
- **Regional aggregation** - Facility-specific data aggregated
- **Audit trail** - All modifications logged
- **Performance** - Indexed for common queries

## Key Constraints

- No user emails, names, or identities (exception: 'founder' tag)
- No facility-specific data in public queries (aggregated only)
- Minimum N thresholds for privacy
- Cryptographic signatures stored for verification
- Delayed publication (publish_after timestamps)

## Indexing Strategy

High-priority indexes:
- `procedure_code + metro_area + published` (search queries)
- `procedure_code + facility_type + metro_area` (filtered searches)
- `user_public_key_hash` (reputation lookups)
- `publish_after + published` (publication cron job)

## Development Status

- [ ] Final database selection
- [ ] Complete schema design
- [ ] Migration strategy
- [ ] Backup strategy
- [ ] Performance optimization
- [ ] Query patterns documented

## Contributing

See [CONTRIBUTING.md](../../CONTRIBUTING.md) for how to get involved.
