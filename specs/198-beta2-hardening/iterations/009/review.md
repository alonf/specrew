# Review: Iteration 009

**Feature**: 198-beta2-hardening
**Iteration**: 009
**Phase**: review — concluded at iteration-closeout 2026-07-30
**Disposition of record**:
file:///C:/Dev/specrew-beta2-hardening/specs/198-beta2-hardening/beta2-release-claim.md
**Overall Verdict**: needs-rework

## Verdict

**Read this before reading the verdict above.** In this methodology `accepted` at
iteration-closeout means *the iteration's recorded disposition is accepted* — including its
deferrals and their assigned owners — and a complete iteration must record it (the same
shape Iteration 003 closed under, with six deferred tasks and `accepted`). **It does NOT
mean the reviewed work was certified, and it is not a release-readiness claim.**

What this iteration actually produced:

**Verification: PASS. Certification: NOT ACHIEVED.** These are separate claims and this
iteration ends with one of each, which is why T079 is terminal as `deferred` rather than
`done`, and why the disposition of record is the narrowed beta2 claim rather than a clean
certification. Two majors of the path-identity/containment class remain open and are carried
to Iteration 010 under an approved deferral; they are listed in the Gap Ledger below rather
than absorbed silently.

Anyone reading this file for release confidence should read
file:///C:/Dev/specrew-beta2-hardening/specs/198-beta2-hardening/beta2-release-claim.md
instead — that is where the seven named limitations live.

## Task Verdicts

Verdict vocabulary is `pass | needs-work | blocked`.

| Task | Requirements | Verdict | Notes |
| --- | --- | --- | --- |
| T072 | P209-W1 | pass | DELIVERED IN 009. Deterministic per-suite timings with optional machine-readable output. |
| T073 | P209-W2 | pass | DELIVERED IN 009. Serial parity proven and three consecutive complete parallel registry passes without evidence loss. |
| T074 | F13, F16 | pass | DELIVERED IN 009. Canonical candidate inclusion/exclusion identity; manifest, digest, diff and materialized paths agree exactly. |
| T075 | F12 | pass | DELIVERED IN 009. Codex file-primary delivery invokes the provider exactly once on empty stdout with a valid current result file. |
| T076 | F6 | pass | DELIVERED IN 009. A stale installed engine cannot silently run when a different project engine is authoritative. |
| T077 | F15 | pass | DELIVERED IN 009. Consumer templates ignore/classify `.specrew/review/` runtime evidence. |
| T078 | F13, F16 | pass | DELIVERED IN 009. Frozen Article Amplifier replay proves the recorded exclusion is honoured against immutable evidence. |
| T079 | F6, F12, F13, F15, F16, P209-W1, P209-W2 | needs-work | NOT COMPLETED IN 009 — terminal as **deferred**. Verification ran and is GREEN; certification did NOT pass after eight rounds. Corrections carried to Iteration 010 (DRIFT-198-I009-041 first task, -042 alongside, -043 with the link-state fixtures). Not delivered elsewhere yet — unlike Iteration 003's deferrals, this one cannot be marked `pass` on a successor's evidence, because that evidence does not exist. |

T072–T078 were delivered and are focused-green; their `pass` is not disturbed by T079's
outcome. T079's verification ran green and its certification did not pass — the distinction
this whole document exists to keep straight.

## Gap Ledger

- Every entry below is **deferred** under the canonical defer entry `f198-i009-defer-path-identity-cluster-to-010` in `.squad\decisions.md`, with the approving human recorded — not absorbed into closure. A **deferred** correction is not a hidden one; the release-facing consequence of the two majors is stated as limitations 1-3 of file:///C:/Dev/specrew-beta2-hardening/specs/198-beta2-hardening/beta2-release-claim.md
- DRIFT-198-I009-041 (major) — authority-store containment is lexical, so a reparse point at the store root or any campaign/run ancestor redirects immutable authority-fact writes and directory creation outside the store: **deferred** to Iteration 010 as its FIRST task; resolve and contain every existing component, or reject reparse points, before any enumeration, creation, read or write, plus a linked-ancestor regression.
- DRIFT-198-I009-042 (major) — the case probe's existence test follows link targets and reports false for a dangling link, so a listed dangling entry on a case-folding volume inverts the verdict and caches a wrong comparer: **deferred** to Iteration 010 alongside -041; use a link-aware directory-entry lookup that tests the entry without following its target, and add a dangling-link fixture to the differential harness.
- DRIFT-198-I009-043 (minor) — the case-distinct firewall fixture that -040 required was never added: **deferred** to Iteration 010 with the link-state harness fixtures; add a measured-volume fixture with mandates in both case-distinct files and assert both are reported.
- DRIFT-198-I009-034 (major, mechanism) — the review gate cannot express a human deferral for a freshly discovered finding: **deferred** to Iteration 012 finality scope, unchanged from its 2026-07-29 disposition.
- Grep-based structural enforcement is not AST-based, and its accepted-residual status is withdrawn after the revisit trigger fired twice: **deferred** to a scheduled replan task for parser-based enforcement.
- DRIFT-198-I009-020, -021 and -029 (minor) — retroactive-closeout crossings, successor-iteration evidence, and verification-command PATH diagnosability: **deferred** to the Specrew product backlog, unchanged; each was open, owned and recorded before this closure.
- DRIFT-198-I009-044 (minor, mechanism) — the closure schema cannot express "iteration complete, task terminal-as-deferred, work NOT yet satisfied anywhere": **deferred** to the Specrew product backlog; see the note under Task Verdicts.

