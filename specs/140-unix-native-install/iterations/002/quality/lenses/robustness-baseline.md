# Robustness Baseline Lens — Iteration 002

**Lens**: `robustness-baseline@v1.0.0`
**Reviewed By**: Crew Reviewer
**Subject**: `install.sh` failure semantics + idempotency.
**Verdict**: `pass` (design-level; runtime proof pending Ubuntu CI — T015).

## Failure semantics

- Every failure path exits non-zero with an actionable message via `fail_closed` (unsupported OS/distro,
  unreadable/incomplete os-release, PMC `.deb` 404, `pwsh` still absent after install, module/wrapper
  install failure). No silent failure; no partial install reported as success. ✔
- `set -eu` aborts on any unhandled error or unset variable; `${VAR:-}` guards intentional optionals. ✔
- The wrapper's own pwsh-missing path (FR-004) is unchanged and still errors non-zero with a hint — the
  wrapper never installs pwsh (only `install.sh` does). ✔

## Idempotency

- **install-only-if-absent**: `ensure_pwsh` returns early if `pwsh` is present (never clobbers/upgrades);
  `ensure_specrew_module` skips the gallery install if a module is already discoverable. ✔
- **Idempotent repo-add**: re-installing `packages-microsoft-prod` re-registers the same key+source (no
  duplicate apt source on re-run). ✔
- Re-running the whole bootstrap converges (skip pwsh, skip module if present, re-install wrappers
  idempotently per the Iteration-1 installer). To be confirmed by the Ubuntu CI re-run dimension. ✔ (design)

## Not applicable

- Network retry/reconnect: `apt-get` + `Install-Module` are user-re-runnable one-shots; no long-lived
  connection or transactional state to recover. N/A (recorded).

## Evidence

- Code: `install.sh`. Runtime: Ubuntu CI `feature140-install-bootstrap` + `install-sh-detect.sh`
  (fail-closed cases) — pending green CI run.
