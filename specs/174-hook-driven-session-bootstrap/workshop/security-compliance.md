# Security Compliance Workshop Record

**Lens**: security-compliance · **Depth**: medium · **Confirmation**: human-confirmed
**Facilitated**: one decision at a time with the human (2026-06-08).

```text
LOCAL, single machine (today's default; write-only, no push)
   repo/worktree = trust boundary -> handover is as trusted as the code/hooks that
   already execute. Anyone who can write handover.md can write the hook scripts.
   No injection containment needed (it would be theater).

CROSS-MACHINE / CI / hosted / multi-tenant  (NOT this feature)
   committed+pushed handover pulled elsewhere, or bootstrap where the repo isn't
   trusted -> real adversarial surface -> deferred to a separate proposal.
```

## Decision 1 - input trust model (security vs governance)

**Chosen: trust boundary = the local project tree. Validate for correctness, not
anti-injection.**

- Bootstrap inputs (hook event JSON, handover content, session-state/anchor fields,
  absolute paths, start marker) are trusted to the **same degree as the hooks/code that
  already execute locally**. A local attacker who can write these files can already write
  the executable surface, so hardening one markdown file is theater.
- Inputs are still validated for **correctness and fail-safety**: schema/shape,
  path-portability (re-resolve to project-local; reject foreign absolute paths),
  freshness, and project-state consistency. These are correctness controls, not
  attacker controls.
- **Security vs governance distinction:** the property that actually matters - external
  state never auto-authorizes a gate - is *governance/correctness* (decision 2), and we
  keep it regardless of trust.

### Proposal candidate (FILE TO MAIN LATER - not on this feature branch)

**Specrew adversarial / untrusted-artifact security posture.** Scope: threat model and
hardening for contexts where the local tree is NOT the trust boundary - committed+pushed
handover/state pulled across machines, CI, hosted, or multi-tenant execution. Covers
untrusted shared artifacts, supply-chain, and CI identity. Surfaced by the F-174
security-compliance lens; explicitly **out of scope** for Feature 174 (which assumes a
trusted local dev tree).

## Decision 2 - lifecycle-authority boundary

**Chosen: option 2 - advisory + explicit non-authorization, re-anchored to the real gate.**

- External state can **inform**, never **authorize**. The directive labels any
  handover/anchor next-step as "advisory from a prior session; confers no authorization;
  the human must still authorize the next boundary" (Rule 1).
- Bootstrap always re-presents the actual gate requirement; **no auto-advance, ever** -
  even with a fully-trusted, fully-honest handover.

## Decision 3 - failure-safe posture

**Chosen: fail-open on availability, fail-closed on authority.**

- **Fail-open on availability:** invalid / missing / stale / untrusted state never blocks
  the user from starting work - worst case is "offer full bootstrap."
- **Fail-closed on authority:** no input failure or ambiguity ever auto-advances or
  continues a boundary - uncertainty defaults to "require human authorization / offer
  menu, never silent resume."
- Net: a broken/stale/ambiguous startup can cost a resume convenience, but can never
  lock the user out of starting, nor cross a gate on their behalf.