## What was verified, and is green

Against the exact target digest, tree quiescent, run as the workflows run it:

| Gate | Result |
| --- | --- |
| `f198-regression-suite.ps1` | all **87** suites green (82 before the path-identity family was registered) |
| Bootstrap suites | all green, run as `specrew-ci.yml` runs them |
| markdownlint | exit 0 on the full CI scope |
| Cross-Platform Validation | green on ubuntu / macos / windows |
| Specrew CI | green — Self-leak firewall, Lint, Deterministic gate, Contract lane |
| Serial/parallel registry parity | green |
| Controller verification commands | both green against the exact digest, every round |

Per-volume measurements, read directly out of the job logs rather than inferred from a
green conclusion:

| Leg | Measured volume | os-family mutant |
| --- | --- | --- |
| ubuntu / ext4 | case-sensitive=`True`, listing `[REPO, Repo]` | UNDETECTABLE-HERE-BY-CONSTRUCTION |
| macos / APFS | case-sensitive=`False` | `disagree=True, harness-failed=5` → **CAUGHT-HERE-REQUIRED** |
| windows / NTFS | case-sensitive=`False` | UNDETECTABLE-HERE-BY-CONSTRUCTION |

## What certification found, across eight rounds

Independent review, codex as reviewer of record with `code_writer_host=claude` declared on
every invocation. All immutable results are preserved under
file:///C:/Dev/specrew-beta2-hardening/specs/198-beta2-hardening/iterations/009/evidence/.

| Round | Target | Outcome |
| --- | --- | --- |
| 1 | `178a3772` | ignored-path set folded case (-010) |
| 2 | `d2b786e6` | digest denial folded case (-012), plus -011, -013, -014 |
| 3 | `5117c807` | case rule from OS family, not the volume (-015, -016, -017) |
| 4 | `aab37c3b` | -022 through -026 — including a defect introduced by round 3's own correction |
| 5 | `2c6d7cb8` | the sweep corrected the deployed MIRROR, not the canonical source (-030) |
| 6 | `0e0048b0` | -031, -032, -033 — the guard on one mutator of five; the probe wrong a third time |
| 7 | `f738f5cf` | -039 (blocking, the certification lane could false-green), -040 |
| 8 | `3d74f123` | -041, -042 (both major) → **termination rule fired** |

The root cause of rounds 1-5 was found by directed sweep, not by review:
DRIFT-198-I009-027, a same-named duplicate shadowing the path-identity primitive, so every
call site "routed through the primitive" was still receiving the OS-family answer. No
review round could have found it from a call site.

## Honest assessment

**The instrument change worked and is retained.** Replacing review rounds with a
differential harness whose oracle is the filesystem — and proving that harness falsifiable
with a mutation gate — is a real improvement over authored expectations. It caught the
historical OS-family defect on the one volume where that defect is detectable.

**It did not make the surface converge.** DRIFT-198-I009-042 sits inside the harness's own
blind spot: the fixtures contain zero symlink, dangling-link, or reparse-point cases, so
the volume was a sound oracle for what it was asked and was never asked about links. The
lesson is not that the oracle was wrong; it is that fixtures must span the state space.

**Four of the defects in the final rounds were introduced by this iteration's own
corrections** (-026 by -018, -032 by -026, -042 by -032, and -039/-040 landing on
instrumentation written the same day). That pattern, not any single defect, is what ended
the campaign.

**Reviewer-reported findings were verified in source before being accepted**, never taken
on the reviewer's word; several corrections went beyond the reported site after
measurement showed the class was wider (-033 found four extra sites in the extensions
trees; -037 exposed a seventh OS-family site once the scan root widened).

## Release-blocking status

Not release-clean. `can_approve_current: false` on the final round. The iteration's answer
on release confidence is the narrowed claim, which names seven limitations, the threat
model including checkout-borne symlinks, and detection commands — not a clean
certification.

## Carried forward

DRIFT-198-I009-041 (Iteration 010, first task), -042 (Iteration 010, alongside), -043
(Iteration 010, with the link-state harness fixtures), -034 (Iteration 012 finality
scope), AST-based structural enforcement (scheduled replan task). Full ledger:
file:///C:/Dev/specrew-beta2-hardening/specs/198-beta2-hardening/iterations/009/drift-log.md
