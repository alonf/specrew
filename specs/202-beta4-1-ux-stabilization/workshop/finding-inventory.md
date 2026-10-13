# Beta4.1 finding inventory

**Feature**: 202-beta4-1-ux-stabilization
**Prepared**: 2026-10-13
**Status**: original inventory retained; the maintainer's two-tier scope decisions and conditional checks are recorded in product-domain.md and conditional-findings.md. The governed product-domain checkpoint still awaits its matching typed-turn receipt; proposed Light depth is not recorded as confirmed.
**Branch base**: 24e5701ac4f6e34a57b2e487b7d813171984c190; governed creator allocated feature 202 on that exact HEAD. Main merge is a separate decision.

## Restoration and validation

The maintainer identified iteration 199/003 state.md and tasks-progress.yml changes as sync regression and authorized restoration. Both were restored from HEAD before feature creation. The full validate-governance invocation completed with no closed-iteration-edited finding. Exit code remained 1 on historical review-result evidence failures, one missing approved-defer record and a complete iteration whose review says needs-rework, plus dashboard/handoff warnings. This is not a claim of a globally green validator. The restoration produced no commit or edits to preserved iteration history.

## Product-domain opening proposal

Known from the maintainer: this release prioritizes diagnosability and stops unrelated to the work. Users are Specrew maintainers and developers working through governed sessions. Existing workaround: manual status reconciliation, corrective replies, repeated packet reading and targeted historical-record restoration. Proposed Light depth: established product/users, bounded defect sweep; scope is the decision needed now. Success measures proposed for discussion: extra stops/replies per scenario and elapsed overhead against the same beta4 scenario, with reasons and human decisions distinguished. Each extra stop is a cost, not evidence of rigor. No metric threshold or technical design has been decided. Known constraints: beta5 stays out; beta4.1 starts from the current beta4 branch HEAD; stop at specify for the full packet and human verdict; no planning or implementation before that point.

## Beta4.1 candidates

Source: docs/beta4-findings.md. Surfaces below are suspicions from the records, not new root-cause verification. B4F-054/056/058/061 share one narrowly deferred ordering slice via B4F-074, not four invitations to redesign review.

| ID | Symptom | Suspected surface | Scope/evidence note |
| --- | --- | --- | --- |
| B4F-054 | Review feeds itself after verification edits; beta4.1 is only the residual records/order repair. | Reviewed-state classification and review completion ordering. | Broader product-versus-verification redesign stays beta5. |
| B4F-056 | Sign-off records can invalidate coverage; scaffold-output exclusion already shipped, so inventory only the remaining ordering gap. | Sign-off record publication and coverage classification. | Partial-sign-off packet redesign stays beta5. |
| B4F-058 | The human accepts again after sign-off's own records move the tree. | Sign-off evidence write order and coverage digest. | Broader acceptance/digest redesign stays beta5. |
| B4F-061 | One boundary costs repeated campaign authorizations; only the duplicate caused by sign-off records is beta4.1. | Review completion ordering. | Campaign authorization/phrase consolidation stays beta5. |
| B4F-089 | Resume announces work already completed on disk. | Resume orientation, handover freshness and pending-crossing context. | Deferred beta4.1. |
| B4F-093 | The iteration's own seal appears as unreviewed source. | Lifecycle execution-record classification. | Deferred beta4.1. |
| B4F-096 | Orientation arrives after the first lens. | First-reply orientation ordering and fallback rendering. | Heading says beta4.1; adjacent PRED-054 resolution describes version labels. Reconcile the scope ambiguity before claiming this fixed or required. |
| B4F-100 | Editing harmless wording after saving a draft causes a Stop rejection. | Draft-to-visible-message conformance. | Review finding; not reproduced by the accepted beta4 walk. |
| B4F-101 | Turn drafts can become tracked or dirty artifacts. | Draft path contract and ignored runtime storage. | Deferred beta4.1. |
| B4F-102 | Design-analysis refusal names a missing artifact without its producing step. | Plan-entry refusal and forward recovery instruction. | Deferred beta4.1. |
| B4F-103 | Gallery comparison fails on NuGet exclusions and publish-time manifest changes. | Package comparison scope and metadata transformation. | Record-only beta4 disposition; comparison correction beta4.1; no republish. |
| B4F-104 | Every unrelated turn repeats the unchanged crossing packet and Stop error. | Per-session crossing presentation obligation. | Deferred beta4.1; preserve all three reported non-verdict triggers. |
| B4F-105 | Default dashboard names feature 001 while saved state names 199. | Default feature-context selection. | New candidate; neither historical pointer is assumed to be the correct resume target. |
| B4F-106 | Missing dials line costs an extra conformance reply cycle. | Adaptation conformance and proportionate recovery. | New candidate; observed one extra cycle; elapsed cost not measured. |
| B4F-107 | Codex prints numeric keys; Claude renders expertise prose. | Host adaptation presentation. | New candidate; band semantics (B4F-091) remain beta5. |

