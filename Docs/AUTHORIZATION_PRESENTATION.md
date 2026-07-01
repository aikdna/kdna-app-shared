# KDNA Authorization Presentation

Status: Implementation Contract
Normative: No
Protocol Source of Truth: `aikdna/kdna` and `kdna-core-swift`

`kdna-app-shared` provides shared presentation helpers for Apple apps. It does
not decide whether a `.kdna` file can load.

## Boundary

KDNA Chat and KDNA Studio MUST request authorization state from Swift Core.
They MUST NOT infer authorization directly from raw manifest fields.

This package MAY translate a Core `KDNALoadPlan` into app-facing labels,
severity, SF Symbol names, and primary action titles. It MUST NOT define access
modes, entitlement profiles, LoadPlan state machines, issue-code registries,
crypto profiles, or runtime projection policy.

## Current Adapter

The current dependency on `kdna-core-swift` is pinned to revision
`0c94032bea8677167e7d57e8d914d9e29bef9edf` until the next stable Core tag
publishes the current LoadPlan/runtime APIs. Apps should create
`KDNALoadPlanPresentationInput` from the Core LoadPlan fields they receive and
pass it to:

```swift
let presentation = KDNAAuthorizationPresentation.from(loadPlan: input)
```

After the Core release exposes `KDNALoadPlan`, this package may add a convenience
overload that accepts the Core type directly. That overload must be a mapping
helper only; Swift Core remains the source of protocol truth.

## App Responsibilities

KDNA Chat should use this presentation helper to render import, unlock, license,
remote-runtime, expired, revoked, and invalid states. When Core returns a
loadable state, Chat should call Swift Core for a `KDNAJudgmentProjection` and
pass only that projection to ordinary model context.

KDNA Studio may use the same helper to show whether an exported asset validates
for runtime loading, but Studio export correctness must be validated by Swift
Core and the CLI.
