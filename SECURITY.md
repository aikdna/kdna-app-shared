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

`kdna-app-shared` is a pre-release package for shared Apple application infrastructure.
Security support continues to track the latest tagged KDNA Protocol release in
`aikdna/kdna` and the latest mainline pre-releases of `kdna-core-swift` and
`kdna-app-shared`. Older Swift pre-release versions may receive critical
security patches on a case-by-case basis.

### Current dependency inputs

| Component | Current input |
|-----------|---------------|
| KDNA App Shared | Candidate coordinate in `public-contract-binding.json` |
| KDNA Core Swift | Exact public Git revision in `Package.swift` and `Package.resolved` |
| Core / canonical IR / Read | `kdna.core/0.3.0` / `kdna.canonical-ir/0.2.0` / `kdna.read/0.2.0` |

The binding governs this candidate's tested contract; a new upstream commit
does not automatically change its dependency inputs.

## About This Package

This package maps supplied public Read results into display values. It does
not implement cryptographic primitives, authenticate caller-supplied values,
disclose the Read body, produce a runtime capsule, or authorize actions.
Applications must retain the actual Core/Read result and trusted provider
boundary. A ready label or delivery label is not permission to reuse content
or evidence of remote consumption.

The legacy workspace relationship decoder is a separate display surface. Its
relationship labels and action request names neither execute operations nor
grant Read/action permission. The excluded loading presentation APIs remain
historical and are not supported compatibility paths.

For the KDNA Protocol security architecture, see
[GOVERNANCE.md](https://github.com/aikdna/kdna/blob/main/docs/GOVERNANCE.md)
in the main protocol repository.

Report misleading ready states, identity/correlation mismatches, unintended
body disclosure or authority confusion through the private channels above.
Use synthetic data and include the exact package/dependency revision, toolchain
and minimal reproduction. Do not include real credentials or private assets.

## Best Practices

- Never commit secrets, API keys, or credentials
- Use signed commits when possible
- Review your PRs for accidental inclusion of sensitive data
- Keep dependencies up to date
