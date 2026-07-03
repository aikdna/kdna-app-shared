# Security Policy

## Reporting a Vulnerability

Please **do not** report security vulnerabilities through public GitHub issues.

Instead, use one of these private channels:

- **GitHub Private Vulnerability Reporting**: Go to the [Security Advisories](https://github.com/aikdna/kdna-app-shared/security/advisories/new) page
- **Email**: security@aikdna.com

We aim to respond within 72 hours and provide a timeline for resolution within
1 week. Please do not disclose the vulnerability publicly until we have had a
chance to address it.

## Supported Versions

`kdna-app-shared` is a public beta support surface for shared KDNA Apple app
infrastructure.

| Component | Supported Versions |
|-----------|-------------------|
| KDNA Protocol | Latest tagged release in `aikdna/kdna` |
| kdna-core-swift | Latest mainline beta release |
| kdna-app-shared | Latest mainline beta release |

Older Swift beta versions may receive critical security patches on a
case-by-case basis.

## About This Package

This package (`kdna-app-shared`) is a **UI presentation layer** for KDNA authorization states. It does NOT implement cryptographic primitives itself.

The security model for KDNA assets is defined and implemented in:

- **`aikdna/kdna`** — Core protocol, crypto profiles, LoadPlan authorization, container validation
- **`aikdna/kdna-core-swift`** — Swift runtime with crypto parity

For the KDNA Protocol security architecture, see
[GOVERNANCE.md](https://github.com/aikdna/kdna/blob/main/docs/GOVERNANCE.md)
in the main protocol repository.

## Best Practices

- Never commit secrets, API keys, or credentials
- Use signed commits when possible
- Review your PRs for accidental inclusion of sensitive data
- Keep dependencies up to date
