# Cost Intelligence Agency
## Technical Design Document

---

## Executive Summary

The Cost Intelligence Agency is building a privacy-first, crowdsourced price transparency platform. We're starting with medical bills and expanding to any market with opaque pricing. This document outlines our technical approach, architecture decisions, and privacy commitments.

**Current Status:** Design phase, recruiting developers  
**Timeline:** MVP in 6-9 months (volunteer-driven, spare time contributors)  
**Budget:** $100/month infrastructure  
**Initial Data:** Founder + volunteer bills ready to seed database

---

## Mission & Vision

### The Problem
Healthcare pricing (and many other markets) operates with complete opacity. The same procedure can have wildly different "prices" depending on who's asking:

**Real example:**
- Hospital estimate: $31,000
- Billed to insurance: $1,158
- Insurance actually paid: $139.26

Uninsured patients get charged inflated prices while having no negotiating power because they don't know what providers actually accept.

### The Solution
A crowdsourced intelligence network where consumers anonymously share what they actually paid. Armed with real data, anyone can negotiate from a position of strength.

### Scope
**Phase 1:** Medical bills (highest impact, people going bankrupt)  
**Phase 2:** Any opaque pricing market (auto repairs, legal fees, home services, funeral costs, vet bills, etc.)

---

## Core Principles

### 1. Inherently Private
**Zero-knowledge architecture:** We cannot identify users even if compelled to do so.
- Cryptographic identity (no email, no names, no PII)
- All sensitive data redaction happens on-device
- Server receives only structured pricing data
- Regional aggregation protects against re-identification
- Subpoena-resistant by design

### 2. Mobile Collection
Reality: People interact with bills via phone camera, not desktop scanners.
- Camera is the primary input method
- On-device OCR and processing
- Optimized for the moment someone gets angry about a bill

### 3. Open Source
- Community-owned from day one
- Auditable code (especially privacy-critical components)
- Impossible to buy out or shut down
- Contributors share ownership
- Security through transparency, not obscurity

### 4. Quality Over Quantity
Better to have 500 verified, trusted submissions than 5,000 questionable ones.
- Multi-layer validation
- Reputation systems
- Community moderation
- Statistical validation

### 5. Regional Aggregation
Display pricing by region/facility type, not specific facilities.
- Better privacy (larger anonymity sets)
- More useful for negotiation
- Handles price variation intelligently
- Always have enough data to show

---

## User Experience Flow

### Primary Flow: Submit a Bill

```
1. User receives bill, gets angry
    ↓
2. Opens app, taps "Add Intelligence Report"
    ↓
3. Camera permission → Takes photo
    ↓
4. [ON DEVICE] OCR extraction
    ↓
5. [ON DEVICE] Pre-screening validation
   "✅ Valid Blue Cross EOB detected (95% confidence)"
    ↓
6. Review extracted data:
   - Procedure: MRI Brain without contrast
   - Facility: General Hospital, Boston MA
   - Facility type: Community Hospital
   - Amount billed: $1,158
   - Amount paid: $139.26
   - Insurance type: Private
   [Edit any field]
    ↓
7. [ON DEVICE] Interactive PII redaction
   "Tap to hide sensitive information"
   [Shows image with highlighted regions]
   - Your name ✓
   - Address ✓
   - Member ID ✓
   - Claim number ✓
   [User can add more]
    ↓
8. Review redacted version
   "This is what we'll store (your data never leaves your device)"
    ↓
9. Submit → Signed with private key → Server receives structured data only
    ↓
10. Random delay (6 hours - 7 days) before publishing
    ↓
11. Confirmation: "Thanks! View similar procedures in your area"
```

### Secondary Flow: Search Before Negotiating

```
1. User has bill, wants to negotiate
    ↓
2. Opens app → "Search Procedures"
    ↓
3. Search: "MRI" or browse by category
    ↓
4. Select: "MRI Brain without contrast (CPT 70553)"
    ↓
5. Filter: Location (Boston, MA)
    ↓
6. Results (dynamically aggregated):
   
   "Community Hospitals in Greater Boston
    Price range: $140-$220 (23 verified reports)
    Confidence: High
    Last updated: Dec 2024"
   
   "Academic Medical Centers in Greater Boston
    Price range: $200-$380 (45 verified reports)
    Confidence: High"
   
   "💡 Standalone imaging centers: $110-$180 (18 reports)"
    ↓
7. Tap facility type for details:
   "You're negotiating with a Community Hospital.
    Similar facilities typically accept: $140-$220
    
    Try offering: $150-$180
    (Reasonable starting point based on 23 reports)"
    ↓
8. Export/print for negotiation
    ↓
9. Optional: "Report your negotiated price to help others"
```

---

## Privacy Architecture

### Zero-Knowledge User Identity

**Cryptographic key-based identity (no centralized accounts):**

```
Device generates on first use:
- Private key (stored in secure enclave)
- Public key
- 12-word recovery phrase (BIP39 standard)

User identity = hash(public_key)
→ Anonymous, unforgeable, recoverable
```

**What server knows:**
- Public key hash: "7a8b9c..." (anonymous identifier)
- Submission count, trust score, timestamps
- NO email, name, real identity, linkable information

**Recovery:**
- User writes down 12-word phrase
- New device → enter phrase → regenerate keys → same identity
- Lost phrase = lost identity forever (like crypto wallet)

