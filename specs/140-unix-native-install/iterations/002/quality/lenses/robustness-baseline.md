# Robustness Baseline Lens — Iteration 002

**Lens**: `robustness-baseline@v1.0.0`
**Reviewed By**: Crew Reviewer
**Subject**: `install.sh` failure semantics + idempotency.
**Verdict**: `pass` — design + **partially runtime-recorded** (Ubuntu CI run 26812981387 green: fail-closed 5/5 + pwsh install-**when-absent** + **module** skip-if-present recorded). Full re-run idempotency (apt repo-add re-registration, pwsh skip-**if-present**) is **design-asserted, not exercised this iteration** — the CI runs `install.sh` exactly once, as root, with pwsh absent — and is deferred to Iteration 3 (a cheap second-run assertion).

## Failure semantics

- Every failure path exits non-zero with an actionable message via `fail_closed` (unsupported OS/distro,
  unreadable/incomplete os-release, PMC `.deb` 404, `pwsh` still absent after install, module/wrapper
  install failure). No silent failure; no partial install reported as success. ✔
- `set -eu` aborts on any unhandled error or unset variable; `${VAR:-}` guards intentional optionals. ✔
- The wrapper's own pwsh-missing path (FR-004) is unchanged and still errors non-zero with a hint — the
  wrapper never installs pwsh (only `install.sh` does). ✔

## Idempotency

- **install-only-if-absent**: `ensure_specrew_module` skip-if-present **ran on CI** (module pre-seeded →
  "already available, skipping the gallery"). `ensure_pwsh` skip-if-present did **not** run this iteration
  (pwsh was absent → the install path ran); design-verified, runtime proof deferred. ✔ (module) / design (pwsh)
- **Idempotent repo-add**: re-installing `packages-microsoft-prod` re-registers the same key+source (no
  duplicate apt source). **Design-asserted — NOT exercised this iteration** (single CI run, no re-run). ◻ (Iter-3)
- Re-running the whole bootstrap converges (skip pwsh, skip module if present, re-install wrappers
  idempotently per the Iteration-1 installer). A second `install.sh` run asserting no duplicate apt source
  is the cheap Iteration-3 proof. ◻ (design; Iter-3)

## Not applicable

- Network retry/reconnect: `apt-get` + `Install-Module` are user-re-runnable one-shots; no long-lived
  connection or transactional state to recover. N/A (recorded).

## Evidence

- Code: `install.sh`. Runtime: Ubuntu CI `feature140-install-bootstrap` + `install-sh-detect.sh`
  (fail-closed cases) — **runtime-recorded: CI run 26812981387 green**.
