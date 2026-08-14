# Claude deep-review validation and mitigation

**Measured**: 2026-08-14 against the working tree, not only `HEAD`
**Purpose**: implementation ledger for the maintainer-requested stabilization pass
**Authority**: diagnostic evidence only; this is not `review.md` and does not authorize review signoff

## Release inventory validation

| Claim | Validation | Mitigation |
| --- | --- | --- |
| Feature 185 has no closeout and carries unresolved host-enforcement evidence debt | **True with stale wording.** No iteration/feature closeout exists. The old `CONTINUATION.md` still says iteration 2 waits on a Claude `PreToolUse` ruling, but later drift/spec records implemented the Stop-hook alternative. The remaining debt is closeout plus direct-host evidence, not an untouched iteration 2. | Correct the inventory/closeout record before release; do not describe the implemented Stop-hook path as still pending. Carry only the explicit direct-host evidence limits. |
| Feature 197 is complete/tagged; reviewer filesystem confinement remains instructional | **True.** Ten iteration directories and `closeout.md` exist; beta1/beta2 tags exist. The confinement defer remains an announced limitation. | Keep the limitation explicit in beta3 notes; do not claim OS-enforced reviewer filesystem confinement. |
| Feature 198 shipped/tagged without a feature closeout | **True.** Iterations 001-003 and 005-011 exist, iteration 004 is absent, and no `closeout.md` exists; the release-claim artifact is not a lifecycle closeout. | Record the historical closeout gap; do not manufacture retroactive authorization. Keep it out of beta3's certification claim. |
| Feature 199 is implemented but unvalidated and its state fields conflict | **Partly true; the asserted conflict is false.** `review.md` is absent, so the iteration is not review-authorized. `Current Phase: before-implement` names the still-open crossing, while `Iteration Status: ready-for-review` says implementation is complete and ready to enter review. Those are orthogonal facts, not contradictory ones. | Preserve the lifecycle state and do not manufacture `review.md`. The actual independent review must create and commit that artifact before the crossing can advance. |
| Regression coverage is curated and incomplete | **True; historical counts are stale.** The permanent census runner discovers 345 PowerShell test entry files, while the F-198 registry currently names 115. A registry pass therefore cannot be reported as “all tests.” | Keep both lanes: the curated F-198 regression contract and the complete on-disk census. Report exact runner scope, file counts, exclusions, and named failures. |
| This branch has no push CI | **True with the review's stated PR nuance.** Push/PR filters name `main` and `001-specrew-product`; pushes to `199-beta3-stabilization` do not run CI, while a PR targeting `main` can. | Extend CI push coverage to stabilization/release branches or use an explicit workflow dispatch; require the local full sweep before the manual walk. |
| Working-tree managed assets are asymmetric | **False as a current-host defect; the observed paths are real but the interpretation is stale.** `.copilot/skills` is the retired legacy surface. Copilot's current skill root is `.github/skills`, where `specrew-code-rules` exists; migration tests explicitly require retired managed `.copilot/skills/specrew-*` directories to be absent. | Preserve the pre-existing deletions/untracked mirrors rather than staging them into this repair. Prove the source template fans out to all current host roots with `code-rules-skill-multihost.tests.ps1` and the clean-deployment legacy-removal tests. |

## Blocking findings

| ID | Validation | Mitigation and acceptance proof |
| --- | --- | --- |
| B1 - raw signoff override is agent-forgeable | **True.** `sync-boundary-state.ps1` constructs authority from two CLI strings; the gate checks only non-empty values and allows before campaign evidence. | Delete the raw CLI authority path. Introduce a pending override request bound to campaign/tree plus a UserPromptSubmit/PreInvocation-captured human phrase and rationale. The gate accepts only the matching captured fact. Paired proof: raw parameters/direct object cannot allow; captured, identity-bound fact can; stale-tree/campaign fact cannot. |
| B2 - round budget is rendered but not enforced | **True.** `budget_exhausted`/`continuation_available` are not read by the invocation path; a fresh round grant can be minted after 4/4. | Enforce budget in both pause-choice recording and continuation authorization. Count only reviewer-invoked rounds after the latest reset; refuse at the ceiling until an explicit captured reset. Prove 3/4 allows, 4/4 refuses even with `--approve-round`, and reset restores exactly one bounded path. |
| B3 - store corruption becomes permissive null/zero | **True.** Two catches in the orchestrator replace authority-store exceptions with `$null` and `0`. | Convert both to one structural `review-authority-store-invalid` refusal before reservation/invocation. Prove malformed result directory and identity mismatch invoke no reviewer and consume no allowance. |

