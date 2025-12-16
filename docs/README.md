# Cost Intelligence Agency (CIA)

**Crowdsourced price transparency for everything.**

*Your bills. Our data. Everyone's benefit.*

---

## The Problem

Healthcare pricing (and many other markets) operates with complete opacity. The same procedure can have wildly different "prices" depending on who's asking.

**Real example:**
- Hospital estimate: $31,000
- Billed to insurance: $1,158
- Insurance actually paid: $139.26

If you're uninsured, they'll try to collect the $31k. If you have insurance, they accept $139 and call it even. **This isn't pricing—it's a shell game.**

## The Solution

A privacy-first, crowdsourced intelligence network where consumers anonymously share what they actually paid. Armed with real data, anyone can negotiate from a position of strength.

## How It Works

1. **Submit** your bill via mobile app (Dead Drop)
2. **On-device processing** extracts pricing data, redacts all PII
3. **Regional aggregation** protects your privacy
4. **Search** before negotiating (Lantern)
5. **Negotiate** with real intelligence

## Privacy First

- Zero-knowledge architecture (we can't identify you even if subpoenaed)
- All sensitive data redacted on your device
- Cryptographic identity (no email, no names)
- Regional display (not facility-specific)
- Open source and auditable

## Project Status

**Phase:** Bootstrapping  
**Looking for:** Developers, designers, contributors  
**Timeline:** TBD

## Repository Structure
/apps                  # User-facing applications
/submission-mobile     # Dead Drop - Submit bills
/search-mobile         # Lantern - Search prices
/web                   # Web interface
/backend               # Server infrastructure
/api                   # REST API
/database              # Database schemas
/packages              # Shared code
/crypto                # Cryptographic identity
/validation            # Data validation
/types                 # Shared TypeScript types
/docs                  # Documentation

## Get Involved

We're recruiting volunteers:
- Mobile developers (React Native or Native iOS/Android)
- Backend developers (Node.js/Python/Go)
- Security/privacy reviewers
- UX/UI designers
- Documentation writers
- Community moderators

**See:** [CONTRIBUTING.md](CONTRIBUTING.md)

## Documentation

- [Technical Design Document](docs/technical-design.md)
- [Privacy Architecture](docs/privacy-architecture.md)
- [Contributing Guide](CONTRIBUTING.md)


## License
GPL

## Contact
costintelagency@proton.me

---

*The Cost Intelligence Agency is building a consumer spy network for price transparency. Join us.*
