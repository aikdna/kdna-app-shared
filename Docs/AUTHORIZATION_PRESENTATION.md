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

The package manifest declares a `0.4.0` lower bound and does not pin an exact
Swift Core revision. This published package predates the current Core contract,
so compatibility must be established at an exact resolved coordinate before a
release claim. Apps should create
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

Apps must distinguish file storage, attachment, authorization, applicability,
and load. They must expose active identity, exact version or digest, scope,
reason, and disable/switch/rollback controls; presentation helpers do not create
those permissions.
