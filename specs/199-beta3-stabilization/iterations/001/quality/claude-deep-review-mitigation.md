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
| Regression coverage is curated and incomplete | **True; historical counts are stale.** The permanent census runner discovers 348 PowerShell test entry files, while the F-198 registry currently names 118. A registry pass therefore cannot be reported as “all tests.” | Keep both lanes: the curated F-198 regression contract and the complete on-disk census. Report exact runner scope, file counts, exclusions, and named failures. |
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

## Follow-up leverage findings

| ID | Validation | Mitigation and acceptance proof |
| --- | --- | --- |
| F1 - hook-output journal has a reader but no writer | **True.** Before this pass only the workshop reader and its fixture named `hook-output-authority.jsonl`; a day of real hook output produced no journal. | The dispatcher now hashes and journals both the semantic payload and exact host envelope before emission, and writes an unhealthy marker on journal failure so the reader fails closed. The derived authority-control guard treats hook-output identity as its sixth producer/consumer pair. Dispatcher integration proves all five host envelopes are recorded and rejected on replay. |
| F2 - path identity remains bypassable | **Partly true.** Continuous co-review already hard-loaded the comparer, but repository-token case folding and several path `HashSet` instances still bypassed it. This was not yet the broader project-wide beta4 consolidation. | Remove the remaining engine bypasses and add structural guards rejecting OS-family case normalization and hard-coded case-insensitive path sets unless explicitly annotated as non-path identity. Beta3 closes the continuous-co-review reachability class; unrelated platform path logic remains beta4 scope. |
| F3 - derived guards are exceptional | **True.** The authority guard was a remembered list and the code-rule catalog did not require consuming-set discovery. | Add the baseline `derived-guard-scope` rule and derive authority control/consumer IDs from source markers, with a nonzero floor and exact set equality. The hook journal is the sixth member, proving a newly marked producer without a consumer fails automatically. |
| F4a - default AcceptPort and GateSyncPort never execute | **False/stale.** `campaign-stop-here-real-ports.Tests.ps1` already contains an all-three-defaults end-to-end case that executes VerifyPort, AcceptPort, and GateSyncPort without injected ports. | Preserve that suite and cite its scope; no duplicate test is added. |
| F4b - Tier-2 harness dry run is absent from CI | **True.** The provider-free script existed only under `tests/manual`. | Add it to the deterministic CI gate and a regression that verifies the workflow wiring and executes the dry run without provider invocation. |
| F4c - gate preflight is not built | **True.** No boundary-time script checked push parity, ahead count, dirty writer classes, task/state truth, and owed artifacts together. | Add a zero-spend preflight, invoke it from boundary sync before ratchet/state writes, and fail closed on deterministic errors. Remote checks are explicitly N/A for `local-only`; remote-delivered branches must match origin at HEAD. Tests cover local-only, unpushed remote HEAD, dirty writer classification, task/state mismatch, and missing review evidence. |
| F5 - drift events have no class-closure field | **True.** The v1 template could close an event with only `Resolution: FIXED`. | New logs use schema v2. Every `### DRIFT-...` event must name an executable class closure or `NONE — <why>`; the governance validator enforces it while grandfathering historical v1 logs. |
| F6 - self-leak firewall scope and identifier coverage | **True with a scope correction.** The executable surface was 204/404 FileList entries because it intentionally scans only files init/update copies into consumer projects, but the header falsely claimed the whole FileList. Recent-only `F-19x` and ledger-prefix patterns missed older feature and DRIFT provenance. | State the narrower FileList-derived consumer-project contract explicitly. Replace remembered ID alternations with one derived `F-NNN` / `DRIFT-NNN-INNN-NNN` / uppercase `X-NNN-suffix` rule, remove Specrew citations from governed prose, and allow repeated implementation provenance only through an exact file-level token list with a reason. The real lane is green at 203 scanned files, 12 rules, 157 exact/reasoned sanctions, and zero unannotated hits. Bare `T###` is deliberately not automated because it is also the consumer task namespace. |

## Verification evidence before packaging

- Historical complete evidence at `0ad486b0` and `862da048` is superseded by later beta3
  stabilization changes and is not release evidence for the current candidate.
- The exact detached `745cf37d` census reported **350/350**, but that result is rejected as
  release evidence: the serialized F-198 registry returned **119/121** and proved the census
  had observed transiently materialized host-skill bytes while distribution readers ran in
  parallel.
- The two failures were `code-rules-skill-multihost.tests.ps1` and
  `product-domain-multihost.tests.ps1`; both rejected stale tracked workshop-skill copies.
- The canonical refusal instruction, project mirror, four host copies, and census serial lane
  are now under repair. A new exact commit must pass both complete instruments before packaging.
- The first exact `adce6ff5` rerun completed **349/350** with only the changed-only
  governance matrix timing out at its historical 1,200-second ceiling. That matrix passed
  all 14 cases alone in 1,333.9 seconds; its explicit serial bound is now 1,800 seconds and
  the complete exact-commit census remains required.

## Manual-test gate — not yet satisfied

No new manual-test environment is created until:

1. every row above is fixed or explicitly corrected as a false/stale claim;
2. focused abuse/legitimate tests pass;
3. every PowerShell test file is executed, with named failures rather than only a count;
4. the F-198 registry and complete disk census run **sequentially** on the same exact commit, then governance validation, markdown lint, packaging, deployed-mirror parity, and five harness dry runs pass without provider invocation;
5. the exact resulting commit is packaged, installed, and identified by both build id and a new-code marker.

The preserved `ada7c793` evidence projects are untouched. No fresh Copilot or Claude manual
fixture will be created until all five conditions pass for the same exact installed commit.
