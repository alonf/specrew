# Tasks: PR Review Integration (Minimal Viable Slice)

**Spec**: [spec.md](spec.md)
**Plan**: [plan.md](plan.md)
**Proposal**: [Proposal 089](../../proposals/089-pr-review-integration-address-pr-review-gate.md)

## T001 — Add 2 helpers to shared-governance.ps1

**Files**: `extensions/specrew-speckit/scripts/shared-governance.ps1` (+ mirror)
**Verifies**: FR-001, FR-002
**Done when**: `Get-SpecrewPrReviewResolutionPath` + `Test-HostProvidesAutomatedPrReview` present; mirror parity verified.

## T002 — Validator soft-warning surface

**Files**: `extensions/specrew-speckit/scripts/validate-governance.ps1` (+ mirror)
**Verifies**: FR-003, FR-004
**Done when**: Validator emits `[pr-review-soft-warning] ...` after target enumeration when artifact missing AND host has auto-review AND iteration past pr-open boundary; warning does NOT contribute to exit code.

## T003 — Integration tests

**Files**: `tests/integration/pr-review-integration.tests.ps1` (new)
**Verifies**: FR-006
**Done when**: helpers present; mirror parity; path helper returns canonical location; host detection both positive and negative cases; soft warning non-blocking.

## T004 — CHANGELOG + INDEX + proposal status

**Files**: `CHANGELOG.md`, `proposals/INDEX.md`, `proposals/089-...md`
**Verifies**: FR-007
**Done when**: CHANGELOG entry under `Changed` references Proposal 089 minimal slice. INDEX move 089 → Shipped (partial). Proposal frontmatter notes pillar-1-shipped-as.

## T005 — PR open + Copilot review + merge

**Done when**: PR opened, Copilot findings addressed, CI green, merged via merge commit.
