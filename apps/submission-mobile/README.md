# Submission Mobile App (Dead Drop)

Mobile application for submitting bills and pricing intelligence to the Cost Intelligence Agency network.

## Status

**Phase:** Planning  
**Tech Stack:** To be decided (React Native vs Native)

## Purpose

Enable users to quickly and privately submit their medical bills (and other pricing data) by:
1. Taking a photo of their bill
2. Automatic OCR and data extraction
3. Interactive PII redaction
4. Cryptographic signing and submission

## Privacy Features

- **On-device processing only** - Sensitive data never leaves the device
- **Interactive redaction** - User confirms all PII is hidden
- **Cryptographic identity** - No email, no name, no account
- **Proof of possession** - Document hash without storing document

## Key Features (Planned)

- Camera integration
- On-device OCR (ML Kit / Tesseract / Vision)
- Document format detection (EOB vs bill)
- Field extraction (procedure codes, amounts, dates)
- PII detection and redaction
- Data validation and confidence scoring
- Cryptographic key generation and signing
- Offline support
- Delayed publication (random 6hr-7day delay)

## Technical Requirements

- Must work offline (except for submission)
- Must support iOS and Android
- Must integrate with device secure enclave for keys
- Must handle poor photo quality gracefully
- Must provide clear user feedback

## Development Status

- [ ] Technology stack decision
- [ ] Architecture design
- [ ] UI/UX wireframes
- [ ] Crypto library selection
- [ ] OCR library selection
- [ ] PII detection approach
- [ ] Camera integration
- [ ] Development environment setup

## Contributing

See [CONTRIBUTING.md](../../CONTRIBUTING.md) for how to get involved.
