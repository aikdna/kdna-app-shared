# KDNA App Shared

[![CI](https://github.com/aikdna/kdna-app-shared/actions/workflows/ci.yml/badge.svg)](https://github.com/aikdna/kdna-app-shared/actions/workflows/ci.yml) [![License](https://img.shields.io/badge/license-Apache%202.0-blue)](LICENSE)

Shared Swift package for platform-neutral app infrastructure used by KDNA Chat, KDNA Studio, and KDNA iOS apps.

## Scope

This package provides:

- **API layer** — Protocol-based AI provider abstraction (`APIProtocol`, `BaseAPIHandler`), streaming support, structured logging
- **Models** — Shared request/response types, search models (Tavily, Exa), reasoning effort configuration
- **Utilities** — SSE stream parsing, MIME type detection, provider identification, streaming task lifecycle management
- **Authorization presentation** — Shared UI-facing presentation helpers that
  render Swift Core LoadPlan results without defining protocol facts

For KDNA authorization UI, this package may contain presentation helpers such as:

- LoadPlan-to-UI presentation state
- Keychain-backed SecretStore adapters
- license status view models
- shared import/install error presentation

The current `kdna-core-swift` package dependency is pinned to revision
`0c94032bea8677167e7d57e8d914d9e29bef9edf` until the next stable Core tag
publishes the current LoadPlan/runtime APIs. Apps should map Core output into
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

## Platforms

macOS 13+ / iOS 16+

## License

Apache-2.0
