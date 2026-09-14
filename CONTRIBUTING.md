# Contributing to KDNA App Shared

This Swift package provides API/model/stream infrastructure and display helpers.
Its Read presentation adapter consumes the public Core/Read result; it does not
authenticate supplied values, copy the disclosed body, or grant permissions.

## Development

Use an Apple Swift toolchain that supports the Swift 5.9 package manifest,
Python 3, and Xcode with an iOS SDK for the complete verification. The manifest
declares macOS 13 and iOS 16 deployment targets. Core is resolved from the exact
public Git revision in `Package.swift` and `Package.resolved`.

```sh
git clone https://github.com/aikdna/kdna-app-shared.git
cd kdna-app-shared
python3 scripts/check_public_surface.py
python3 scripts/test_public_surface.py
python3 scripts/verify_native.py --work-dir ../kdna-app-shared-check --ios
```

The work directory must be new and outside the checkout. The native runner
builds debug/release, runs the full suite, runs separate public consumers in
both configurations, checks retired-type compilation fails for the intended
missing symbols, and compiles a generic iOS target without signing. Omit
`--ios` for a macOS-only run. Direct `swift build` and `swift test` also work.

## Contract and review

- Preserve the separate Read channels and observed identity, request, state and delivery facts.
- Reproduce an actual failure and include a regression before changing behavior.
- Do not change expected fixture output or a binding merely to hide a mismatch.
- Keep API/model/stream helpers and the legacy workspace relationship view separate from Read authority.
- Keep excluded loading presentation sources/tests as history; do not add a compatibility alias that implies action permission.
- Update the exact source/test inventory when a reviewed contract change requires it.

The public gate retains private-name detection, exact native input hashes,
original public byte preservation, the pinned dependency, the complete suite,
consumer configurations and iOS compilation. Its mutation tests must continue
to reject missing fixtures, changed inputs, partial coverage and local or moving
dependency coordinates. SwiftPM target constants and GitHub action tags
are third-party version syntax, not KDNA capability names.

Required GitHub checks are `build`, `Analyze (swift)`, `Analyze (python)` and
`Analyze (actions)`. The analysis checks come from GitHub CodeQL default setup.
Keep those contexts and the current CI coverage when editing workflows.

Update public documentation when behavior changes and describe the exact input
coordinate and validation in the PR. Contributions use Apache 2.0.
