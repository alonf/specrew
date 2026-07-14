# Iteration State: 005

**Schema**: v1
**Last Completed Task**: the Prop-145 hook-health REDESIGN (Option A, amended) — INDEPENDENT hook-liveness + a NON-PROMOTING `ambient-path-binding` version diagnostic; byte-capped shell-safe probe; System32 cmd.exe interpreter; exact-digest T018 runs injected as reviewer-visible evidence. **Iteration 005 is NOT yet complete** — a Proposal-145 review returned three authoritative findings (bounded output, ambient executable-identity, unsupported evidence). After characterizing that NO host exposes a trustworthy non-ambient executable identity, the maintainer chose Option A: the version is a non-authoritative diagnostic, health rests on observed hook-liveness, readiness on fresh liveness + config/trust — receipts are MONITORING evidence, never authentication. Implemented + green on Windows AND Linux; pending the T018 recording + one authorized confirming review round. See the Co-review section at the bottom.
**Tasks Remaining**: run the maintainer's STANDING 5-round authorization (2026-07-14: "authorized up to 5
additional review rounds") to a CLEAN round — each round: resolved-against-disk citing the latest fixes
commit → one `--live` review → verify findings against disk → fix with paired tests → full verification →
commit → re-bind evidence. The loop STOPS on: a clean round (closes Iteration 005, releases T019 pieces 5-7),
a HUMAN-DECISION finding (escalate immediately), or round 5 of 5 exhausted. History: eighth round (the single
authorization) → 5 findings fixed (6de77f5e); ninth round (1 of 5) → 3 schema-conformance findings fixed —
see the round sections below. NO rounds beyond the authorized five. FR-054/plugin packaging (now T040) is NOT a Beta2 deliverable — deferred to issue #3084 / Beta3.
**In Progress**: none
**Baseline Ref**: cf53400a (the T038 commit; T039 is integration work layered on the already-committed T035-T038 modules)
**Updated**: 2026-07-14T17:30:00Z

<!--
  Current Phase / Iteration Status are set canonically by the sync
  machinery (Proposal 090) once execution begins — omitted at planning
  scaffold time to match the sanctioned shape (iteration 002 precedent),
  never hand-authored with a non-canonical value.
-->

## Execution Summary

- **T035 done (FR-050): truthful host+surface support-tier model + renderer.**
  Shipped `scripts/internal/continuous-co-review/host-support-tier.ps1` — the ONE
  place a host+surface support CLAIM is recorded (data + a pure lookup + a
  doctor/status renderer `Format-SpecrewHostSupportTierReport`). The closed set is
  exactly four tiers (`verified` / `configuration-compatible` / `unsupported` /
  `unverified`), enforced structurally so a fabricated tier is a build-time error.
  CLI is the authoritative surface; the false "Copilot VS Code / cloud gets CLI
  Stop-hook enforcement" claim is removed — Copilot VS Code and cloud are
  `unsupported`, Cursor desktop is `unverified`, and an unknown host/surface fails
  honest to `unverified` (never a fabricated `verified`). References issue #3084 for
  the Beta3 follow-up. Commit 56f783c1. Test:
  `tests/continuous-co-review/unit/host-support-tier.Tests.ps1`.

- **T036 done (FR-051): Codex Stop-contract conformance + untrusted-headless preflight + fail-open guard.**
  An ISOLATED executable fixture against the installed `codex-cli 0.144.1` (scratch
  dir, `CODEX_HOME` redirected, real `~/.codex` verified byte-unchanged) proved the
  OBSERVED contract: `{"decision":"block","reason":…}` on stdout at exit 0 is the
  shape that force-continues; the Codex-manual `{"continue":…,"stopReason":…}` shape
  does NOT gate; exit-2 does NOT gate; a malformed emit SILENTLY fails open; and an
  UNTRUSTED headless hook is SILENTLY skipped. Evidence:
  `iterations/005/evidence/codex-stop-contract-characterization.md` (commit
  0f6eff24). Specrew's existing `StopBlockShape = 'decision-block'` is confirmed
  correct, so the adapter response shape needed NO change; the load-bearing follow-ups
  are the trust gate and the silent fail-open. Those are addressed by two consumers in
  `hook-health-receipt.ps1`: `Test-SpecrewCodexHeadlessGovernanceReady` (the
  untrusted-headless PREFLIGHT — ready ONLY when a current healthy codex/cli receipt
  exists, else NOT-ready with an actionable instruction; NEVER silently governs) and
  `Test-SpecrewHookGateEmissionWellFormed` (the Stop-gate emission validator so a
  regression to a malformed/continue-shape/garbage emit is caught, never a silent
  bypass). Tests: `codex-headless-preflight.Tests.ps1`,
  `codex-stop-gate-fail-open.Tests.ps1`.