## Major findings

| ID | Validation | Mitigation and acceptance proof |
| --- | --- | --- |
| M1 - workshop authority blocklist misses campaign Stop prose | **True.** `Specrew review - ...` is not matched by the `Specrew:` prefix. The class is coupled to mutable prose. | Add immediate prefix coverage and a structural emitted-hook-output hash journal. Workshop authority rejects a prompt whose hash matches recent dispatcher output, independent of wording. Prove exact campaign text and novel recorded hook text cannot mint a receipt, while a typed answer can. |
| M2 - agenda receipt is not bound to the persisted agenda | **True.** The receipt's `question_hash` is stored but never compared with selected/skipped parameters. | Make the script render one canonical full agenda (selected plus every skipped lens/reason), recompute its hash on confirmation, and require equality with the receipt. Prove agenda A receipt cannot persist agenda B. |
| M3 - marker `managed_files` bypasses reparse/hydration policy | **True.** Bundle hashing reads marker paths with raw `ReadAllText`, bypassing the classifier/hydration wrapper. | Route both manifest and marker paths through one contained managed-text reader that classifies every ancestor, hydrates admitted cloud placeholders, and hashes only bytes actually read. Prove marker and discovered manifests have identical link/cloud behavior and messages. |
| M4 - reparse premise guard cannot see extension delete caller | **True.** The guard scans `scripts/internal`; the production deletion caller is under `extensions/specrew-speckit/scripts`. Its positive checks also accept comment text. | Expand AST discovery to both production roots, require the deploy caller explicitly, and make positive assertions call-structure based. Mutation proof: remove the containment call while leaving comments and the guard fails. |
| M5/M6 - absent-review state is unused/asymmetric and its options ignore budget | **True.** `result_produced=false` is emitted only on failure, no external production consumer reads it, `gating=false` aliases clean, and rerun is always offered. | Give all decision shapes a closed `evidence_state` and `result_produced`; non-produced is gating and cannot be rendered as clean. Options derive from enforced continuation availability; at budget ceiling offer reset/abandon, never an impossible rerun. Prove timeout below/at ceiling and complete clean/findings paths. |

## Minor findings

