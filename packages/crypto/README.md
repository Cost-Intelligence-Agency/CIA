# Crypto Package

Cryptographic identity and signing functionality for Cost Intelligence Agency.

## Status

**Phase:** Planning

## Purpose

Provide zero-knowledge user identity through cryptographic keys:
- Generate private/public key pairs
- Derive BIP39 recovery phrases (12 words)
- Sign submissions with private keys
- Verify signatures with public keys
- Hash public keys for anonymous identifiers

## Features (Planned)

- **Key Generation**
  - Secure random key generation
  - BIP39 mnemonic phrase (12 words)
  - Deterministic key derivation
  - Secure enclave storage (mobile)

- **Signing**
  - Sign submission data
  - Signature includes timestamp
  - Standard algorithms (Ed25519 or similar)

- **Verification**
  - Verify signatures server-side
  - Prevent replay attacks
  - Detect tampering

- **Identity**
  - Hash(public_key) = anonymous user ID
  - No email, no name, no real identity
  - Recoverable from 12-word phrase

## Technical Requirements

- Must work on iOS and Android (native crypto)
- Must work on backend (Node.js/Python/Go)
- Standard algorithms (well-reviewed, not custom)
- Secure key storage in device enclave
- Clear error handling

## Security Considerations

- Private keys never leave device
- Recovery phrase shown once, user must save it
- No cloud backup of keys (by design)
- Lost phrase = lost identity (like crypto wallet)

## Development Status

- [ ] Technology stack decision
- [ ] Algorithm selection (Ed25519, ECDSA, etc.)
- [ ] BIP39 library selection
- [ ] Platform-specific secure storage
- [ ] API design
- [ ] Test suite with known vectors
- [ ] Security review

## Contributing

See [CONTRIBUTING.md](../../CONTRIBUTING.md) for how to get involved.