**Trade-off:** Maximum privacy requires user responsibility

### Data Minimization

**What we NEVER collect or store:**
- ❌ Names
- ❌ Addresses (only metro area/region)
- ❌ Email addresses
- ❌ Phone numbers
- ❌ Member IDs
- ❌ Claim numbers
- ❌ Document numbers
- ❌ Barcodes
- ❌ Dates of birth
- ❌ Specific service dates (only month/year)
- ❌ Insurance company names (only type: "private", "medicare", "medicaid")
- ❌ Device identifiers
- ❌ IP addresses (never logged)
- ❌ Search queries (aggregate stats only)
- ❌ Original unredacted documents

**What we DO store (but protect through aggregation):**
- ✅ Facility IDs (stored internally, rarely displayed individually)
- ✅ Facility names (in facilities table, for aggregation purposes)
- ✅ Display shows facility *types* and *regions*, not specific names

**What we DO store per submission:**
```javascript
{
  submission_id: uuid,
  user_public_key_hash: "7a8b9c...", // anonymous identifier
  signature: "cryptographic proof of submission",
  
  // Pricing intelligence only:
  procedure_code: "70553", // CPT code
  procedure_name: "MRI Brain without contrast",
  facility_id: "uuid-of-facility", // stored but not displayed individually
  facility_type: "community_hospital", // displayed
  metro_area: "Greater Boston",
  region: "Northeast",
  state: "MA",
  
  date_month: "2024-11", // month/year only
  amount_billed: 1158.00,
  amount_paid: 139.26,
  patient_responsibility: 0.00,
  insurance_type: "private", // enum
  
  // Validation metadata:
  device_validation: {
    confidence: 0.95,
    document_type: "eob",
    insurer_type: "blue_cross",
    format_valid: true,
    math_valid: true
  },
  
  document_hash: "sha256...", // proof of possession
  verified: true, // uploaded document for verification
  
  created_at: timestamp,
  publish_after: timestamp // delayed publication
}
```

### On-Device Processing Pipeline

**All sensitive data processing happens on user's device:**

```
1. Photo capture
    ↓
2. OCR (Tesseract.js / ML Kit / Vision framework)
    ↓
3. Document validation:
   - Detect EOB/bill format
   - Validate against known patterns
   - Check math, procedure codes
   - Confidence scoring
   (Unique identifiers checked then discarded)
    ↓
4. PII detection & redaction:
   - Pattern matching (SSN format, phone, etc.)
   - Named entity recognition
   - Interactive user confirmation
   - Black boxes over sensitive regions
    ↓
5. PERMANENTLY DELETE original photo from device
   - Secure deletion (overwrite, not just unlink)
   - Happens BEFORE any network activity
   - Redacted version also deleted after extraction
   - User can optionally save redacted copy to their photos
    ↓
6. Extract structured data only
    ↓
7. Sign with private key
    ↓
8. Send to server:
   - Structured data
   - Validation results
   - Signature
   - Optional: redacted image (for moderation)
   - Document hash (proof of possession)
```

**Server never receives:**
- Original photo
- Unredacted images
- Any PII (names, addresses, member IDs, etc.)
- Unique document identifiers (claim numbers, barcodes, etc.)

### Regional Aggregation for Privacy

**Why regional display protects privacy:**

```
Facility-specific (risky):
- Small Hospital, Rural Town: 3 submissions
- Only 3 MRIs performed this quarter
→ Easy to identify patients

Regional aggregation (safe):
- Western Massachusetts hospitals: 43 submissions  
- 50+ facilities, 1000+ procedures
→ Cannot identify individuals
```

**Adaptive granularity based on data availability and price consistency:**

```javascript
Display most granular level that meets:
1. Minimum N (5-20 depending on level)
2. Privacy threshold (adequate anonymity set)
3. Statistical reliability (enough data for confidence)

Levels:
- Facility type in metro (if N≥15 and consistent pricing)
- Metro-wide (if N≥20)
- Regional (if N≥25)
- State-wide (if needed)
```

### Metadata Protection

**Metadata is the primary confidentiality threat.**

**Timing protection:**
- Random delay (6 hours - 7 days) before publishing submissions
- Batch publishing (every 6 hours, not real-time)
- Date display: "Q4 2024" not "November 15, 2024"
- Longer delays (30+ days) for rare/identifiable combinations

**Geographic protection:**
- Display metro/region, not specific facilities (in most cases)
- Aggregate small populations
- No street addresses, full ZIP codes

**Behavioral protection:**
- No search query logging (aggregate stats only)
- No user activity tracking
- Cannot correlate searches with submissions
- No IP address logging anywhere

**Statistical protection:**
- Minimum N before displaying data
- k-anonymity for rare combinations
- Suppress uniquely identifying data
- Higher aggregation for rare procedures

### Subpoena Resistance

**If compelled by law enforcement or legal action:**

We can honestly state:
- "We don't store emails, names, or addresses"
- "We don't have member IDs or claim numbers"
- "We only have cryptographic hashes and regional pricing data"
- "We cannot identify users even if we wanted to"
- "Users control their own identity keys"
- "We don't log IP addresses or search queries"

**The data we have is not useful for identifying individuals.**

### User Disclosure

**Privacy Limitations (User-Facing):**