- **T037 done (FR-052): Copilot CLI contract verification.**
  An isolated executable probe of `GitHub Copilot CLI 1.0.70` (fresh scratch dir,
  `COPILOT_HOME` redirected, real `~/.copilot` verified byte-for-byte unchanged, 2003
  files) proved: USER-level `sessionStart` / `userPromptSubmitted` / `agentStop` hooks
  fire in BOTH `copilot -p` and interactive mode and are NOT trust-gated (so Specrew's
  user-level governance hook is not subject to the repo-trust gate); REPO-level hooks in
  `-p` require the `trustedFolders` opt-in (an untrusted `-p` folder silently skips repo
  hooks); `agentStop {"decision":"block","reason":…}` blocks + force-continues with the
  reason as the next prompt; allow terminates; NO built-in loop guard; and malformed /
  non-zero-exit agentStop FAILS OPEN. The INTENTIONAL reviewer suppression
  (`SPECREW_REFOCUS_DISABLE=1` — the hook FIRES then no-ops) is cleanly distinguished
  from an ACCIDENTAL never-fired bypass by a single observable: did the hook fire?
  Evidence: `iterations/005/evidence/copilot-cli-contract-characterization.md` (commit
  589c6d26). Test: `tests/continuous-co-review/unit/copilot-cli-contract.Tests.ps1`.

  **Maintainer ruling on the T036/T037 evidence (2026-07-14):** flip both `codex`/`cli`
  and `copilot`/`cli` from `unverified` → `verified`, each carrying an HONEST evidence
  PROVENANCE (what was RUNNER-observed vs HUMAN-observed) plus any NARROWER limitation,
  recorded on the row so the claim never overstates — a bare `verified` with no recorded
  evidence is exactly the false-green this feature exists to prevent. For codex/cli:
  Stop response-shape gating is runner-observed (the T036 probe), and the interactive
  native trust request + subsequent hook execution in a real Codex session is
  human-observed (the maintainer exercised it directly); the untrusted-headless silent
  skip is recorded SEPARATELY as a narrower limitation, NOT a whole-CLI downgrade. For
  copilot/cli: the T037 probe is runner-observed; the repo-hook `trustedFolders` opt-in
  is the recorded limitation, and the user-level hook Specrew rides is not trust-gated.
  Commit b8fefe8f. **No ~/.codex mutation:** Codex owns its trust decision — Specrew
  NEVER writes `~/.codex`, NEVER seeds a `trusted_hash`, and NEVER passes
  `--dangerously-bypass-hook-trust` as a standing workaround.

- **T038 done (FR-053): sanitized hook-health receipts + classifier + doctor/status renderer.**
  Shipped `scripts/internal/continuous-co-review/hook-health-receipt.ps1`: the receipt
  WRITER (`Write-SpecrewHookHealthReceipt` — sanitized BY CONSTRUCTION to EXACTLY six
  fields: host; surface; event; observed_host_version; timestamp;
  adapter_contract_version — no prompt, argument, environment value, or secret can
  enter), the READER + CLASSIFIER (`Resolve-SpecrewHookHealth`), and the renderer
  (`Format-SpecrewHookHealthReport`). The health rules are a closed set with NO
  fail-open-to-healthy branch: present + fresh + well-formed + host-version-matched +
  adapter-contract-matched → `healthy`; MISSING / host-version DRIFT / adapter-contract
  DRIFT → `unverified`; STALE / MALFORMED / CONFLICTING → `degraded`. Missing health is
  NEVER `healthy`. Commit cf53400a. Test:
  `tests/continuous-co-review/unit/hook-health-receipt.Tests.ps1`.

