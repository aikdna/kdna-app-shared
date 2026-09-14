# Public Read presentation contract

This document describes the current `KDNAAppShared` candidate identified in the package binding. Its historical filename is retained for existing documentation links.

## Input and output

`KDNAReadPresentation.from(readResult:assetTitle:)` accepts a `KDNAValue` returned by the public Swift `KDNARead` execution methods. SwiftPM resolves the exact public Core revision in `Package.swift` and `Package.resolved`. The package binding records its `KDNACore 0.4.0-rc.component-semantics.1` contract and the corresponding accepted source-archive provenance. App Shared maps values already produced by that API; it has no new wire JSON decoder, asset parser, protocol validation engine, or Host policy provider.

| Result | Presentation |
| --- | --- |
| Current ready Read envelope | Content available; exact observed identity, snapshot, A/C/E digests, selected judgment, state strings and delivery |
| Rejected Read envelope | Content withheld; actual request correlation, diagnostics, state strings and delivery |
| Admission rejection | Request rejected; validated request correlation and actual admission diagnostic reason |
| Control without a body | Body withheld; actual control code and semantic cause |
| Transport failure | Delivery unconfirmed; no body or asset identity presented |
| Unsupported/mixed/contradictory display input | Unsupported, with no inferred permission or ready display |

The adapter retains state strings as observations. Core validity, interpretation, writer, confirmation, read permission, and action authorization remain separate. A ready response with action authorization `not_evaluated` remains unevaluated. Read permission does not imply action authorization. A delivery label is not an end-to-end acknowledgment.

Only a current ready envelope with disclosed content, displayed A/C/E observations, writer/confirmation state strings, compatible state fields, and matching receipt request/snapshot references yields the ready display. Unknown or legacy mixed envelope fields yield an unsupported display. These checks prevent accidental presentation of known incompatible shapes; they do not authenticate the source or replace the public Read contract's verifier. A caller can construct a `KDNAValue`, so the application must preserve where its actual Read result came from.

## Component and declaration boundary

The dependency supplies the finite component interpretations and method declaration presence in its public Read closure. Applications retain that exact Read body separately from this display model. App Shared does not infer a method from an empty array, label missing declarations as evaluated, or introduce a component parser. A ready display still means only that the supplied current response was disclosed. Rejected component diagnostics remain withheld and visible as their actual codes.

## Retired loading presentation

`KDNALoadPlanPresentationInput` and `KDNAAuthorizationPresentation` are excluded from the current library target. Their old source and tests remain exact historical bytes. The old `canLoadNow` boolean previously took precedence over conflicting display state; it is not carried into the new API. There are no password/license/account/remote-runtime action inferences, RuntimeCapsule adapters, or loading-capability constructors.

The existing severity enum `KDNAAuthorizationPresentationSeverity` keeps its name and cases for UI compatibility. It is a display category only, never a protocol or permission state.

## Workspace relationship compatibility

The existing bounded legacy CLI status decoder and relationship presentation remain separate. They accept `kdna.workspace-attachments` schema `0.1.0`, not a public Read result. They do not parse assets, read workspace files, or feed their state into the new adapter. “Enabled” describes a relationship; it cannot authorize disclosure or execution. Relation action values are UI request names, not callable operations or permission grants. A caller remains responsible for its actual command and authorization boundary.

Applications migrating from the excluded loading interfaces must call the current public Read API and retain its trusted provider boundary. The display adapter supplies no compatibility shim for retired loading or execution authority.

## Verification

Run `scripts/verify_native.py` with a new external work directory to build and test the pinned package and consume its public API in debug and release configurations. It compiles the current consumer before checking that both retired public types fail compilation with missing-type diagnostics. The complete XCTest suite retains actual Core/Read integration, component, display, workspace and infrastructure assertions. Generic iOS compilation is a separate leg; runtime behavior on iOS requires device testing.
