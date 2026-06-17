# KDNA App Shared

[![CI](https://github.com/aikdna/kdna-app-shared/actions/workflows/ci.yml/badge.svg)](https://github.com/aikdna/kdna-app-shared/actions/workflows/ci.yml) [![License](https://img.shields.io/badge/license-Apache%202.0-blue)](LICENSE)

Shared Swift package for platform-neutral app infrastructure used by KDNA Chat, KDNA Studio, and KDNA iOS apps.

## Scope

This package provides:

- **API layer** — Protocol-based AI provider abstraction (`APIProtocol`, `BaseAPIHandler`), streaming support, structured logging
- **Models** — Shared request/response types, search models (Tavily, Exa), reasoning effort configuration
- **Utilities** — SSE stream parsing, MIME type detection, provider identification, streaming task lifecycle management

## What this package is NOT

- Not a KDNA protocol runtime (use `kdna-core-swift`)
- Not an authoring engine (use `kdna-studio-swift`)
- Not a UI framework

## Dependencies

- [kdna-core-swift](https://github.com/aikdna/kdna-core-swift) — KDNA Core

## Platforms

macOS 13+ / iOS 16+

## License

Apache-2.0
