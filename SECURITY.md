# Security Policy

## Reporting a Vulnerability

If you discover a security vulnerability in KDNA, please **do not** open a public issue.

Email: **security@aikdna.com**

We will respond within 48 hours and work with you on a coordinated disclosure timeline.

## About This Package

This package (`kdna-app-shared`) is a **UI presentation layer** for KDNA authorization states. It does NOT implement cryptographic primitives itself.

The security model for KDNA assets is defined and implemented in:

- **`aikdna/kdna`** — Core protocol, crypto profiles, LoadPlan authorization, container validation
- **`aikdna/kdna-core-swift`** — Swift runtime with crypto parity

## Best Practices

- Never commit secrets, API keys, or credentials
- Use signed commits when possible
- Review your PRs for accidental inclusion of sensitive data
- Keep dependencies up to date