## Beta5 exclusions

These references remain outside this intake. Some findings have shipped partial fixes; only the named residual/class is excluded, and this inventory never reopens a shipped fix. IDs are preserved, including the distinct B5-001 and B5F-001. docs/beta5-findings.md supplies B5F-001..003.

| ID | Symptom or residual | Suspected surface |
| --- | --- | --- |
| B4F-006 | Work-kind is silently defaulted; per-feature posture cannot be expressed. | Work-kind selection/scope. |
| B4F-008 | Orientation discharge was per turn. | Orientation conformance history. |
| B4F-011 | Non-assent turns become lens confirmations. | Workshop receipt consumption. |
| B4F-012 | Ambiguous workshop refusal stays in the journal. | Workshop refusal disclosure. |
| B4F-014 | Receipt proves a turn rather than assent. | Workshop evidence semantics. |
| B4F-015 | Evidence is promoted to confirmation authority. | Workshop receipt reader. |
| B4F-016 | Workshop and approval stores interpret a turn differently. | Response classification. |
| B4F-018 | A claim exceeds the measured verification scope. | Methodology/evidence claims; B4F-103 alone is the beta4.1 package slice. |
| B4F-020 | Project-level work-kind cannot express a feature's conduct. | Per-feature work-kind. |
| B4F-023 | Closeout policy and later amendments disagree. | Historical seal/amendment governance; seal-order repair subsequently shipped. |
| B4F-025 | Untouched feature stub asserts an open workshop. | Workshop candidate qualification; linked B4F-028. |
| B4F-028 | Unasked stub and posed first question are indistinguishable. | Durable posed-question declaration. |
| B4F-030 | Bug-bash review requires an iteration it never creates. | Campaign identity/work-kind. |
| B4F-031 | Pinned model and installed CLI cannot launch review. | Reviewer capability/deployment. |
| B4F-032 | Project install writes user-level files without disclosure. | Global deployment surface. |
| B4F-033 | Timing assertions depend on runner load. | Census timing budgets. |
| B4F-034 | Timing diagnostics conflate unobserved and surviving processes. | Census assertion diagnostics. |
| B4F-036 | Post-agenda controller recovery is unavailable. | Governed workshop repair. |
| B4F-038 | Preferred intake depth is stored but unread. | Profile consumption; shipping the profile skill already fixed in beta4. |
| B4F-039 | Mid-clarify packets repeat; stale session directories count as live. | Stop classification/session liveness. |
| B4F-041 | Product-domain can be reopened after agenda. | Workshop transition/writer consistency. |
| B4F-042 | Repair and ordinary closing share an unsafe path. | Controller authority/writer-reader consistency. |
| B4F-046 | Handoff-evidence gate and sync order disagree. | Handoff evidence ordering. |
| B4F-047 | Review gate is vacuous early and unreachable for iteration-less features. | Review gate placement/work-kind. |
| B4F-050 | Bug-bash contract is only a checklist. | Work-kind enforcement. |
| B4F-053 | Crashes leave orphan turn tokens. | Turn-token lifecycle/dispatcher; issuance defect already repaired. |
| B4F-054 | Verification changes continually re-arm review. | Broader review digest redesign; ordering slice separately inventoried. |
| B4F-055 | Severity is demoted for missing literal formatting. | Review finding grading. |
| B4F-056 | Human must compose partial-sign-off coverage. | Partial-sign-off packet design; ordering slice separately inventoried. |
| B4F-057 | Review digest consumes the Stop timeout. | Dispatcher budget/performance. |
| B4F-058 | Partial acceptance invalidates itself. | Broader acceptance semantics; ordering slice separately inventoried. |
| B4F-059 | Task readers use different status vocabularies. | Task-state contracts. |
| B4F-060 | Mechanical check fails when no matching code exists. | Scan applicability/no-work result. |
| B4F-061 | Campaign decisions cost multiple crossing-like approvals. | Campaign authorization redesign; ordering slice separately inventoried. |
| B4F-062 | Dashboard counts planned points as delivered. | Velocity accounting; distinct from B4F-105 selection. |
| B4F-064 | Correct refusal provides no forward move. | General refusal standard; B4F-102 is the bounded beta4.1 slice. |
| B4F-065 | Prompt-entry encoding changes typed content. | Argv transcoding; pasted-transcript capture defect already fixed. |
| B4F-069 | No-launch start hangs in a consumer environment. | Startup/environment. |
| B4F-071 | Readiness BLOCKED can be summarized as PASS. | Source-write control; directive line already fixed. |
| B4F-072 | Source writes lack enforced implementation authorization. | Tool-boundary/Stop enforcement. |
| B4F-077 | Other hosts lack a keep-and-own charter remedy. | Remaining host charter notices; bounded beta4 fix already shipped. |
| B4F-079 | Prose lint prevents product test lanes from running. | CI dependency/record writer formatting. |
| B4F-084 | Reviewer host pick adds a separate lens reply. | Reviewer setup interaction. |
| B4F-085 | Clarify defaults propose skipping a mandatory stop. | Clarify guidance/authority. |
| B4F-090 | Resumed project gets first-run prose. | Orientation context. |
| B4F-091 | Value 7 receives inconsistent expertise bands. | Profile band semantics; distinct from B4F-107 formatting. |
| B4F-092 | Implementation approval phrase names a preposition. | Verdict alias/lifecycle vocabulary. |
| B5-001 | Stop-intent classifier has no taught producer. | Agent instruction/intent contract (ID as written in beta4 findings). |
| B5F-001 | Task-record ownership is unclear. | Implementer versus task-progress writer. |
| B5F-002 | A mandatory stop is bundled into a discussion default. | Boundary packet/skip authority. |
| B5F-003 | Plan artifacts are written before mandatory design analysis. | Lifecycle artifact ordering. |

## Superseded beta4.1 references

- B4F-063: originally deferred, then fixed in beta4 (seal at authorization and sealed-writer skip). Do not create a second repair from its earlier disposition.
- B4F-095: originally proposed for beta4.1, then ruled into beta4 and built as PRED-BETA4-054 (version-label resolver). Do not reopen the version-label fix.
- B4F-056 scaffold-output classification: fixed in beta4; only a proven remaining ordering gap belongs in this candidate list.
- B4F-096: the record has a beta4.1 heading but an adjacent version-label resolution. Treat the orientation-order claim as a scope ambiguity to settle, not silently as fixed or unshipped.

## Recommended scope discussion

Lead with B4F-104, B4F-106, B4F-100, B4F-102, B4F-105 and B4F-089: repeated irrelevant stops, disproportionate correction cost, and context/recovery diagnosability. B4F-101 supports predictable recovery. Keep the review-ordering slice and B4F-093 bounded. B4F-096 needs record reconciliation; B4F-107 is a presentation candidate without changing beta5 band semantics. B4F-103 is a lower-priority comparison correction, never a beta4 republish. The human will decide inclusion/exclusion in the product-domain workshop.

