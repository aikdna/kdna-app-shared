# KDNA App Shared

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

- [kdna-core-swift](https://github.com/aikdna/kdna-core-swift) — KDNA Protocol core library

## Platforms

macOS 13+ / iOS 16+

## License

Apache-2.0