```markdown
**What we protect:**
✅ Your name, address, member ID never leave your device
✅ Your identity is cryptographically anonymous
✅ All sensitive data redacted on your device
✅ Prices displayed regionally, not facility-specific
✅ Delayed publication (6 hours to 7 days)

**What we can't fully protect:**
⚠️ Very rare procedures may still be identifiable
⚠️ Multiple submissions create a pattern
⚠️ Determined adversary with hospital records could correlate

**Your choice:**
- Submit recent bills (higher re-identification risk)
- OR wait weeks/months (better anonymity, less useful data)
- OR don't submit rare procedures at small facilities

We're transparent about limitations. You decide your risk tolerance.
```

---

## Technical Architecture

### Platform Strategy

**Mobile-First (MVP):**
- React Native (recommended for speed to market)
  - Single codebase → iOS + Android
  - Access to native ML/camera APIs
  - Web developer-friendly
- Alternative: Native iOS/Android (better performance, more specialized developers)

**Why mobile:**
- Camera is the input method
- People interact with bills on phones
- On-device processing is standard (ML frameworks built-in)
- Secure enclaves for cryptographic keys
- Matches user behavior (mobile-first world)

**Web interface (Phase 2):**
- Search and browse data
- Manual data entry (fallback)
- Analytics and insights
- Admin/moderation tools

### Technology Stack (Proposed)

**Mobile App:**
- React Native or Native (iOS/Android)
- On-device ML: ML Kit (Google) or Vision (Apple)
- Camera: React Native Camera or native APIs
- Cryptography: Native crypto libraries
- Local storage: Secure enclave for keys

**Backend:**
- Node.js or Python (API server)
- PostgreSQL (structured data, good search, aggregations)
- Serverless functions (AWS Lambda or similar)
- Object storage (S3 or compatible) for optional redacted images

**Infrastructure:**
- Managed database (AWS RDS, Supabase, or similar)
- Serverless compute (AWS Lambda, Cloudflare Workers)
- CDN (Cloudflare free tier)
- Domain: costintelagency.org
- Budget: $100/month covers MVP to moderate scale

**Development:**
- GitHub (open source repository)
- CI/CD: GitHub Actions
- Testing: Jest, Detox (mobile)

**Note:** Final stack decided with technical lead based on expertise and preferences.

### Database Schema (Draft)

**facilities**
```sql
id: uuid PRIMARY KEY
name: text
type: enum (academic, community, imaging_center, urgent_care, clinic)
metro_area: text -- "Greater Boston"
region: text -- "Northeast"
state: text
teaching_hospital: boolean
size: enum (large, medium, small)
created_at: timestamp
```

**submissions**
```sql
id: uuid PRIMARY KEY
user_public_key_hash: text -- anonymous user identifier
signature: text -- cryptographic proof

procedure_code: text -- CPT code
procedure_name: text
facility_id: uuid FOREIGN KEY
facility_type: enum
metro_area: text
region: text
state: text

date_month: text -- YYYY-MM only
amount_billed: decimal
amount_paid: decimal
patient_responsibility: decimal
insurance_type: enum (private, medicare, medicaid, self_pay, other)

device_validation: jsonb -- validation metadata
document_hash: text -- sha256 of original
verified: boolean -- submitted document

upvotes: integer -- community confirmations
flags: integer -- community flags

created_at: timestamp
publish_after: timestamp -- delayed publication
published: boolean

INDEX on (procedure_code, metro_area, published)
INDEX on (procedure_code, facility_type, metro_area)
INDEX on (user_public_key_hash)
```

**users** (anonymous reputation only)
```sql
public_key_hash: text PRIMARY KEY
submissions_count: integer
verified_submissions_count: integer
trust_score: decimal (0-1)
first_seen: timestamp
last_active: timestamp
flags_received: integer
```

**price_aggregates** (pre-computed for performance)
```sql
id: uuid PRIMARY KEY
procedure_code: text
aggregation_level: enum (facility_type, metro, region, state)
aggregation_id: text -- which metro/region/etc
facility_type: text (nullable) -- if aggregating by type

count: integer
min_price: decimal
max_price: decimal
median_price: decimal
p25_price: decimal -- 25th percentile
p75_price: decimal -- 75th percentile
variance: decimal

confidence: enum (high, medium, low)
last_updated: timestamp
data_sufficient: boolean -- meets minimum N

INDEX on (procedure_code, aggregation_level, aggregation_id)
```

**No email, no password, no real identity.**

### API Design (Draft)

**Public endpoints:**
```
GET  /api/procedures
GET  /api/procedures/:code
GET  /api/procedures/:code/pricing?metro=...&facility_type=...
GET  /api/metros
GET  /api/stats (aggregate only)
```

**Authenticated endpoints** (signed requests):
```
POST /api/submissions (submit new data)
POST /api/submissions/:id/upvote
POST /api/submissions/:id/flag
GET  /api/users/:public_key_hash/stats
```

**Admin endpoints** (for moderation):
```
GET  /api/admin/submissions/flagged
GET  /api/admin/submissions/pending (not yet published)
POST /api/admin/submissions/:id/review
GET  /api/admin/audit-log (public audit trail)
```

---

## Validation & Trust System

### Multi-Layer Validation

**Layer 1: Device Pre-Screening (Before Submission)**

