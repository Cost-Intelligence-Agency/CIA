# Backend API

REST API server for submissions, queries, and moderation.

## Status

**Phase:** Planning  
**Language:** To be decided (Node.js / Python / Go)

## Endpoints (Planned)

### Public Endpoints
GET  /api/procedures                    # List all procedures
GET  /api/procedures/:code              # Get specific procedure
GET  /api/procedures/:code/pricing      # Get pricing for procedure
GET  /api/metros                        # List metro areas
GET  /api/stats                         # Aggregate statistics

### Authenticated Endpoints (Signature-based)
POST /api/submissions                   # Submit new pricing data
POST /api/submissions/:id/upvote        # Upvote submission
POST /api/submissions/:id/flag          # Flag submission
GET  /api/users/:public_key_hash/stats  # Get user reputation

### Admin Endpoints
GET  /api/admin/submissions/flagged     # Flagged submissions queue
GET  /api/admin/submissions/pending     # Not yet published
POST /api/admin/submissions/:id/review  # Review flagged submission
GET  /api/admin/audit-log               # Public audit trail

## Authentication

- **Users:** Cryptographic signatures (no passwords, no sessions)
- **Admins:** To be decided (multi-sig? Hardware keys?)

## Rate Limiting

- Per IP for public endpoints
- Per public key hash for authenticated endpoints
- Aggressive limits for new users (trust-based)

## Technical Requirements

- Response time < 500ms (p95)
- Support 1000+ requests/minute
- Serverless deployment friendly
- Budget: ~$100/month for moderate traffic
- Comprehensive error handling
- Request validation and sanitization

## Development Status

- [ ] Technology stack decision
- [ ] API specification (OpenAPI/Swagger)
- [ ] Authentication implementation
- [ ] Rate limiting strategy
- [ ] Error handling patterns
- [ ] Deployment configuration

## Contributing

See [CONTRIBUTING.md](../../CONTRIBUTING.md) for how to get involved.
