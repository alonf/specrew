# Security-Compliance Lens — iter-008 reviewer-context redesign

## Lens
security-compliance (medium). Reuses + STRENGTHENS F-197's reviewer trust boundary
(workshop/security-compliance.md line 42: "the reviewer is a trusted component, not an adversary; the boundary
is not 'hide repo context', it is 'do not package/persist ambient secrets and do not allow mutation'").

## Trust boundary (agreed)
```text
  REAL PROJECT REPO   (never touched — read-only source of truth)
        │  git archive of the project tree
        ▼
  EPHEMERAL READ-ONLY-SOURCE WORKTREE   (disposed after the run; disposition=discard)
   ├─ the user's project — reviewer SEES ALL of it (no confidentiality blinding: secrets/config visible)
   ├─ methodology machinery (.specrew/.specify/.squad + deployed runtime) stripped — RELEVANCE, not secrecy
   ├─ gitignored ambient (.env, keys, token stores) absent (not in the git tree)
   └─ .review/changes.diff + .review/design/*   (the review entry point)
        │  TRUSTED AGENT reviewer (claude -p / codex with read+run tools):
        │     SEES ALL · RUNS ALL (executes tests/builds/exploration to VERIFY) · CANNOT FIX the source
        ▼
  FindingsResult → durable blackboard/audit   (secret VALUES redacted to location; no ambient/machine state)
```

## Decisions (human-confirmed)
1. **Reviewer is a fully-trusted component: SEES ALL + RUNS ALL.** No confidentiality blinding within the
   project; the reviewer is an AGENT that may execute (run tests, build, explore) in the ephemeral worktree to
   verify the change — a strengthening of F-197 (which was read-only). This is the headline capability gain.
2. **The ONLY restriction: it CANNOT FIX the code.** It emits a FindingsResult, never patches; the real repo is
   never mutated; the worktree is ephemeral (discard disposition); any run side-effects vanish with it. Fixes
   come from the code-writer agent via the result-delivery / round loop (review -> findings -> fix -> re-review).
   This closes G2 (today `--live` runs the reviewer in the REAL repo).
3. **Confidentiality is only about durable ARTIFACTS.** FindingsResult / blackboard / audit redact secret VALUES
   to a location and never persist ambient/machine state or raw transcripts. The reviewer may SEE secrets
   (trusted); it just must not echo their values into the record.
4. **Methodology-machinery strip = relevance, not secrecy** (orthogonal to "see all"): review the user's
   project, not Specrew's own deployed scripts. Open to keeping literally everything if the maintainer prefers.

Human verdict: "the reviewer must be able to see all, and run all. It is a trusted component. The only
restriction is that it can't fix the code."