On-device validation checks:
- ✅ Document format matches known EOB/bill patterns
- ✅ Required fields present (procedure codes, amounts, etc.)
- ✅ Math is correct (billed - adjustments = paid + patient_responsibility)
- ✅ Procedure codes are valid (CPT code database)
- ✅ Amounts are plausible (not obviously fake like $0.01 or $999,999)
- ✅ Insurer detected from logo/format

**Result:** Confidence score (0-1) sent with submission

**Benefits:**
- Unique identifiers checked locally then discarded (never transmitted)
- Immediate user feedback
- Catches mistakes before submission
- Reduces bad data reaching server

**Layer 2: Server-Side Statistical Validation**

Server checks:
- Is this an outlier? (compare to existing data for this procedure/region)
- Does the user have a trust score? (new user = more scrutiny)
- Is this within expected ranges?
- Is this submission rate suspicious? (spam detection)

**Result:** Auto-approve, auto-reject, or flag for review

**Layer 3: User Reputation System**

Anonymous trust scoring:
```javascript
trust_score = f(
  submissions_count,      // More submissions = more trusted
  verified_count,         // Uploaded documents = higher trust
  upvotes_received,       // Community confirmations
  flags_received,         // Community reports
  time_active,            // Longer history = more trusted
  statistical_accuracy    // Submissions match norms
)
```

**Trust levels:**
- 0.0 - 0.3: New/Untrusted (manual review required)
- 0.3 - 0.7: Moderate (automated checks, some manual review)
- 0.7 - 1.0: Trusted (auto-approved, spot checks only)

**Layer 4: Community Validation**

Users can:
- ✅ Upvote: "I paid similar for this procedure"
- 🚩 Flag: "This seems wrong"

Submissions with multiple confirmations gain credibility.

**Layer 5: Moderator Review**

Flagged submissions reviewed by:
- Trusted community moderators
- Project maintainers
- Can see: redacted images, structured data, trust signals
- Cannot see: Original documents, PII, user identity

**Moderator actions:**
- Approve (make public)
- Request more info
- Reject (with reason)
- Ban user (if clearly malicious)

### Display Trust Signals

Search results show transparency:
```
MRI Brain without Contrast
Community Hospitals in Greater Boston

Price Range: $140 - $220
Based on 23 submissions:
  ✅ 18 from verified contributors ⭐⭐⭐
  ⭐ 5 from new contributors

Last updated: December 2024
Confidence: High
Price consistency: Good (20% range)

[View details] [Report your price]
```

Individual submissions never shown (aggregate only) to prevent re-identification.

---

## Regional Aggregation Strategy

### Philosophy
**Show the most granular data that's both statistically reliable and privacy-preserving.**

### Adaptive Granularity Algorithm

```javascript
function getPriceIntelligence(procedure, userLocation, facilityType) {
  // Try progressively broader aggregations until we have enough data
  
  // Level 1: Facility type in metro (best case)
  if (facilityType && metro) {
    const data = query({
      procedure,
      facility_type: facilityType,
      metro: userMetro,
      minN: 15
    });
    
    if (data.count >= 15 && data.variance < 0.25) {
      return {
        level: "facility_type_metro",
        display: "Community Hospitals in Greater Boston",
        range: data.range,
        count: data.count,
        confidence: "high",
        note: null
      };
    }
  }
  
  // Level 2: Metro-wide
  const metroData = query({
    procedure,
    metro: userMetro,
    minN: 20
  });
  
  if (metroData.count >= 20) {
    return {
      level: "metro",
      display: "Greater Boston area",
      range: metroData.range,
      count: metroData.count,
      confidence: metroData.variance < 0.35 ? "high" : "medium",
      note: metroData.variance > 0.5 ? 
        "Wide variation - price depends on facility type" : null
    };
  }
  
  // Level 3: Regional
  const regionalData = query({
    procedure,
    region: userRegion,
    minN: 25
  });
  
  if (regionalData.count >= 25) {
    return {
      level: "region",
      display: "Northeast region",
      range: regionalData.range,
      count: regionalData.count,
      confidence: regionalData.variance < 0.5 ? "medium" : "low",
      note: "Limited local data - using regional average"
    };
  }
  
  // Level 4: State-wide (last resort)
  return stateWideData();
}
```

### Why This Works

**Privacy benefits:**
- Larger anonymity sets (harder to re-identify)
- Rare procedures at small facilities protected
- Can display data even with low N per facility
- Metadata correlation much harder

**Utility benefits:**
- More useful for negotiation ("similar facilities accept...")
- Better statistical confidence (more data points)
- Handles price variation intelligently
- Actionable insights (facility type matters)

**Always show something:**
- Aggregate upward until we have data
- Clear confidence indicators
- Transparent about aggregation level
- User knows what they're getting

### Handling Price Variation

**Detect consistent vs variable pricing:**

```javascript
function assessPriceConsistency(priceData) {
  const range = (priceData.max - priceData.min) / priceData.median;
  
  if (range < 0.20) {
    return {
      consistency: "high",
      message: "✅ Consistent pricing in this area",
      canUseRegional: true
    };
  } else if (range < 0.40) {
    return {
      consistency: "medium",
      message: "Moderate variation - see breakdown by facility type",
      suggestFacilityType: true
    };
  } else {
    return {
      consistency: "low",
      message: "⚠️ Wide variation - price depends heavily on facility type",
      requireFacilityType: true,
      showBreakdown: true
    };
  }
}
```

