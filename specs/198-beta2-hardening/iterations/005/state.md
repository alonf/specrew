# Iteration State: 005

**Schema**: v1
**Last Completed Task**: the iter-005 false-green CORRECTION, now SHELL-SAFE + CROSS-PLATFORM (SessionStart version probe + independent current-version gate + FR-053a shell-safe reconciliation; Linux-verified). **Iteration 005 is NOT yet complete** — three co-review cycles fired the loop guard (5 findings → partial-fix on 3+5 → shell-free contract gap), each escalated to the maintainer and fixed under an explicit ruling. The shell-safe fix is DONE + green on Windows AND Linux; ONE final clean re-review closes the iteration and releases T019 pieces 5-7. See the Co-review section at the bottom.
**Tasks Remaining**: commit the shell-safe reconciliation + ONE final clean re-review. **Iteration 005 completion + the release of T019 pieces 5-7 is PENDING that re-review** (see the Co-review section at the bottom). FR-054/plugin packaging (now T040) is NOT a Beta2 deliverable — deferred to issue #3084 / Beta3.
**In Progress**: none
**Baseline Ref**: cf53400a (the T038 commit; T039 is integration work layered on the already-committed T035-T038 modules)
**Updated**: 2026-07-14T00:00:00Z

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
   + a production-path test.
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

After this reconciliation commits and the evidence re-binds to the new committed digest, ONE final clean re-review
closes Iteration 005 and releases T019 pieces 5-7.

## Notes

- **Verification.** The full F-198 honesty regression suite
  (`pwsh -File tests/f198-regression-suite.ps1`) is GREEN — all 35 suites pass,
  including the self-leak firewall (the dispatcher comments + the aggregator are in
  scanned surfaces and stay deny-list clean), T035/T036/T037/T038, and the new T039
  reconciliation suite (18/18). The reconciliation suite also passes standalone.
  End-to-end dispatcher firing (SessionStart / Stop / agentStop write a receipt;
  PostToolUse does not; every dispatch exits 0) and the doctor aggregator render
  (verified tiers with provenance + a fresh receipt reading `healthy` + the Codex
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
