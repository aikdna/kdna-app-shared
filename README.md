# KDNA App Shared

[![CI](https://github.com/aikdna/kdna-app-shared/actions/workflows/ci.yml/badge.svg)](https://github.com/aikdna/kdna-app-shared/actions/workflows/ci.yml) [![License](https://img.shields.io/badge/license-Apache%202.0-blue)](LICENSE)

Shared Swift package for platform-neutral app infrastructure used by KDNA Chat, KDNA Studio, and KDNA iOS apps.

> **Status: recertification pending.** The package manifest declares
> `kdna-core-swift` with a `0.4.0` lower bound and `Package.resolved` still
> resolves `0.4.0`, while the current published Swift Core line is `0.20.x`.
> This package predates the current Swift Core contract and must not be
> treated as compatible with it until exact-coordinate recertification lands.
> See the dependency note under Scope below.

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
- shared open/attachment error presentation

The published package manifest declares `kdna-core-swift` with a `0.4.0` lower
bound rather than an exact pin. This repository predates the current Swift Core
contract and requires exact-coordinate recertification before it can claim
current compatibility. Apps should map verified Core output into
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

## Platforms

macOS 13+ / iOS 16+

## License

Apache-2.0