**Display adapts to variance:**

```
High consistency:
"Boston area: $140-170 (tight range, 32 reports)"

Low consistency:
"Boston area: $100-400 (wide variation)
 
 By facility type:
 • Imaging centers: $100-150 (8 reports)
 • Community hospitals: $180-250 (15 reports)
 • Academic centers: $300-400 (9 reports)
 
 💡 Facility type matters significantly for this procedure"
```

### Facility Type Categorization

```javascript
facility_types: {
  academic: "Academic Medical Center",
  community: "Community Hospital",
  imaging_center: "Imaging Center",
  urgent_care: "Urgent Care",
  clinic: "Outpatient Clinic",
  lab: "Laboratory",
  surgery_center: "Ambulatory Surgery Center"
}
```

**More useful than specific facility names** for negotiation purposes.

---

## Security Assessment

### CIA Triad Analysis

**Integrity: HIGH RISK ⚠️⚠️⚠️**

**Why:** False data misleads users → they accept bad prices → financial harm

**Threats:**
- Malicious insider modifies database
- Attacker compromises infrastructure
- Coordinated fake submissions
- Hospital employees poison data
- Data tampering without detection

**Impact:** Users make wrong financial decisions based on bad data

**Mitigations:**
- Cryptographic signatures (users sign submissions - can't be forged)
- Public audit logs (detect tampering)
- Append-only event log (tamper-evident history)
- Data mirroring (multiple independent copies detect divergence)
- Multi-layer validation
- Community oversight
- Statistical validation

**Detection mechanisms:**
- Users can verify their submissions unchanged
- Community can audit full event chain
- Mirrors detect if official database diverges
- Anomaly detection for suspicious patterns

---

**Availability: MEDIUM RISK ⚠️**

**Why:** Users need data when negotiating (time-sensitive), but not life-critical

**Threats:**
- DDoS attacks
- Infrastructure compromise
- Account takeover
- Budget exhaustion (crypto mining, runaway bills)
- Insider sabotage

**Impact:** Users can't access data during negotiation window

**Mitigations:**
- Cloud reliability (AWS/GCP uptime is good)
- DDoS protection (Cloudflare)
- Regular data exports (GitHub, Archive.org)
- Offline app cache (recent searches work)
- Cost monitoring with kill switches
- Multiple admin keys required for infrastructure changes
- Community can run mirrors

**Why only MEDIUM:**
- Not life-threatening if service is down
- Users can retry negotiation later
- Data dumps available for manual lookup
- Service can be reconstructed from exports
- Downtime is inconvenient, not catastrophic

---

**Data Confidentiality: LOW RISK ✅**

**Why:** We don't store secrets. Data is meant to be public.

**"Sensitive" data:**
- Anonymous regional pricing (meant to be public)
- Cryptographic hashes (useless without keys)
- User reputation scores (anonymous)

**NOT stored:**
- Names, addresses, emails
- Member IDs, claim numbers
- Any PII

**Breach impact:** Attacker learns public pricing information

---

**Metadata Confidentiality: MEDIUM-HIGH RISK ⚠️⚠️**

**Why:** Submission patterns, timing, and behavior could enable re-identification

**Threats:**
- Timing correlation: Hospital knows bill date → correlate with submission
- Geographic correlation: Rare procedure + small facility → limited patient pool
- Pattern analysis: Multiple submissions from same user → behavioral fingerprint
- Cross-reference: Combine with leaked insurance data or hospital records
- Search behavior leakage: What you search reveals what bills you have

**Particularly vulnerable:**
- Rare procedures (fewer patients)
- Small facilities (limited pool)
- Unique combinations (procedure + location + date)
- First-time submitters (account creation = timestamp)

**Mitigations:**

**Temporal protection:**
- Random delays (6 hours - 7 days) before publishing
- Batch publishing (every 6 hours, not real-time)
- Date fuzzing ("Q4 2024" not exact dates)
- Longer delays (30+ days) for rare/identifiable combinations

**Geographic protection:**
- Regional display (not facility-specific in most cases)
- Aggregate small populations
- No street addresses or full ZIP codes
- Metro/region level only

**Behavioral protection:**
- No search query logging (aggregate stats only)
- No user activity tracking
- Cannot correlate searches with submissions
- No IP address logging anywhere

**Statistical protection:**
- Minimum N=15-25 (depending on aggregation level)
- k-anonymity for rare combinations
- Suppress uniquely identifying data
- Higher aggregation for rare procedures
- Add noise to small cells if needed

**Residual risk:**
- Very rare procedures at small facilities may still be identifiable
- Users with unique procedure combinations at risk
- Determined adversary with auxiliary data could correlate
- We accept this risk: users are informed and choose their comfort level

---

### Security Priority Order

```markdown
1. **Integrity (HIGH)** - Most resources here
   - Audit logging
   - Cryptographic signatures  
   - Validation systems
   - Community oversight
   - Data mirroring

2. **Metadata Confidentiality (MEDIUM-HIGH)** - Important protection
   - Temporal/geographic fuzzing
   - No logging of sensitive metadata
   - Regional aggregation
   - k-anonymity enforcement

3. **Availability (MEDIUM)** - Reasonable precautions
   - Basic redundancy
   - DDoS protection
   - Data exports
   - Cost monitoring

4. **Data Confidentiality (LOW)** - Basics only
   - Standard HTTPS
   - Credential management
   - Data isn't secret - don't overthink it
```

---

## Insider Threat Mitigation

### Philosophy
**Tamper evidence, not tamper prevention.**

We prioritize detecting and proving misconduct over preventing it entirely. This aligns with our open source values - transparency is our security model.

### Who Are The Insiders?

1. **Project maintainers** - Database access, deployment, can modify data
2. **Volunteer moderators** - Review flagged submissions, ban users
3. **Compromised accounts** - Hacked credentials, malicious code merged

### What Insiders Can Do

**With database access:**
- ✅ Modify any submission (change prices)
- ✅ Delete submissions
- ✅ Manipulate trust scores
- ❌ Can't identify users (data is anonymous)
- ❌ Can't forge signatures (don't have user private keys)

