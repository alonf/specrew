# Security Baseline Lens — Iteration 001

**Feature**: 140-unix-native-install
**Lens**: `security-baseline@v1.0.0`
**Scope**: explicit security review of the installer + wrapper surfaces (maintainer instruction). The baseline Reviewer owns the final review-signoff verdict; this lens is the security input.
**Reviewed**: 2026-06-02 (planning + implementation-time analysis; Unix runtime confirmation deferred to Iteration 2 CI)
**Verdict**: pass — no blocking security findings for Iteration 1; controls in place.

The five surfaces the maintainer flagged as security-sensitive, reviewed explicitly:

## Surface 1 — bin-dir confinement (`install-shell-wrappers`)

- **Risk**: writing outside the requested bin dir; clobbering a user's real file; mutating shell profiles.
- **Controls**: the installer writes ONLY inside the resolved `-BinDir`; never edits shell profiles; a missing dir requires `-Force`; an existing **non-symlink** file requires `-Force` (`Get-WrapperInstallPlan` returns `skip-needs-force`, so a user's real `specrew` file is not clobbered silently); `-WhatIf` changes nothing.
- **Evidence**: `install-shell-wrappers.tests.ps1` (decision matrix incl. `skip-needs-force`; Windows no-op = zero writes). Unix write-confinement runtime → Iteration 2 CI (T011).
- **Assessment**: pass.

## Surface 2 — `curl | sh` trust (`install.sh` bootstrap)

- **Risk**: piping a remote script to `sh` is a trust-on-first-use surface.
- **Status**: `install.sh` is **Iteration 2** (not implemented here). Specified controls for Iter 2: verify `pwsh` (never auto-install); `Install-Module Specrew` from PSGallery (known registry); then invoke the local `install-shell-wrappers` (no arbitrary remote execution beyond the reviewable bootstrap). Docs must show the canonical URL and a "review before piping" note.
- **Assessment**: deferred to Iteration 2 (controls specified; security review will run on that slice).

## Surface 3 — argument forwarding (wrappers)

- **Risk**: shell injection / argument mangling through the forwarder.
- **Controls**: wrappers `exec ... "$@"` — no `eval`, no unquoted expansion, no re-quoting of user args; thin (no option parsing); `#!/usr/bin/env sh` + `set -eu`.
- **Evidence**: generator test asserts thin forwarders (no `getopts`); `bash -n` clean on all 8. Quoting/spaces/`--` forwarding runtime → Iteration 2 CI (FR-002).
- **Assessment**: pass (design); runtime confirmation in Iteration 2.

## Surface 4 — symlink resolution (wrappers)

- **Risk**: symlink-following resolving to an attacker-controlled path; infinite loops.
- **Controls**: the `while [ -L ]` loop resolves the wrapper's own `$0` (not user input); relative vs absolute link targets handled via `case`; resolution terminates at the module's own real `bin/` file. No user-controlled symlink is followed.
- **Assessment**: pass.

## Surface 5 — `pwsh` invocation / `ExecutionPolicy` (wrappers)

- **Risk**: `-ExecutionPolicy Bypass` could execute untrusted scripts.
- **Controls**: `Bypass` is scoped to a SINGLE `exec` of the module's own `scripts/specrew.ps1` (a trusted, shipped file resolved via the module root) — never an arbitrary or user-supplied script path. `-NoProfile` avoids profile injection. This is the standard pattern for a module-shipped launcher.
- **Assessment**: pass (Bypass is scoped to the trusted module entrypoint only).

## Summary

- No blocking security findings for Iteration 1 (wrappers + installer).
- The `curl | sh` bootstrap trust surface is Iteration 2 — controls specified, security review deferred to that slice.
- Final verdict owned by the baseline Reviewer at review-signoff.
