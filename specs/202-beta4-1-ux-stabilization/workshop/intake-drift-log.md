# Intake drift record

## DRIFT-202-INTAKE-001 — typed product scope has no matching workshop receipt

**Observed**: 2026-10-13, installed beta4 identified by stamp 8d3f9906.
**Evidence**: maintainer's typed scope reply is present in the conversation and saved in workshop/product-domain.md; runtime/workshop-authority.jsonl contains no feature-202 receipt and its latest rows are feature 201 in September. Feature 202 has a valid strict pre-agenda controller. Current conformance dirty-file baseline sees its files. No handler/capture root cause is asserted.
**Impact**: product-domain checkpoint cannot be completed honestly; extra recovery exchange is a cost to measure, not a quality signal.
**Disposition**: preserve answers; do not manufacture receipt IDs, manually write moved_on or modify authority stores. Workshop conduct requires re-rendering the question and waiting for a matching typed receipt. No product implementation, spec authoring or lifecycle crossing has occurred. Proposed bounded recovery: re-present the saved product scope for a fresh typed closing reply, then retry the governed checkpoint once; if the receipt is still absent, stop and propose an explicit supported recovery rather than repeating questions indefinitely.

## DRIFT-202-INTAKE-002 — first B4F-096 fixture was confounded

The original controlled replay omitted the working controller, so Stop demanded both a working area and orientation. The retry added the controller with the installed governed initializer, kept package code unchanged, and produced only the orientation demand. Preserve both runs; claim reproduction from the corrected run only.

## DRIFT-202-INTAKE-001 — bounded checkpoint retry failed after explicit move on

The maintainer typed move on to the displayed product-domain record at Light depth. The human-readable and structured records now preserve that actual confirmation; this is not a claimed hook-owned receipt. The checkpoint invocation first hit a PowerShell -File array-argument binding error, corrected to one Agenda string; its actual governed attempt then refused because no matching typed reply was on record. Feature-202 receipt count remains zero. The controller was not edited, no lens was closed and no boundary advanced.

Read-only registration inspection found SessionStart/UserPromptSubmit/Stop wired to the installed beta4 Codex launcher. The store still holds only the earlier feature's workshop replies; a root cause is not inferred from registration presence or store absence. Prepared checkpoint-recovery-proposal.md for a governed Claude resume of the same feature and persisted an authored handover. Claude executable availability is verified. No new host was launched; approval is requested because the workshop conduct requires stopping after the bounded recovery fails and approval before the next recovery action. Preserve all answers and measure the additional corrective exchange as cost.

## DRIFT-202-INTAKE-003 — missing receipt reported as selection-channel provenance

The subsequent Stop prompt asserts that the recorded product answers arrived through a structured picker or dismissed question UI. This conversation used neither: the scope, retry and move on are ordinary typed user messages, and no structured question tool was invoked. The record's human-confirmed provenance describes that actual human input; it does not supply the missing hook-owned receipt. A missing receipt does not establish selection-channel input.

The Stop requires approval to set the canonical product records aside before asking again. Invoking the governed pre-agenda recovery proposal surface with -Request returns workshop-repair-not-required; the controller is already strict pre-agenda and carries no completed lens. No repair proposal was minted, applied or bypassed. Prepared a bounded archival proposal for the non-authority product-domain.md/.yml records, preserving their bytes and actual typed provenance, to be executed only on explicit human approval. No archive move, controller edit, receipt write or host launch has occurred. This is another corrective Stop cycle and belongs in the friction record; it does not add a new implementation item to the agreed scope.


## DRIFT-202-INTAKE-004 — product records set aside; resumed on Claude

**2026-10-13, Claude session.** On the maintainer's explicit approval, the two product-domain records were moved (not deleted) to workshop/preserved-product-answers/. SHA-256 verified identical before and after (md C60FC1BB...09AF, yml 14CE92F7...5F62); no destination existed beforehand. The controller and the authority store were not touched. The maintainer recorded the Codex receipt gap, the records-before-receipt deadlock and the selection-channel misdiagnosis as B4F-108 (Tier 1) in docs/beta4-findings.md. The first-reply miss's root cause stays open inside B4F-108. Next: re-present the saved scope once as prose on Claude, check workshop-authority.jsonl for a feature-202 receipt after the typed reply, and report the result before writing any product record.

## DRIFT-202-INTAKE-005 — Claude typed "move on" also minted no receipt

**2026-10-13, Claude session.** The saved scope was presented once as prose (Light depth). The maintainer typed `move on`. workshop-authority.jsonl still has 20 lines, all feature 201 / September; no feature-202 receipt. No product record was written.
**Runtime facts (read from runtime files, not hook source):**
- The Stop at 08:35:31Z wrote .specrew/handover/workshop-question.json for 202/product-domain, `agenda_status: pending-confirmation`, a `message_hash` — and an **empty `question` field**.
- The conformance journal classified that Stop as `workshop-intermediate` / `durable-workshop-active` for 202/product-domain (host claude).
- On the reply, UserPromptSubmit at 08:40:10Z appended `typed-turn-exhausted` to .specrew/authority/exhausted-turns.jsonl with `host_kind: claude` and **`minted: ""`**: the typed turn was consumed and nothing was minted.
**Consequence:** the miss is not Codex-only. On this state it reproduces on Claude, so B4F-108's cause may sit in the shared capture path. The empty `question` field is an observation, not an established cause. The cause has not been diagnosed.