**With code deployment:**
- ✅ Push malicious app update (steal recovery phrases)
- ❌ But code is open source (community can see and verify)

### Defenses

**1. Public Audit Trail**
```javascript
// Every database modification is logged publicly
audit_log: {
  timestamp: "2024-12-13T20:15:00Z",
  action: "submission_modified",
  submission_id: "abc-123",
  actor: "admin_public_key_hash", // which admin
  before_hash: "7a8b9c...",
  after_hash: "9d3f2a...",
  signature: "admin_signature", // cryptographically proves who
  public: true // anyone can see this
}

// Append-only log
// Anyone can verify integrity of the chain
// Tampering with logs is detectable
```

**Why this works:**
- Admin CAN modify data, but CAN'T hide that they did it
- Community can audit and detect suspicious changes
- Whistleblowing: "Admin modified 50 submissions last night"
- Bad actor's reputation is destroyed
- Actions are traceable and provable

**2. Cryptographic Accountability**
- All user submissions signed (can't be forged)
- All admin actions signed (proves who did what)
- Users can verify their submissions haven't changed
- Signatures use standard cryptographic libraries

**3. Data Mirroring**
```javascript
// Continuous replication to independent locations
public_mirrors: [
  "GitHub (daily exports)",
  "Archive.org (weekly snapshots)",
  "IPFS (distributed)",
  "Community-run mirrors"
]

// If official database is tampered:
// - Mirrors have original data
// - Community can detect divergence
// - Can restore from clean copy
```

**4. Code Deployment Security**

```javascript
// Releases require multiple maintainer signatures
deployment: {
  code_review: "required for all PRs",
  signed_releases: "2 maintainers must sign",
  reproducible_builds: "anyone can verify binary matches source",
  community_review: "public PRs, visible changes"
}
```

**Why code deployment needs more protection:**
- Malicious code harder to detect after deployment
- Could steal user keys or exfiltrate data
- Worth the overhead for releases

**5. Community Oversight**
- All code is open source (anyone can review)
- All audit logs are public (anyone can monitor)
- Whistleblowing-friendly (bad actions are visible)
- Reputation at stake for maintainers

### Result

**Malicious insider CAN act, but WILL be caught and can't hide it.**

Detection, not prevention. Transparency is our security model.

---

## Threat Model & Attack Scenarios

### Open Source Security Principle

**All code is public. Security depends on:**
- Strong cryptography (not secret algorithms)
- Defense in depth (multiple layers)
- Economic incentives (attacks must be costly)
- Community oversight (many eyes reviewing)

**We do NOT rely on:**
- ❌ Keeping validation logic secret
- ❌ Obscure algorithms
- ❌ Hidden backdoors

### Attack Scenarios & Mitigations

**1. Sybil Attack (Fake Identity Spam)**

*Attack:* Adversary creates 1,000 fake identities, submits garbage data to pollute database

*Current defenses:*
- New users have low trust scores (submissions go to manual review)
- Statistical outlier detection
- Community flagging

*Additional mitigations needed:*
- Proof-of-work on first submission (~10 seconds CPU time)
- Rate limiting per new identity
- First N submissions from new users require manual review
- Pattern detection for coordinated bot behavior

*Cost to attacker:* Time, computational resources, manual review catches most

---

**2. Targeted Data Poisoning**

*Attack:* Hospital employees submit fake prices to make their facility look good or competitors look bad

*Current defenses:*
- User reputation system
- Statistical validation (outliers flagged)
- Community upvote/downvote

*Additional mitigations:*
- Detect submission spikes (many submissions for same facility in short time)
- Geographic clustering detection (many submissions from same IP range)
- Temporal analysis (unusual patterns)
- Require document verification for facilities with few submissions

*Cost to attacker:* Need many accounts with built-up trust, takes time/effort

---

**3. Document Replay Attack**

*Attack:* Get one real EOB, modify numbers, submit multiple times

*Current defenses:*
- Document hash stored (exact duplicates detected)

*Additional mitigations needed:*
- Perceptual hashing (detects visually similar images even if pixels differ)
- Multiple hash types (SHA-256 for exact match, pHash for similarity detection)
- Flag submissions where perceptual hashes are very close but amounts differ
- Example: Same document layout/structure but different numbers edited in

*Cost to attacker:* Need access to real documents, sophisticated image manipulation

---

**4. Re-identification via Metadata**

*Attack:* Cross-reference submission timing/location with known patient data

*Current defenses:*
- Random delays (6 hours - 7 days) before publishing
- Regional aggregation (not facility-specific)
- No IP logging
- Only month/year for dates
- Geographic fuzzing

*Why still medium-high risk:*
- Very rare procedures may still be identifiable
- Determined adversary with auxiliary data could correlate
- Statistical inference possible with enough data points

*Residual risk accepted:* Users informed and choose their risk tolerance

---

**5. Infrastructure Compromise (Integrity)**

*Attack:* Hacker gains database access, modifies prices to mislead users

*Impact:* HIGH - Users negotiate based on false data

*Current defenses:*
- Cryptographic signatures (can't forge user submissions)
- Public audit logs (modifications are visible)
- Append-only event log (tampering is detectable)
- Data mirroring (independent copies can verify)

*Detection:*
- Users can verify their submissions unchanged
- Community audits event chain
- Mirrors detect divergence

*Recovery:*
- Restore from clean mirror
- Revert tampered data
- Public disclosure of incident

---

**6. Infrastructure Compromise (Availability)**

*Attack:* DDoS, resource exhaustion, account takeover to take service down

*Impact:* MEDIUM - Users can't access data during negotiation

*Current defenses:*
- Cloudflare DDoS protection
- Cost monitoring with kill switches
- Regular data exports (service can be reconstructed)
- Offline app caching

*Recovery:*
- Service can be restored from exports
- Community can spin up mirrors
- Data survives even if service doesn't

---

**7. Malicious Code Deployment**

*Attack:* Compromised maintainer pushes update that steals recovery phrases

*Impact:* HIGH - User private keys compromised

*Current defenses:*
- Open source (community can review)
- Multiple maintainer signatures required for releases
- Reproducible builds (verify binary matches source)
- Code review process (all PRs visible)

*Why this is hard for attacker:*
- Malicious code visible in open source
- Requires multiple compromised maintainers (for signatures)
- Community reviews code before releases
- Users can audit and verify builds

---

**8. Social Engineering / Phishing**

*Attack:* Fake app that looks like ours, steals recovery phrases

*Current defenses:*
- Official distribution channels only (App Store, Google Play)
- Signed releases with public key fingerprints
- User education about official sources

*User responsibility:*
- Download only from official sources
- Verify signing keys
- Never enter recovery phrase into websites
- Be wary of fake apps with similar names

---

**9. Collusion Between Users**

*Attack:* Group coordinates to boost fake data (reputation farming then submitting false data)

*Current defenses:*
- Reputation must be earned over time (costly)
- Statistical validation (coordinated submissions look suspicious)

*Additional mitigations:*
- Social graph analysis (detect coordinated behavior)
- Submission pattern similarity detection
- Reputation decay if inactive
- Flag sudden changes in behavior

*Cost to attacker:* Significant time investment to build multiple trusted accounts

---

**10. Statistical Inference Attacks**

*Attack:* With enough data points, infer individual submissions from aggregates

*Current defenses:*
- Minimum N thresholds (15-25 depending on level)
- Regional aggregation (larger anonymity sets)
- Suppress rare procedures at small facilities
- Add noise to small cells if needed

*Residual risk:*
- Very rare procedures may still be vulnerable
- Cross-referencing with other datasets possible
- Perfect anonymity impossible for unique cases

*Acceptance:* Users informed, choose whether to submit rare procedures

---

## Development Roadmap

### Phase 1: MVP (Months 1-9)

**Goal:** Prove the concept with medical bills

**Reality check:** Volunteers working spare time (5-10 hours/week realistic)
- Core team of 3-5 developers needed minimum
- Expect slower progress than full-time development
- Build incrementally, test early and often
- Celebrate small wins to maintain momentum

**Deliverables:**
- Mobile app (iOS and/or Android)
  - Camera capture
  - On-device OCR
  - Interactive redaction
  - Submission flow
  - Basic search
- Backend API
  - Submissions endpoint
  - Search/aggregation endpoint
  - Basic moderation queue
- Database with initial data
  - Seed with bills from founder and early volunteers
  - Regional aggregation working
- Landing page
  - Mission explanation
  - Download app
  - View data (web)
  - Technical documentation

**Success criteria:**
- 500+ verified submissions
- 50+ different procedures covered
- Multiple metro areas represented
- First success story: user negotiates bill using our data
- App is stable and usable
- Regional aggregation provides useful data

### Phase 2: Scale & Validate (Months 10-18)

**Goal:** Grow user base, validate model

**Note:** Phase 2 starts only after MVP is stable and being used

**Enhancements:**
- Web search interface (browse without app)
- Improved moderation tools
  - Automated flagging
  - Moderator dashboard
  - Public audit log viewer
- User reputation system refinement
- More validation patterns (insurance types)
- Analytics dashboard (aggregate stats only)
- Data export API for researchers

**Growth:**
- 5,000+ submissions
- 10+ metro areas
- Media coverage
- Partner with patient advocacy groups
- Community moderators recruited

**Success criteria:**
- Demonstrable bill reductions for users
- Media coverage in healthcare/tech press
- Active community of contributors
- Self-sustaining moderation
- Trust system working well

### Phase 3: Expand Scope (Months 18-36+)

**Goal:** Expand beyond medical bills

**Note:** Only pursue if Phase 1 & 2 successful and community is sustainable

**New categories:**
- Auto repairs
- Legal fees
- Home services (HVAC, plumbing, electrical)
- Funeral costs
- Vet bills
- Other opaque markets

**Platform improvements:**
- Multi-category support
- Better search/filtering
- Facility type detection improvements
- Mobile app enhancements
- Community features (success stories, forums)
- Advanced analytics

**Success criteria:**
- 50,000+ submissions across multiple categories
- National coverage (US)
- API adoption by researchers/journalists
- Policy impact (cited in transparency discussions)
- Self-sustaining community
- Financial sustainability (donations/grants if needed)

---

## Open Questions (For Technical Lead)

These are decisions best made with the development team:

**1. Mobile framework:** React Native vs Native iOS/Android?
- Trade-off: Speed to market (RN) vs Performance (Native)
- Depends on developer expertise
- Both are viable

**2. Backend language:** Node.js vs Python vs Go?
- All viable options
- Depends on team skills and preferences

**3. Database details:** PostgreSQL configuration, indexing strategy
- Leaning PostgreSQL for structured data + aggregations
- Need to optimize for common queries

**4. Hosting specifics:** AWS vs GCP vs Cloudflare vs other?
- Budget: $100/month
- Serverless preferred for cost efficiency
- Open to discussion

**5. OCR library:** ML Kit vs Tesseract vs Vision vs commercial?
- Must work on-device
- Trade-offs: accuracy, cost, privacy
- Good enough > perfect

**6. PII detection approach:** Regex + NER vs ML model vs hybrid?
- Must be privacy-preserving
- High recall critical for first-pass automated detection
- User review is the final safety layer
- Can iterate and improve over time

**7. Aggregation algorithm:** Specific thresholds, variance calculations
- Need to tune based on real data
- Start conservative, relax if needed

**8. Audit log format:** Specific schema, retention policy
- Must be tamper-evident
- Public vs private portions
- Storage considerations

---

## Success Metrics

### Technical Metrics
- App crash rate < 1%
- OCR accuracy > 90%
- PII detection recall > 95% (first-pass automated detection, before user review)
- API response time < 500ms (p95)
- Database query performance (queries under 200ms)
- Server costs staying under budget

### Product Metrics
- Submissions per week (growth trend)
- Unique contributors (retention)
- Users who submit multiple times (engagement)
- Search queries (utility)
- Success stories (impact)
- App store ratings

### Impact Metrics
- Total dollar value of bills submitted
- Estimated savings for users (based on negotiated prices)
- Metro areas covered
- Procedures covered
- Media mentions
- Policy citations
- Partner organizations

### Community Health
- Active moderators
- Community upvotes/confirmations
- Low flag rate (quality submissions)
- Code contributors
- Public audit log reviews

---

## Contributing

We're recruiting developers now. This is an open source, volunteer-driven project.

**What we need:**
- Mobile developers (React Native, iOS, or Android)
- Backend developers (API, database)
- ML/Data specialists (OCR, validation)
- DevOps (infrastructure, deployment)
- Design (UX/UI)
- Security reviewers
- Documentation writers

**What we have:**
- Clear mission with real impact
- Real data ready (founder and volunteer bills)
- Funded infrastructure ($100/month)
- Domain and brand (costintelagency.org)
- Committed leadership
- Privacy-first architecture
- Open source from day one

**How to get involved:**
Contact: [your email address]

**We're building:**
- Something that matters (saves people money)
- Something transparent (open source, auditable)
- Something lasting (community-owned)
- Something you'll be proud of

---

## License

**To be decided** with initial team. Options:
- MIT (permissive, maximum adoption)
- GPL (copyleft, derivatives must be open)
- AGPL (GPL + network use = distribution)

Open to team input on best choice for project goals.

---

## Appendix: Related Work & Context

**Similar efforts:**
- Clearity Health (2021) - Pivoted to government data, subscription model
- Pricing Healthcare (2012) - Status unclear
- Fair Health / Healthcare Bluebook - Use insurance claims data (not crowdsourced)
- Turquoise Health - Aggregates hospital price transparency files

**What we're doing differently:**
- Open source (community-owned, can't be bought out)
- Privacy-first (zero-knowledge architecture)
- Mobile-first (matches user behavior)
- Regional aggregation (better privacy + utility)
- Start small, prove value (not trying to boil the ocean)
- Expandable beyond healthcare (any opaque pricing)

**Policy context:**
- Hospital Price Transparency Rule (2021) requires hospitals to publish negotiated rates
- Compliance is poor, data is often buried and unusable
- No Surprises Act (2022) protects against some surprise bills
- Growing policy momentum for price transparency
- We complement policy with grassroots action

**Market size:**
- 23 million uninsured Americans
- 100+ million with high deductible plans
- Medical debt affects 100+ million people
- $88 billion in medical debt in collections
- This is a massive problem affecting real people

---

**Document Version:** 2.0  
**Last Updated:** December 2024  
**Status:** Design Phase - Recruiting Developers

---

*The Cost Intelligence Agency is building a consumer spy network for price transparency. Join us.*

**Cost Intelligence Agency**  
*Crowdsourced price intelligence for everything.*  
*Your bills. Our data. Everyone's benefit.*
