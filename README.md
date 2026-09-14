# KDNA App Shared

Shared Swift API clients, request/response models, stream utilities, and display helpers for Apple applications.

This pre-release package exposes the current Read presentation contract at the candidate coordinate in [public-contract-binding.json](public-contract-binding.json). SwiftPM resolves the exact public Core Git revision in `Package.swift` and `Package.resolved`. The binding preserves the corresponding Core contract and source-archive provenance; it does not assert a package tag or registry release.

The package declares macOS 13 and iOS 16 deployment targets. CI runs macOS builds, tests and public consumers, plus generic iOS device compilation. The iOS leg does not establish runtime behavior on a physical device.

## Installation

Clone [aikdna/kdna-app-shared](https://github.com/aikdna/kdna-app-shared), check out the exact revision you intend to use, and add it as a SwiftPM path dependency. Select the `KDNAAppShared` product in your application target. The Core dependency is resolved from its pinned public Git coordinate; a sibling Core checkout is not required.

```swift
.package(path: "../kdna-app-shared")
// In the application's target dependencies:
.product(name: "KDNAAppShared", package: "kdna-app-shared")
```

## Public Read presentation

Pass the result of `KDNARead.readBytes`, `readFile`, or `readSnapshot` to the display adapter:

```swift
import KDNACore
import KDNAAppShared

let result = await KDNARead.readBytes(
    bytes, request: request, control: trustedControl, host: trustedHost
)
let presentation = KDNAReadPresentation.from(
    readResult: result, assetTitle: "Review"
)
// Render presentation.statusText, diagnosticCodes and observedStates.
```

Current binding uses public Core/IR/Read contracts `0.3.0`/`0.2.0`/`0.2.0` and the component definition digest declared in the binding. Ordinary, taxonomy and differential judgments stay in the caller's actual public Read content. Method absence and declared empty collections are preserved by Core/Read; this content-neutral display adapter does not collapse, reinterpret, or copy those bodies.

The adapter distinguishes a Read envelope, admission rejection, control without a body, and unconfirmed transport. It keeps observed identity, version, digests, request correlation, state strings, and delivery information separate. It does not copy the disclosed body into the presentation.

“Read content available” describes the supplied response. It does not grant permission to reuse content, load a runtime, execute an action, or create model context. The adapter cannot authenticate a caller-supplied `KDNAValue`; callers must retain the actual public Read result and the trusted Host boundary. Delivery labels are the returned local Read facts, not proof of remote consumption.

The old `KDNALoadPlanPresentationInput` and `KDNAAuthorizationPresentation` interfaces are excluded from current targets. The former `canLoadNow` and password/license/runtime actions have no compatibility shim. Their source and tests remain historical material. See [Docs/AUTHORIZATION_PRESENTATION.md](Docs/AUTHORIZATION_PRESENTATION.md) and [surface-disposition.json](surface-disposition.json).

## Other shared infrastructure

API provider abstractions, models, reasoning and attachment compatibility helpers, SSE parsing, MIME detection, provider identifiers, and stream lifecycle helpers retain their existing behavior. Importing this package does not initialize an API service or perform a network request.

The existing `KDNAWorkspaceAttachmentStatusDecoder` accepts the bounded legacy CLI `kdna.workspace-attachments/0.1.0` status representation. Its enabled/disabled labels describe workspace relationships. Its enable/disable/switch/rollback/remove values name UI requests that a caller may handle; they do not authorize or perform those operations. This separate view is not current public Read input and is never converted into Read permission by this package. It does not read `.kdna/attachments.json`.

## Verification

```sh
python3 scripts/check_public_surface.py
python3 scripts/test_public_surface.py
python3 scripts/verify_native.py --work-dir ../kdna-app-shared-check --ios
```

Use a new work directory outside the checkout. The native runner builds debug and release, runs the complete current test suite, builds and runs independent public-API consumers in both configurations, proves retired types cannot compile, and builds for a generic iOS device without signing. Omit `--ios` for macOS-only verification. Build products and caches use the supplied directory.

The suite uses real Core/Read calls and synthetic component fixtures, rejected and mixed display inputs, and workspace/infrastructure regressions. Exact current source and test bytes are recorded in `public-inputs.json`. Historical code remains excluded from active targets; preserved original public files are inventoried in `public-history.json`.

Apache-2.0. See [LICENSE](LICENSE) and [NOTICE](NOTICE).