- **T039 done (this iteration's integration + reconciliation + documentation) — UNCOMMITTED per the "do not commit" directive:**

  1. **Real host-fired receipt (FR-053 integration).** Wired
     `Write-SpecrewHookHealthReceipt` into the hook DISPATCHER
     (`specrew-hook-dispatcher.ps1`) so a GENUINE SessionStart or Stop-class event
     (`SessionStart` / `Stop` / `stop` / `agentStop`) records a sanitized receipt for
     the current host + surface=`cli` + event. The write is placed EARLY (right after
     the project-root self-gate) so a real fire is captured even if later
     catalog/state parsing degrades to a no-op. It is STRICTLY fail-open: a new
     `Write-DispatcherHookHealthReceipt` guards on the lifecycle event, resolves the
     module the same fail-open way sibling helpers are resolved
     (`Resolve-DispatcherHookHealthModulePath` — SPECREW_MODULE_PATH / PSScriptRoot /
     ProjectRoot walk-up, then the installed module base; Test-Path; dot-source;
     Get-Command guard), and wraps everything in try/catch so a module-absent /
     resolve / write failure NEVER blocks or alters normal dispatch (the whole
     dispatcher still exits 0). The observed host version has no cheap+bounded source
     (the host event payload carries none, and a per-fire `--version` subprocess would
     tax the tight Stop budget), so it records `'unknown'` unless a zero-cost
     `SPECREW_OBSERVED_HOST_VERSION` override is set — honest, never fabricated. The
     change is applied to all three tracked dispatcher copies
     (`scripts/internal/specrew-hook-dispatcher.ps1`,
     `extensions/specrew-speckit/scripts/specrew-hook-dispatcher.ps1`, and the
     `.specify/…` project-side mirror); the extension + `.specify` copies are
     byte-identical, and the module copy differs only by its pre-existing self-leak
     markers + trailing-newline (no new divergence introduced). Proven end-to-end: a
     real dispatcher invocation writes `claude-cli-sessionstart.json` /
     `…-stop.json` / `…-agentstop.json`, skips PostToolUse, and the receipt resolves to
     `healthy` when fresh.

  2. **Doctor/status surfacing (FR-050 + FR-053 + FR-051), without editing the protected surface.**
     The natural home (`specrew hooks status` in `scripts/specrew-hooks.ps1`) is an
     F-184 PROTECTED file, so per the design a NEW non-protected aggregator module was
     created: `scripts/internal/continuous-co-review/host-support-doctor.ps1`
     (`Format-SpecrewHostSupportDoctorReport`) stitches the three renders — the
     host-support tiers + the hook-health evidence + the Codex-headless-governance-ready
     result — into a single doctor/status STRING. It self-loads its two siblings
     fail-open so it is truly DROP-IN: the protected surface can add exactly ONE
     dot-source + ONE call (documented inline at the bottom of the module) with no edit
     to the protected file, and any non-protected status path can call it the same way.
     Wired into `scripts/internal/continuous-co-review/_load.ps1` and the `Specrew.psd1`
     FileList. The aggregator only FORMATS what its resolvers return — it can never
     upgrade a tier or a health status (no health-washing seam).

  3. **Reconciliation suite (FR-050 + FR-053 + FR-051).**
     `tests/continuous-co-review/unit/host-support-reconciliation.Tests.ps1` (18 tests,
     registered in `tests/f198-regression-suite.ps1`) reconciles the tier model, the
     hook-health receipts, and the committed evidence against each other:
     codex/cli + copilot/cli = `verified` AND carry their provenance; cloud (any host)
     = `unsupported`; Copilot VS Code = `unsupported`; an unknown host/surface =
     `unverified`; the health closed set is exactly {healthy, unverified, degraded} and
     missing/stale/malformed is NEVER healthy; the committed evidence files corroborate
     each flip; and — the core cross-model invariant — a `verified` TIER never implies
     `healthy` HEALTH (a surface-contract claim is not a live firing hook), so the two
     axes cannot cross-contaminate.

  4. **Documentation.** User-facing support-tier + host-compatibility section added to
     `docs/troubleshooting.md` (the four tiers; CLI authoritative; Claude/Codex
     config-compatible surfaces; Copilot VS Code + cloud `unsupported`; Cursor
     `unverified`; a symptom-guide entry) plus the Codex one-time interactive-trust
     instruction (start Codex interactively once, approve the native trust prompt, let a
     hook fire to record a receipt; Specrew never writes `~/.codex`). References issue
     #3084 for Beta3. It does NOT reintroduce any false "Copilot VS Code / cloud gets
     CLI Stop-hook enforcement" claim. This `state.md` is the Iteration 005 execution
     record.

## Serialized co-review (2026-07-14) + task-plan reconciliation

The maintainer-directed ONE serialized co-review (signoff, auto-anchored to the feature
merge-base, independent host) ran against the committed Iteration 005 slice and returned
**ACTIONABLE — 5 blocking findings** (the digest-bound full-registry evidence was
`command_succeeded` at reviewed digest `203e4b5a…` beforehand). Per the completion protocol,
actionable findings are FIXED, not waved through:

1. **Task-plan drift (this finding).** T039 was originally the CONDITIONAL Codex
   plugin-packaging regression (FR-054), but the integration/reconciliation/docs work above
   was executed + committed under the "T039" label, and T035-T039 were left unchecked.
   **DECISION (2026-07-14 — authorizes the task-plan change):** Codex plugin installation is
   NOT a Beta2 deliverable — Specrew deploys `~/.codex/hooks.json` (a hooks CONFIG per
   `hosts/codex/host.psd1`), not a plugin — so the FR-054 plugin regression is DEFERRED to
   issue #3084 and renumbered **T040**. **T039 is redefined to the integration +
   reconciliation + docs work actually executed** (matching the commits). T035-T039 are now
   checked in tasks.md.
2. **Receipt-before-validation false-green (dispatcher).** The receipt was written before the
   host event JSON was validated, so a malformed lifecycle event recorded a receipt that read
   `healthy`. Fixed: the write moves AFTER host-envelope validation (dispatch stays fail-open)
   - a production-path test.
3. **Ambient value could enter the receipt (dispatcher).** `observed_host_version` copied
   `SPECREW_OBSERVED_HOST_VERSION` verbatim (a secret could persist). Fixed: validated against
   a strict version-shaped whitelist → else `unknown`; a production-path test proves a
   secret-bearing value is not persisted.
4. **Doctor aggregator not surfaced.** Loadable but no production command called it (only a
   comment). Fixed: wired into an authorized production status/doctor seam + a test exercising
   the real command path.
5. **`unknown` version read healthy (hook-health).** With no expected version the resolver
   returned `healthy`; the dispatcher stamps `unknown`. Fixed: `unknown`/unobserved →
   `unverified`, never `healthy`/`ready`; production-default-path test.

After the fixes commit and the full-registry evidence re-binds to the NEW committed digest,
exactly ONE re-review runs. **Iteration 005 completion (and the release of T019 pieces 5-7)
is PENDING that clean re-review** — it is NOT complete at the earlier `203e4b5a` digest.

### Re-review (2026-07-14) — ONE human-judgment finding on findings 3+5, fixed fully (maintainer option 1)

The ONE re-review (auto-anchored, independent host) ran against the NEW committed digest `9e76af7a…`
after the 5 fixes and returned **ONE blocking finding, flagged HUMAN DECISION REQUIRED** — the loop guard
correctly fired on a second review→fix cycle on the same findings. Verified against the code, the reviewer was
right: findings 3 + 5 were only PARTIALLY fixed —

- **f3 (ambient value):** the strict version-shape whitelist bounded the SHAPE, not the PROVENANCE — a
  version-shaped secret (`token_123`) still passed and persisted; the ROOT cause (reading the version from an
  ambient env var at all) was untouched.
- **f5 (`unknown` reads healthy):** `unknown`→`unverified` closed one value, but `healthy`/`ready` was still
  reachable for ANY non-`unknown` version with NO current-vs-observed comparison, because the production callers
  (doctor + preflight) omitted `ExpectedHostVersion` — a bare receipt still earned healthy.
- The prior production-path tests ENCODED both defects (asserted the ambient value was persisted, and that an
  arbitrary version read healthy without a comparison).

**MAINTAINER DECISION (2026-07-14): fix fully now (option 1).** Implemented per the approved design (spec FR-053a):

- `observed_host_version` is now a BOUNDED, shell-free `--version` probe of the resolved host executable, run
  ONLY at SessionStart; `SPECREW_OBSERVED_HOST_VERSION` is REMOVED as a version source; probe failure / timeout /
  ambiguity / malformed → `unknown`. Stop launches no probe and cannot overwrite/promote the SessionStart fact.
- `healthy`/`ready` now REQUIRE an INDEPENDENTLY probed CURRENT version (the doctor + the Codex preflight probe
  the live host binding and supply it) that MATCHES the SessionStart-observed version; a missing current version
  is never defaulted to acceptance. Adapter contract bumped 1→2 (every pre-fix receipt retires as drift).
- The encoded tests were REWRITTEN and the full production-path matrix added: env ignored / never persisted; a
  version-shaped ambient token cannot influence health; missing expected → never healthy; a matching probe →
  healthy; mismatch / timeout / malformed / unresolved-executable / stale → unverified/degraded; Stop launches no
  probe; a later Stop cannot overwrite the SessionStart fact; the doctor + preflight pass an independently probed
  expected version.
- Files: `scripts/internal/continuous-co-review/hook-health-receipt.ps1` (the probe + the SessionStart-anchored
  expected-version-gated resolver + the probing doctor/preflight consumers), the 3 dispatcher copies
  (SessionStart-only probe, env source removed, byte-identical parity), `spec.md` FR-053a, and the four test
  suites (`hook-health-receipt.Tests.ps1`, `codex-headless-preflight.Tests.ps1`,
  `host-support-reconciliation.Tests.ps1`, `tests/integration/f198-iter005-hook-health-production-path.tests.ps1`).
  NO deferral to #3084 for this defect (per the maintainer ruling — it is a Beta2 false-green correction).

After this correction commits and the full-registry evidence re-binds to the new committed digest, ONE final
clean re-review closes Iteration 005 and releases T019 pieces 5-7.

### Second re-review + shell-safe / cross-platform reconciliation (2026-07-14, maintainer option 1 + Linux)

The committed option-1 fix re-review first PAUSED on the 2-round budget ceiling (`review-spending-limit-reached`,
escalated to human — 21 blocking items cleared, the latest change not yet reviewed). The maintainer authorized
`--remediate more-time`; the budgeted round then reviewed the latest change and returned ONE human-judgment finding:
FR-053a mandated a "shell-free" probe, but the probe routed Windows `.cmd`/`.bat` shims through `cmd.exe /c` — a
contract/impl mismatch I introduced (I wrote "shell-free" while building a shell-mediated shim path). The loop guard
fired; the maintainer chose **option 1 (shell-safe reconciliation) + Linux compatibility**.

Implemented (FR-053a amended shell-free → SHELL-SAFE + CROSS-PLATFORM):

- A NATIVE executable (Windows `.exe`; any POSIX binary / shebang script) is invoked DIRECTLY with a fixed argument
  vector — genuinely shell-free on every OS (codex/claude resolve to `.exe`; all Linux hosts take this path). A
  Windows `.cmd`/`.bat` shim (the ONLY interpreter-mediated case, and Windows-only) is invoked via cmd.exe with the
  resolved path REFUSED if it bears a shell metacharacter (`% ! & ^ | < > "`) — no untrusted input reaches the
  interpreter; the injection surface is FALSIFIED by test (a `&`-bearing shim path is refused and never executes).
- CROSS-PLATFORM tests: every fake is now a Windows `.cmd` OR a POSIX shebang script (`SetUnixFileMode +x`); the
  production-path test's backslash path literals were corrected to forward slashes (they broke `Join-Path` on Linux).
  Added falsification tests (native-direct shell-free; the Windows shim injection-guard, `-Skip` on non-Windows).
- **Verified on BOTH OSes.** Windows: the full 36-suite registry is green. Linux (Docker, pwsh 7.4.2, Pester 5.6.1):
  the probe smoke, the three unit suites (43/0 + 1 correctly-skipped Windows-only injection test, 10/0, 19/0), and the
  FULL production-path integration (all 8 findings) are all green. CI runs on `ubuntu-latest`, so Linux correctness is
  a release requirement — now met and demonstrated, not merely reasoned.
- Files: `scripts/internal/continuous-co-review/hook-health-receipt.ps1` (the shell-safe cross-platform probe
  invocation), `spec.md` FR-053a, and the four test suites. The 3 dispatcher copies are UNCHANGED (the probe is
  module-internal) and remain byte-identical. NO deferral to #3084 for this defect.

This reconciliation was committed as `a5838c87` and the evidence re-bound to digest `0062bd89…`
(`command_succeeded=true`). The one authorized `--remediate more-time` re-review then reviewed the change and
returned two mechanical findings (below).

### Fourth round — trusted shim interpreter + evidence reconciliation (2026-07-14, maintainer-routed mechanical fixes)

The `more-time` re-review of the shell-safe reconciliation returned TWO blocking findings, both actionable +
mechanical (verified against disk before fixing, per the maintainer's routing):

1. **Ambient interpreter (`hook-health-receipt.ps1`).** The shim injection-guard covered the shim PATH, but the
   INTERPRETER itself was `$env:ComSpec` (or PATH-resolved `cmd.exe`) — a caller controlling the inherited
   environment could substitute an arbitrary executable and run attacker code during SessionStart / doctor /
   preflight (and still emit a matching version). Fixed: cmd.exe is now resolved from the trusted OS system
   directory (`[Environment]::SystemDirectory` → Win32 GetSystemDirectory, NOT the mutable `%ComSpec%`/`%PATH%`),
   fail-closed if absent. A unit test AND a production-path test FALSIFY the hijack: a bogus / empty `$env:ComSpec`
   is ignored and the probe still uses the trusted System32 cmd.exe.
2. **`state.md` overclaim + inconsistency.** The record claimed done/green without a worktree-traceable digest-bound
   execution record, said "35 suites" in one place while another said "36", and kept forward-looking "must re-bind"
   language after the re-bind had happened. Fixed: the suite count is reconciled to 36; the stale language is
   corrected to past tense; and the exact cross-platform commands + results + reviewed digest are recorded durably
   in `iterations/005/evidence/shell-safe-cross-platform-verification.md`, with the digest-bound machine record in
   the co-review evidence store.

Per the maintainer's routing for mechanical findings, these fixes are committed and RETURNED; NO further review round
is launched automatically — the maintainer decides whether to authorize additional review budget.

### Fifth round — Proposal-145 review + Option A hook-health redesign (2026-07-14)

The confirming round's Proposal-145 review returned THREE authoritative findings (focused tests green + the System32
cmd.exe fix correct, but not approvable):

1. **Bounded output.** The version probe was time-bounded but not MEMORY-bounded (`ReadToEndAsync`). FIXED: a
   byte-capped (8 KB) concurrent drain of stdout+stderr, tree-killed on timeout, fail-closed on overflow, nothing to disk.
2. **Ambient executable identity.** The host EXECUTABLE was still ambient-PATH resolved, so a prepended shim could be
   described as the host and (with matching versions) promote health. Characterization (2026-07-14) confirmed NO host
   (claude/codex/copilot) exposes a trustworthy non-ambient executable path/version — only the deploy-baked
   `-HostKind` (kind, not version). Per the maintainer's **Option A (amended)**: the version is a NON-PROMOTING
   `ambient-path-binding` DIAGNOSTIC; the receipt (contract **v3**, +field `version_source`) SEPARATES hook-liveness
   from the version; the resolver returns INDEPENDENT `hook_status` (healthy|stale|malformed|conflicting|absent) +
   `version_status` (diagnostic-match|diagnostic-drift|unavailable|untrusted-source); readiness rests on fresh
   hook-liveness + the existing Codex config/trust prereqs, NEVER the version. Receipts are MONITORING evidence, not
   authentication (the store is project-writable and the dispatcher can be invoked directly) — the earlier over-claim
   that "a PATH shim cannot forge hook-fire" is RETRACTED. `-ArgsOverride` removed (fixed host-declared args only).
   FR-053a amended + recorded as explicit design drift. Forbidden vocabulary ("trusted host version", "actual
   host-process version", "unforgeable hook receipt") is absent from the implementation.
3. **Unsupported evidence.** The prior evidence doc overclaimed (placeholders, uncommitted script, Windows-only
   machine record, stripped store). FIXED: a committed, replayable `tests/cross-platform-verify.ps1`; the T019
   step-6 evidence-injection reader broadened to accept T018 `runs` (so exact-digest recorded runs are injected as
   `.review/implementer-evidence.json`); the evidence doc rewritten to reference the injected machine record, not
   hand-copied fields.

Verified green on Windows (the focused suites + the full F-198 regression registry) AND Linux (Docker
`cross-platform-verify`). The exact replayable commands are committed. Per the recording protocol, the Windows AND
Linux runs are recorded via the T018 wrapper against the committed reviewed digest immediately AFTER the
evidence-bearing commit (the digest-keyed machine record in the co-review evidence store), and at review time
`Copy-ContinuousCoReviewImplementerEvidence` injects that record into the reviewer worktree as
`.review/implementer-evidence.json` (the reviewer's authoritative machine evidence — see
`iterations/005/evidence/shell-safe-cross-platform-verification.md`). Exactly one confirming review round is then
requested.

### Sixth round — the authorized confirming round (2026-07-14, run 20260714T123137002-4f3689f3) + 5 T018/T019 fixes

The maintainer-authorized ONE confirming round ran against the reconciled committed digest with the three
T018-recorded runs (Windows focused + full 36-suite registry + Linux Docker) injected as
`.review/implementer-evidence.json` — the prior "evidence unverifiable-here" finding did NOT recur (the injected
digest-bound machine record resolved it), and the Prop-145 hook-health redesign itself returned NO findings. The
round returned **5 NEW blocking findings**, all on the adjacent T018/T019 verification-plan machinery (the
recorder plus the plan contract/runner), none flagged human-decision. Per the completion protocol they are FIXED,
not waved through — each with a paired falsification test:

1. **f1 (contract, ancestor-link escape).** Path safety dereferenced only the FINAL item, so an ordinary file/dir
   below an escaping symlink/junction ancestor read safe. Fixed: every existing path component is walked root-down;
   a link component must resolve inside RepoRoot and the walk continues from the RESOLVED location (nested links
   validated too). Tests: below-link dir + file refused; an inside-repo link stays accepted.
2. **f2 (runner, env_refs execution semantics).** `env_refs` were recorded but never applied — the child inherited
   the FULL ambient environment. Fixed: the child now receives EXACTLY a safe non-secret baseline + the declared
   env_ref names (values resolved at spawn, never recorded) via a constructed-environment seam in the recorder
   (`-ChildEnvironment` clears + rebuilds the process environment). Test: a declared name is visible in the child;
   an unlisted ambient sentinel is structurally absent; the store carries neither value.
3. **f3 (recorder, output persistence).** `truncated_tail` persisted literal command output (a printed secret would
   persist into reviewer-visible digest-bound evidence). Fixed two-layer: supplier-declared plan commands persist
   NO output text at all (`-OutputTailBytes 0` — count/hash only), and every remaining tail passes a
   credential-pattern redactor (`Get-ContinuousCoReviewRedactedOutputText`: KEY=VALUE credentials, authorization/
   bearer headers, URL userinfo) before serialization. Tests: runtime-assembled sentinels printed to stdout+stderr
   are absent from the reloaded durable record; suppression mode persists no output text.
4. **f4 (runner, CWD-relative paths).** `working_directory`/`result_path` were resolved against the caller process
   CWD (and result_path against the working directory), contradicting the schema's repository-relative semantics.
   Fixed: both anchor against RepoRoot before execution. Test: a plan invoked from OUTSIDE the repository runs in
   RepoRoot/subdir and finds its required result at RepoRoot-relative result_path.
5. **f5 (recorder+runner, identity not durable).** command_id/provenance/env_refs were tagged only on the in-memory
   return — the persisted run could not join on command_id + reviewed digest, and the dedup key
   (executable+arguments) let two distinct plan commands with the same invocation clobber each other. Fixed: the
   recorder persists command_id/provenance/env_ref names INTO the durable record; the uniqueness key is command_id
   when present (else executable+arguments+working_directory). Test: two same-invocation/different-id commands
   reload as two separately joinable records that pass the T019 evidence join at the exact digest.

Files: `test-evidence-recorder.ps1`, `verification-plan-contract.ps1`, `verification-plan-runner.ps1` + their three
test suites. After this commit the evidence re-binds (Windows focused + full registry + Linux Docker re-recorded at
the new committed digest); NO further review round is launched automatically — the one authorized confirming round
is spent, and the maintainer decides whether to authorize the re-review that would close Iteration 005.

### Seventh round — the f2/f3 residual HUMAN DECISION + full fix (2026-07-14, run 20260714T130410888-bc28813e)

The post-fix re-review (round 2, run `20260714T130410888-bc28813e`, 13:04–13:08Z) returned ONE blocking finding
flagged **HUMAN DECISION REQUIRED**: the sixth-round f2/f3 fixes were incomplete — (f2 residual) the constructed
child environment still passed an implicit ambient baseline (`HOME`, `USERPROFILE`, `LOCALAPPDATA`, `APPDATA`,
`TEMP`, `PATH`, `PSModulePath`, locale/terminal) the env_refs contract never sanctioned; (f3 residual) the generic
recorded-run default still persisted a 2048-byte redacted tail, and pattern redaction cannot recognize an
arbitrary bare secret. The loop guard correctly stopped the autonomous review/fix loop; both residual claims were
VERIFIED against disk before escalating.

**MAINTAINER DECISION (2026-07-14, instruction-bearing verdict):** implemented in full —

1. **Child environment (f2):** constructed from an **EMPTY map**; a **normative, platform-specific engine
   baseline** where every variable requires paired runtime-evidence tests (probes prove a resolved-full-path
   child launches with a completely empty environment on Windows AND Linux, so the baseline is **EMPTY on
   both**); `HOME`/`USERPROFILE`/`APPDATA`/`LOCALAPPDATA` excluded by ruling; `PSModulePath`/locale/terminal/
   tool vars are explicit env_refs; the executable is **resolved to a full path BEFORE the environment is
   constructed** (rooted / repo-relative / ambient-PATH `Get-Command`; unresolvable → recorded
   `executable-not-resolvable` failure, never a silent skip). Contract recorded in the VerificationPlan schema
   (`env_refs` description) + spec FR-015. Paired cross-platform tests: engine-baseline evidence (empty-env
   launch), identity-path exclusions + a parent-PATH sentinel that must NOT flow, declared-ref visibility,
   undeclared-ambient absence, bare-name resolution, unresolvable-recorded-failure.
2. **Output (f3), B1 + disclosure door:** generic recorded-run default `OutputTailBytes` **2048 → 0** (output
   text private by default; count/hash/artifact-digest/structured-result facts unchanged); explicit opt-in
   tails clamped to an **8 KB engine cap** and labeled (`tail_disclosure`: suppressed | bounded-redacted-tail |
   authorized-diagnostic); a FAILED command with suppressed output records
   `failure_diagnostics: insufficient-without-disclosure` (honest, never a clean result); a **human-authorized
   diagnostic disclosure** `{ authorized_by, reason, command_id, max_tail_bytes? }` is the only door — bounded,
   scoped to the ONE named command, auditable, labeled `potentially_sensitive`, **DURABLE** in the digest-keyed
   store by design (durability is the audit trail; tested), and never automatic (malformed → fail-loud; plan
   runner refuses fail-fast with zero commands run). Redaction remains defense-in-depth on opted-in tails.
   Falsification: an UNSTRUCTURED bare secret printed alone is absent from the durable record on the default
   path. Policy: raw verification output is private by default; a reviewer may request explicit human-authorized
   disclosure when its absence prevents an accurate conclusion.
3. **Stop-packet hardening (new scope, FR-055 + DRIFT-198-I003-008):** the five-heading packet demand now keys
   on the TURN'S OWN delta (SessionStart/discharged-stop baseline; managed-count drift stripped from the surface
   key), a deterministic long-turn lane covers packet-worthy read-only investigations, a PostToolUse
   one-per-obligation-window nudge arranges the packet IN the original response, and the six-section boundary
   contract is untouched. Six maintainer fixtures (PH-a…PH-f) green; suite Case 5 was found ALREADY RED at HEAD
   (stale vs the ratified T099/N3 contract) and reconciled test-only, with Case 5b proving the intake nudge
   survives where the parse runs.

Per the review-control directive: fixes are committed, evidence re-binds to the new committed digest (Windows
focused + full registry + Linux Docker via the T018 wrapper), and **NO review round launches** — the maintainer
authorizes any re-review separately. Iteration 005 completion (and the release of T019 pieces 5-7) remains
PENDING that separately-authorized clean re-review.

### Eighth round — the maintainer-authorized re-review (2026-07-14, run 20260714T172315119-93949663) + 5 fixes

The maintainer's "authorized" verdict was executed as: `--remediate resolved-against-disk --fix-evidence-ref
f8df5f8a` (recorded by Alon Fliess), then ONE re-review (`--live --code-writer-host claude`, auto-anchored)
against the committed digest `3a3c3d7e…` with the injected three-run T018 evidence. The round returned
**5 blocking findings**, none human-decision — all VERIFIED against disk before fixing, all fixed with paired
falsification tests per the completion protocol:

1. **f1 (containment case-sensitivity).** Every containment comparison (path-safety lexical guard + symlink
   targets in `verification-plan-contract.ps1`; repo-relative executables in `verification-plan-runner.ps1`)
   used OrdinalIgnoreCase — on a case-sensitive platform `../Repo/...` escaped `/tmp/.../repo`. Fixed:
   `Get-ContinuousCoReviewPathComparison` (ignore-case ONLY on Windows) routed through every check. Linux-only
   case-variant regressions (`-Skip:$IsWindows`) for working_directory, result_path, symlink target, and a
   repo-relative executable whose case-variant sibling carries a REAL executable that must never run.
2. **f2 (future-dated receipt false-green).** Hook-health freshness never rejected a negative age: a
   well-shaped future-dated receipt read `healthy` (and Codex preflight `ready`) until its future instant plus
   the freshness window. Fixed: beyond a 5-minute clock-skew tolerance → `malformed` (never healthy/ready);
   within-tolerance skew still healthy. Paired classifier + preflight tests.
3. **f3 (embedded-digest bypass).** The production evidence lookup validated only the envelope digest, so a
   digest-B-keyed record carrying a digest-A run injected as B evidence. Fixed: the lookup/copy path now
   enforces `Test-ContinuousCoReviewEvidenceInjectable` (envelope AND every embedded digest; missing embedded
   identity fails closed), and BOTH writers stamp `reviewed_digest_tree_id` into every embedded entry.
   Production regressions: a tampered mixed-digest record and an identity-stripped entry are refused at
   lookup AND Copy (the reviewer gets no evidence, never wrong evidence).
4. **f4 (lease-token wildcard).** `Test-ContinuousCoReviewLeasePromotionAuthority` treated an empty
   CompletingOwnerToken as a wildcard — run-id knowledge (or a token-less legacy/corrupt registry) substituted
   for lease ownership. Fixed: owner match now requires a NON-EMPTY, exactly-equal token; the live spawn path
   already stamps the token into every registry it writes, so only token-less registries demote to advisory.
   Unit regression (empty/omitted/forged token all `not-lease-owner`) + a navigator production-path regression
   (a token-less completion naming the lease's own run_id blocks nothing; advisory note only).
5. **f5 (open schema at the validation boundary).** The in-code plan validator never enforced
   `schema_version == '1.0'` or the schema's `additionalProperties:false`, so unknown fields (including a
   literal secret-bearing map under any name other than env/environment) validated and executed. Fixed:
   closed key sets at plan/command/provenance levels + the schema_version const, with the env/environment
   teaching error preserved. Regressions: missing/wrong version, unknown plan/command/provenance properties,
   a `secret_env` map, and a fully-populated valid plan proving the closed set is complete, not over-tight.

Focused suites 152/152 green on Windows (2 Linux-only cases correctly skipped there); full registry +
cross-platform Linux verify re-run and the evidence re-bound to the fixes commit's digest. Per the standing
directive, NO further round launches — the round consumed the authorization, and the maintainer decides
whether to authorize the next (potentially closing) re-review.

### Ninth round — round 1 of the 5-round authorization (2026-07-14, run 20260714T180554025-b1f7ddce) + 3 fixes

The maintainer authorized **up to 5 additional review rounds** (2026-07-14). Round 1 ran after
`resolved-against-disk --fix-evidence-ref 6de77f5e` and returned **3 blocking findings**, none human-decision —
schema-conformance edges in the eighth-round f5 fix and the SpecrewTestResult validator. All verified and fixed
with paired regressions:

1. **f1 (null-valued env bypass).** The closed-key allowlist kept `env`/`environment` (for the teaching error)
   but the forbidden-map check tested VALUE non-null — `"env": null` validated. Fixed: presence-based rejection
   (`Test-ContinuousCoReviewPropertyPresent`); the teaching error is preserved; null-valued regressions added.
2. **f2 (type coercion instead of validation).** String fields stringified numerics; `timeout_seconds` was not
   checked as a nonnegative integer; `require_result` not as boolean (`"false"` cast to `$true`);
   `working_directory`/`result_path`/`label`/`plan_id`/`schema_version`/provenance fields untyped. Fixed:
   schema-type validation (string/integer/boolean, minimum 0) at plan/command/provenance levels — validated,
   never coerced; wrong-type regressions for every field including the reviewer's exact `require_result:
   "false"` example.
3. **f3 (counts:null + Int64 narrowing).** A present-but-null `counts` was treated as absent (granting
   structured-result standing to a schema-invalid artifact), and schema-valid counts beyond Int32 threw in the
   `[int]` narrowing instead of recording verbatim. Fixed: presence-based null rejection
   (`counts-null-not-object`) + `[long]` preservation; required-result regressions for both.

Focused suites 80/80 green on Windows; full registry + Linux Docker verify re-run and the evidence re-bound to
the fixes commit. Rounds consumed of the 5-round authorization: 1. The loop continues per the authorization —
clean closes Iteration 005; a human-decision finding stops immediately.

### Tenth round — round 2 of the 5-round authorization (2026-07-14, run 20260714T182921446-f1e5c4f0) + 4 fixes

Round 2 ran after `resolved-against-disk --fix-evidence-ref 8c1495e3` and returned **4 blocking findings**, none
human-decision — all verified and fixed with paired regressions:

1. **f1 (unverified stale-result deletion).** The pre-run stale-result delete swallowed errors and never
   verified the file disappeared — an undeletable (locked/permission) schema-valid stale result could be read
   as this run's rich claim. Fixed: deletion is VERIFIED; still-present → the run REFUSES to execute
   (fail-loud, zero side effects). Regression: Windows share-read/deny-delete handle; Linux read-only parent —
   both throw before execution, sentinel proves the command never ran.
2. **f2 (char-counted probe cap).** FR-053a's 8 KB probe cap counted decoded CHARS — multibyte output consumed
   ~3x the contract bytes before tripping. Fixed: UTF-8-pinned stream decoding + ENCODED-BYTE accounting per
   chunk (`SpecrewHostVersionProbeMaxOutputBytes`). Regression: 3,000 euro signs (3,000 chars, 9,000 bytes)
   fail closed.
3. **f3 (result file flips the reviewed digest).** A run-produced result_path file stayed in the tree while
   the digest was bound pre-execution — the evidence could never exact-match the reviewed state. Fixed:
   TRANSIENT result lifecycle — the file is a transport, deleted right after reading (valid or invalid); its
   validated content persists in the record; a cleanup failure warns and the evidence honestly orphans
   itself. Regression: digest identical before/after a structured-result run.
4. **f4 (synthetic failures not durable).** Verification failure records existed only on the in-memory
   return — the digest-keyed store (what the reviewer injection reads) omitted attempted failures,
   contradicting FR-048 record-every-attempt. Fixed: the store writer is extracted
   (`Save-ContinuousCoReviewRunRecord`) and every synthetic failure persists through it (digest-unavailable →
   loud warn, in-memory only). Regression: each runnable-plan failure classification reloads from disk,
   joins at the exact digest, and passes the production lookup.

Focused suites 134/134 green on Windows; full registry + Linux Docker verify re-run; evidence re-bound to the
fixes commit. Rounds consumed: 2 of 5.

## Notes

- **Verification (current — see the cross-platform evidence record).** The full F-198 honesty regression
  suite (`pwsh -File tests/f198-regression-suite.ps1`) is GREEN on Windows — all **36** suites pass (the
  self-leak firewall with the dispatcher comments + aggregator in scanned surfaces staying deny-list clean;
  T035/T036/T037/T038/T039; and the iter-005 hook-health production-path suite). It ALSO passes on Linux via
  Docker (pwsh 7.4.2). The EXACT commands, results, and reviewed digest for BOTH OSes are recorded durably in
  `specs/198-beta2-hardening/iterations/005/evidence/shell-safe-cross-platform-verification.md`, and the
  digest-bound machine record of the registry run is in the co-review evidence store
  (`.specrew/review/test-evidence/<committed-digest>.json`, `command_succeeded=true`). End-to-end dispatcher
  firing (SessionStart / Stop / agentStop write a receipt; PostToolUse does not; every dispatch exits 0) and the
  doctor aggregator render (verified tiers with provenance + a fresh receipt reading `healthy` + the Codex
  preflight flipping ready) were both exercised directly.

- **Protected-file discipline (F-184).** No edit to `scripts/specrew-hooks.ps1` or
  `scripts/internal/specrew-hook-health.ps1`. The doctor surfacing is delivered through
  the new non-protected aggregator + a documented one-line call the maintainer may add
  to the protected `Show-Status` at their discretion.

- **Mirror parity.** The task's explicit parity requirement (extension source ↔
  `.specify` mirror) holds byte-for-byte. The broader `ProviderMirrorParity.Tests.ps1`
  (module ↔ extension ↔ `.specify`) is a self-host meta-test that is not part of the
  F-198 suite and was already RED on an unrelated provider (`specrew-bootstrap-provider`)
  before this work; the dispatcher change introduces no NEW divergence between the module
  and extension copies.

- **Scope.** FR-054 (Codex plugin packaging regression) is NOT a Beta2 deliverable and
  stays in issue #3084 / Beta3, alongside richer desktop / IDE / cloud certification and
  host capability negotiation. Nothing here implements it.
