# Changelog

## Unreleased

- Re-certify the presentation-only package against exact final Swift Core main
  `95f638e2f0472a375704fb5fe2f057de0cb4cb07` without moving protocol or
  attachment-selection authority into App Shared.
- Restore the declared generic iOS build by using Application Support instead
  of the macOS-only home-directory API and compiling the `NSEvent` swipe helper
  only on macOS; CI now proves both macOS tests and a generic iOS target.

This is an unpublished source candidate. No existing package release changes.

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

27 commits from 2026-05-30 initial shared native application types through
2026-05-31 WebSearchProvider selection persistence repair.

See [GitHub Releases](https://github.com/aikdna/kdna-app-shared/releases) for detailed version history.
