# Future proposal: OS-enforced reviewer/verification isolation

**Status**: deferred — NOT F-198 / T015 scope. Recorded at the maintainer's option-1 decision
(2026-07-11) as a separate future proposal.

## Why this is deferred, not done

T015 confines the reviewer and any bounded verification by **monitored confinement**: an isolated
worktree snapshot with origin references removed (T013/T014), a strict read-only contract, a before/after
integrity hash of the reviewer's certified inputs that **fails the review** on any out-of-allowlist
mutation, and the T016 detector that monitors and reports boundary-leave attempts. This is honest and
enforced at the engine layer, but it is **not** an OS-enforced filesystem sandbox: a reviewer or a
declared command runs with the ambient authority of the host process, so it can still *attempt* to write
outside the worktree (we detect and refuse when it touches the certified tree; we do not prevent
arbitrary other host writes).

The review rounds that led here (bfc7b5c5 unbounded output, c9abe16d transient-copy race, 4b124d0e
ambient-authority escape, 90173dc6 authority-input tampering) proved that no in-process mechanism can
*prevent* ambient-authority filesystem access — it can only detect and refuse. Genuine prevention needs
the OS.

## Proposed scope (a later proposal)

Run the reviewer host — and any opt-in bounded verification — under real OS confinement:

- **Dedicated process identity**: a low-privilege principal (a distinct local user / service account, or
  a restricted token) that owns the reviewer process, distinct from the maintainer/CI identity.
- **Worktree-only ACL isolation**: filesystem ACLs granting that identity read/write **only** within the
  ephemeral worktree (and its findings output), and no access to the origin repository, the governance
  machinery, or the rest of the host — so an out-of-worktree write is denied by the OS, not merely
  reported after the fact.
- **Platform backends**: Windows job objects + restricted tokens + per-worktree ACLs; Linux user
  namespaces / bind-mounts / seccomp; container-per-review where available. The host-neutral core keeps
  the policy; a per-platform backend enforces it.

## Relationship to shipped T015 behaviour

This proposal would *upgrade* the enforcement layer under the same contract: the prompt's read-only
promise, the integrity check, and the T016 detector stay; OS ACLs would make a violation impossible
rather than detected. Until then, the shipped behaviour is honestly documented as monitored confinement.