## DRIFT-202-INTAKE-006 — latched unhealthy marker moved to evidence

**2026-10-13, Claude session.** The maintainer identified the cause of the missing receipts: `.specrew/runtime/hook-output-authority.jsonl.unhealthy` (created 2026-09-09T07:28:50Z by a sharing violation on a hook-output journal append; content: `The process cannot access the file ... because it is being used by another process.`). While it exists, every reply is treated as hook output and no receipt is minted on any host. This supersedes the empty-`question` observation in DRIFT-202-INTAKE-005 as an explanation.
On the maintainer's explicit approval the marker was moved (not deleted) to workshop/evidence/hook-output-authority.jsonl.unhealthy. SHA-256 d4278938b2174f95e4c45f133f930ef67eaae56126c0da9e7063d4abbe432fbc before and after; the runtime path no longer exists. Nothing else was changed: no hook, store, controller or receipt edit. B4F-108 was rewritten around the cause as three defects (permanent latch, undisclosed latch silently consuming turns, selection-channel misattribution), keeping the cross-host acceptance test and noting that Codex has not yet been tested on a healthy worktree. Next: present the product-domain scope once more and check for a feature-202 receipt after the typed reply.

## DRIFT-202-INTAKE-007 — receipt minted after marker removal; product-domain closed

**2026-10-13, Claude session.** With the marker moved, the maintainer's typed `move on` minted receipt 34cc2b6996b11d959255ad05b7fe44bfb1e0dcd783e0233bc9a77a03aff8bb37 (feature 202, product-domain, host claude, 08:51:13Z), the first receipt since 2026-09-09. Product records were rewritten (including B4F-108) only after the receipt was confirmed, and confirm-workshop-lens closed product-domain with that receipt. Correction to entry 005: the same reply also logged `typed-turn-exhausted` with `minted: ""`, so that field does not indicate a missing receipt.

## DRIFT-202-INTAKE-008 — lens-close refusal named the wrong cause on a stale working directory

**2026-10-13, Claude session.** The first confirm-workshop-lens.ps1 run for code-implementation used `-ProjectRoot .` after an earlier shell command had left the process working directory at the feature folder (PowerShell Set-Location had reset the provider location but not the process directory). The writer refused with "This feature has no recorded workshop plan yet ... confirm its agenda first", although `lens-applicability.json` existed with `agenda_status: confirmed`. One rerun with the absolute project root closed the lens normally (receipt a455ece5..., all seven selected lenses moved_on). No record was hand-edited. Observation for B4F diagnosability: the refusal asserted a missing plan instead of saying the plan file was not found at the resolved path, which would have pointed straight at the path. Candidate beta5 item; not added to 202.

## DRIFT-202-INTAKE-009 — specify preflight: unscoped run checks no feature; scoped run needs the spec first

**2026-10-13, Claude session.** After all seven lenses closed, `sync-boundary-state.ps1 -BoundaryType specify -PreflightOnly` returned `success: true` with `feature_ref: ""`. It resolved no feature, which is consistent with the stale start-context pointer (199) and the empty `.specify/feature.json` (B4F-105, data-storage lens). A pass that checked no feature is not evidence for 202. The same preflight scoped with `-FeatureRef 202-beta4-1-ux-stabilization` refused only because spec.md is still the scaffold placeholder, and it named the specify step as the next action. The skill's "preflight before speckit.specify" ordering cannot be satisfied for a scoped run, so the scoped preflight runs again after the spec is authored, before the boundary stop. Feeds the data-storage pointer decision; no new finding.

## DRIFT-202-INTAKE-010 — specify sync recorded arrival but opened no pending crossing

**2026-10-13, Claude session.** The branch was pushed with the maintainer's approval, which cleared the `verdict-commit-durable` precondition. The boundary commit was 3821a05c. `sync-boundary-state.ps1 -BoundaryType specify -FeatureRef 202-beta4-1-ux-stabilization` then returned `success: true`, `boundary_record_status: established`, `is_first_boundary: false` and `pending_verdict_has_pending: false`, and wrote no `.specrew/runtime/pending-verdict-stop.md`. start-context.json `session_state` now names 202/specify at 3821a05c. `boundary_enforcement` still carries feature 199's ledger: `last_authorized_boundary: feature-closeout`, `pending_crossing: null`. The documented advancement gate reports `intake -> specify` blocked, with "No persisted authorization matched". So the gate requires a verdict, but no crossing exists for a typed verdict to bind to. The per-worktree ledger was never reset for the new feature; this is the same class as the stale pointer in B4F-105 and the data-storage lens.
The same sync also rewrote `Specrew.psd1` FileList ordering (readiness-verdict.ps1 and turn-end-store.ps1 moved to alphabetical positions; no entry added or removed) and updated the .squad bookkeeping files. The Specrew.psd1 change is left uncommitted pending the maintainer's decision. No ledger or pointer was hand-edited.
