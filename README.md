# KDNA App Shared

[![CI](https://github.com/aikdna/kdna-app-shared/actions/workflows/ci.yml/badge.svg)](https://github.com/aikdna/kdna-app-shared/actions/workflows/ci.yml) [![License](https://img.shields.io/badge/license-Apache%202.0-blue)](LICENSE)

Shared Swift package for platform-neutral app infrastructure used by KDNA Chat, KDNA Studio, and KDNA iOS apps.

> **Status: pre-release recertification candidate.** The package manifest and
> resolved graph pin final Swift Core main
> `95f638e2f0472a375704fb5fe2f057de0cb4cb07`. This is source-candidate
> compatibility evidence, not a new App Shared or Swift Core release.

## Scope

This package provides:

- **API layer** — Protocol-based AI provider abstraction (`APIProtocol`, `BaseAPIHandler`), streaming support, structured logging
- **Models** — Shared request/response types, search models (Tavily, Exa), reasoning effort configuration
- **Utilities** — SSE stream parsing, MIME type detection, provider identification, streaming task lifecycle management
- **Authorization presentation** — Shared UI-facing presentation helpers that
  render Swift Core LoadPlan results without defining protocol facts
- **Workspace attachment presentation** — Exact CLI status DTO validation and
  UI-ready identity, digest, scope, state, reason, and control models; no
  attachment storage or mutation authority

For KDNA authorization UI, this package may contain presentation helpers such as:

- LoadPlan-to-UI presentation state
- Keychain-backed SecretStore adapters
- license status view models
- shared open/attachment error presentation

The unpublished recertification candidate pins one exact final Swift Core main
revision. The published App Shared line still predates that coordinate. Apps
should map verified Core output into
`KDNALoadPlanPresentationInput` and render it through
`KDNAAuthorizationPresentation`.

See [Docs/AUTHORIZATION_PRESENTATION.md](Docs/AUTHORIZATION_PRESENTATION.md).

## What this package is NOT

- Not a KDNA protocol runtime (use `kdna-core-swift`)
- Not an authoring engine (use `kdna-studio-swift`)
- Not a UI framework
- Not the source of truth for access modes, entitlement profiles, LoadPlan
  states, crypto profiles, import security, or runtime projection policy

## Dependencies

- [kdna-core-swift](https://github.com/aikdna/kdna-core-swift) — KDNA Core

`kdna-app-shared` must import protocol/runtime facts from `kdna-core-swift`.
KDNA Chat and KDNA Studio should not define authorization state by reading raw
manifest fields in this package.

This package may translate Core states into labels, severity, symbols, and
actions. It must not decide whether a KDNA can load.

Saving or opening a file is not authorization. Presentation code must keep the
active asset identity, exact version or digest, attachment scope, reason, and
disable/switch/rollback actions visible.

`KDNAWorkspaceAttachmentStatusDecoder` accepts only the exact bounded status
JSON emitted by the runtime CLI. It rejects unknown fields and digest/snapshot
mismatches, then maps records to content-neutral presentation state. Apps must
still send every attach, enable/disable, switch, rollback, or remove operation
to the exact runtime CLI; App Shared never reads `.kdna/attachments.json`.

## Platforms

macOS 13+ / iOS 16+

## License

Apache-2.0