| ID | Validation | Mitigation and acceptance proof |
| --- | --- | --- |
| m1 - optional marker fields throw under StrictMode | **True.** `schema_version` and `specrew_version` are read directly while `managed_files` is guarded. | Read required properties through explicit property lookup and return `review-engine-marker-invalid:<field>`. |
| m2 - workshop receipt reader has silent 1 MB / 256-line caps | **True.** Both limits return indistinguishably from no receipt. | Stream the complete append-only file and retain the latest matching valid record; malformed/oversized individual records fail with a diagnostic. Prove a valid receipt older than 256 lines and a store over 1 MB remains reachable. |
| m3 - source event matching is spelling/case fragile | **True.** Six case-sensitive spellings form a silent allowlist. | Normalize separators/case into canonical semantic events; unknown events refuse explicitly. Prove mixed case and supported host spellings map to one value. |
| m4 - Antigravity hook health is not per-event structural | **True.** Exact-event validation runs only for event-map shapes; named-definition falls back to whole-file searches. | Make health validation shape-aware and inspect each event under the exact named definition. Prove an event missing in the definition fails even if the same tokens exist elsewhere. |
| m5 - reparse policy has dead disposition and case-sensitive wording | **True.** `refuse-unknown` remains in docs/ValidateSet; `-ceq 'Junction'` disagrees with case-insensitive classification. | Remove the dead disposition and use case-insensitive kind rendering. Prove lowercase junction is described as a junction. |
| m6 - authority timestamps are compared as strings | **True.** Current facts are uniformly `+00:00`, but other writers use `Z`; lexical order can disagree with time order. | Parse every authority timestamp to `DateTimeOffset` through one fail-closed helper before sorting/comparison. Prove mixed `Z`/offset representations order by instant; invalid timestamps refuse. |
| m7 - starter templates are beside JSON but spec says inside | **True contract drift.** The sidecar preserves a strict secrets-safe JSON schema and is the better design. | Amend US5, FR-012, the entity description, plan summary, and drift log to say JSON plus `verification-plan.templates.md`; keep the JSON schema closed. Prove both files materialize. |
| m8 - dead signoff assertion wrapper drops campaign inputs | **True.** It has no callers and its signature omitted the campaign parameters. | Keep the public assertion wrapper for compatibility, but make it semantically complete: accept and forward all six campaign parameters to the single decision function. The production wiring remains the enforced entry point. |
| m9 - agenda catalog is parsed with a line regex | **True.** Quoting/indentation can make a lens vanish. | Use the repository's dependency-free YAML reader, or a dedicated strict catalog parser backed by its schema. Prove quoted and differently indented IDs remain in the completeness set. |
| m10 - containment comment promises a re-check not performed | **True but currently harmless.** Component-by-component no-link validation plus lexical containment establishes the property, but code and comment disagree. | Perform the cheap final containment check after the walk and test the returned path remains under root. |

## Cross-cutting sweep

The review's common failure class is accepted: **a computed control with no production consumer is a typed comment, not an enforcement mechanism**. Before release, enumerate returned decision fields in the review authority/core/gate/orchestrator and prove every authority-bearing field has a production consumer or is explicitly diagnostic-only. Add the resulting guard to the permanent class-guard lane.

The deterministic consumer guard now covers the authority-bearing decisions added or changed in this pass. The workshop stop-message failure also has a structural fix: hook output is journaled by hash and cannot become human workshop authority when Copilot replays it as input. The product-domain and technical-lens questions remain ordinary workshop pauses; the generic material-work packet is suppressed for proved workshop questions unless the turn also changes files outside the workshop record set. Agenda confirmation now covers the complete selected-and-skipped lens set and is bound to the exact rendered agenda.

## Verification evidence before packaging

- Complete PowerShell census: **345/345 files have a green result**. The latest broad run executed 344 files (118 Pester-style plus 226 direct scripts) with zero failures; the one explicitly excluded long-running changed-only integration file passed separately at 14/14 assertions.
- F-198 curated registry: **115/115 registered suites green**. This is reported only as the registry contract, not as the complete test corpus.
- Changed-only governance integration: **14/14 green**.
- Workshop typed-turn and replay defenses: campaign Stop prose, recorded hook-output replay, case-normalized events, stores beyond 256 lines and 1 MiB, and genuine typed answers all covered and green.
- Workshop question precedence: proved workshop questions recover from the bounded Copilot flush race and do not render duplicate five-part packets; low-header recovery records its bounded reread attempt/result.
- Signoff abuse/legitimate paths: raw CLI override removed; exact human phrase, campaign/tree binding, tamper rejection, stale binding rejection, budget 3/4 allow, 4/4 refusal, reset, and corrupt-store refusal are green.
- Reparse, hook-health, verification-plan, multi-host instruction, legacy migration, recovery, and containment proof suites are green.

These measurements establish implementation correctness before packaging. The exact committed tree will be run once more through the complete census and release-facing validation before it is installed.

## Manual-test gate

No new manual-test environment is created until:

1. every row above is fixed or explicitly corrected as a false/stale claim;
2. focused abuse/legitimate tests pass;
3. every PowerShell test file is executed, with named failures rather than only a count;
4. the F-198 registry, governance validation, markdown lint, packaging, deployed-mirror parity, and five harness dry runs pass without provider invocation;
5. the exact resulting commit is packaged, installed, and identified by both build id and a new-code marker.
