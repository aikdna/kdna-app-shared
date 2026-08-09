# KDNA App Shared

[![CI](https://github.com/aikdna/kdna-app-shared/actions/workflows/ci.yml/badge.svg)](https://github.com/aikdna/kdna-app-shared/actions/workflows/ci.yml) [![License](https://img.shields.io/badge/license-Apache%202.0-blue)](LICENSE)

**Shared Swift application infrastructure for KDNA-powered Apple apps: API
clients, models, utilities, and UI presentation helpers for KDNA
authorization and workspace attachment state.**

This package is the platform-neutral building block used by KDNA apps. It
provides:

- **API layer** — protocol-based AI provider abstraction with streaming and
  structured logging
- **Models** — shared request/response types, search models, reasoning-effort
  configuration
- **Utilities** — SSE stream parsing, MIME type detection, provider
  identification, streaming task lifecycle management
- **Authorization presentation** — UI-facing presentation helpers that render
  KDNA Core LoadPlan results without defining protocol facts
- **Workspace attachment presentation** — validation and UI-ready models for the
  exact CLI status output (identity, digest, scope, state, reason, control
  actions)

> New to KDNA? → [KDNA Core](https://github.com/aikdna/kdna)
>
> Need the Swift protocol/runtime implementation? →
> [kdna-core-swift](https://github.com/aikdna/kdna-core-swift)
>
> Building an authoring app? →
> [kdna-studio-swift](https://github.com/aikdna/kdna-studio-swift)

---

## Install

Add the dependency to your `Package.swift`:

```swift
.package(url: "https://github.com/aikdna/kdna-app-shared.git", from: "0.5.0")
```

Then add `KDNAAppShared` to your target dependencies:

```swift
.product(name: "KDNAAppShared", package: "kdna-app-shared")
```

Requires macOS 13+ or iOS 16+.

---

## Quick start

1. **Get a LoadPlan from Core.** Run the exact runtime `kdna-core-swift` against
   a `.kdna` file to obtain the official LoadPlan result.
2. **Map it to presentation state.** Translate the Core output into
   `KDNALoadPlanPresentationInput`.
3. **Render through `KDNAAuthorizationPresentation`.** The helpers turn Core
   states into labels, severity, symbols, and actions for your authorization UI.

For workspace attachments, feed the exact CLI status JSON to
`KDNAWorkspaceAttachmentStatusDecoder`. It accepts only the bounded status
output emitted by the runtime CLI, rejects unknown fields and digest/snapshot
mismatches, and maps records to content-neutral presentation state.

---

## What this package is NOT

- Not a KDNA protocol runtime — use `kdna-core-swift`
- Not an authoring engine — use `kdna-studio-swift`
- Not a UI framework
- Not the source of truth for access modes, entitlement profiles, LoadPlan
  states, crypto profiles, import security, or runtime projection policy

Presentation code must keep the active asset identity, exact version or digest,
attachment scope, reason, and disable/switch/rollback actions visible. It must
not decide whether a KDNA can load, and it never reads or parses
`.kdna/attachments.json`. Saving or opening a file is not authorization.

---

## Status

- **Pre-release.** The package pins the published Swift Core `0.21.0` release
  and is source-compatibility evidence, not an App Shared or Swift Core
  release.
- App teams should map verified Core output into
  `KDNALoadPlanPresentationInput` and render it through
  `KDNAAuthorizationPresentation`.

See [Docs/AUTHORIZATION_PRESENTATION.md](Docs/AUTHORIZATION_PRESENTATION.md)
for the detailed presentation contract.

## License

Apache-2.0
