# Manual dogfood protocol — the side-by-side gate disqualifier (F-174 iter-7, T047)

This is the **manual half** of the iteration-007 acceptance gate, and per **Ruling Prompt 3 it is the
disqualifier**: the automatable content-diff (T046,
`tests/integration/contract-parity-side-by-side.tests.ps1`) proves the *contract is equivalent*, but it
**cannot** prove the agent **reads and follows** it — which is the exact iter-6 failure (the agent never read
`last-start-prompt.md`). Both must pass before parity is re-claimed.

The maintainer runs this; it is a clean-session observation, not a file assertion.

## Setup (point the session at this branch's iter-7 code)

The deployed copy of the provider must be iter-7. Two ways:

- **Dev-tree fast path:** set `$env:SPECREW_MODULE_PATH = 'C:\Dev\Specrew-session-bootstrap'` so component
  resolution hits this branch, and ensure the project's deployed extension (`.specify/.../specrew-bootstrap-provider.ps1`)
  is the synced iter-7 provider (T045 — verify with `tests/bootstrap/ProviderMirrorParity.Tests.ps1`).
- **Installed path:** install this branch as the resolvable module, then `specrew init` a fresh project.

Anti-false-green check before trusting anything (the stale-install trap): the resolved module has
`scripts/internal/launch-contract.ps1`, and the project's deployed provider greps
`Write-SpecrewLaunchContractArtifact` ≥ 1.

## Procedure

Run the SAME first prompt (e.g. *"Create a feature for an employee time-tracking app"*) through both paths,
in equivalent project state.

1. **Reference — `specrew start`:** `specrew start --host claude` in an initialized project. Observe the
   agent's first reply: it reads `last-start-prompt.md` and renders the **coordinator contract** — the
   user-profile/expertise adaptation (*"…expert on Software Architecture…"*), the clarify-budget, the
   re-entry-packet promise — then the orientation + the Resume/New/Pick menu, **before** acting on the task.
2. **Test — the hook:** launch `claude` **directly** (no `specrew start`) in the same project. The
   SessionStart hook fires and injects the contract **inline**. Observe the agent's first reply.

## PASS criterion (the disqualifier)

The hook session's lead-up must be **equivalent** to the `specrew start` session's, modulo genuinely
launcher-only bits (host selection, casting). Concretely, the hook session's agent must, **on its first reply
and before acting on the task**:

- render the **coordinator contract**, including the **user-profile/expertise adaptation** line;
- **drive into the governed lifecycle** (lead with orientation, head toward the design workshop at
  `/speckit.specify`) and **not bypass** clarify/governance gates;
- match the `specrew start` session's lead-up in substance.

**FAIL** (parity NOT achieved — do not claim parity, do not advance) if the hook session's agent
**self-orients** from git/config instead, **omits** the user-profile/coordinator content, or treats the
contract as optional. That is the iter-6 outcome; if it recurs, the inlined core was insufficient → expand it
toward full (Ruling b) and/or investigate injection delivery, then re-run.

## Record

Capture the verdict honestly in `specs/174-hook-driven-session-bootstrap/iterations/007/state.md` (host,
date, PASS/FAIL, and a one-line note on what the agent actually rendered). Parity is re-claimed for the
review-signoff packet **only** when BOTH this manual dogfood AND the T046 content-diff are green — never on
T046 alone (that is the build≠live trap one level up).
