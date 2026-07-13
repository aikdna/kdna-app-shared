# Changelog

## 0.5.0 — 2026-07-13

- Move the minimum Swift Core dependency to 0.4.0 so application presentation
  code consumes the current account/device entitlement LoadPlan contract.
- Keep all authorization decisions in Core; this package only maps verified
  Core state into UI-facing presentation models.

## 0.4.1 — 2026-07-13

- Replace the temporary Core revision pin with the stable
  `kdna-core-swift` 0.3.1 dependency.
- Keep authorization decisions in Core and presentation-only mapping here.

## Current — 2026-06-02

27 commits from 2026-05-30 feat: KDNAAppShared — shared types between KDNaStudio and KDNAChat to 2026-05-31 Fix WebSearchProvider.selected UserDefaults key mismatch (was 'WebSearchProvider', now 'webSearchProvider').

See [GitHub Releases](https://github.com/aikdna/kdna-app-shared/releases) for detailed version history.
