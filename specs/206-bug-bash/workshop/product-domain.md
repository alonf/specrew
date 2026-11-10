# Product-Domain Record: 206-bug-bash

**Depth**: Light · **Confirmed**: by the maintainer's typed reply, 2026-11-10 · **Scope**: feature_standalone

**Why Light**: a narrow defect sweep in a known product. Every item was diagnosed before the feature
existed, and nothing changes who Specrew is for or how it is used, so alternatives, competition and
business-model discovery have nothing to decide. *(known)*

## Who is affected

- The maintainer, as release owner: a red nightly nobody sees, 35 suites that never run, and checks that
  pass while broken. *(known)*
- Anyone running `specrew start` without a console (CI, a host-launched start, a fresh checkout): with
  stale session state it spins forever. *(known)*
- Consumer projects using Copilot: asked to pause and confirm Specrew's own instruction refresh. *(known)*
- Anyone closing an iteration with uncommitted artifacts: the check has been inert since 2026-05-16.
  *(known)*
- Feature 203: receives the unproven retry-test candidate and the undone 198/011 work. *(known)*

## Pain and current workaround

The nightly has been red since 2026-08-08 with no alert; the B5F-036 suites burn a full sweep limit; 35
scripts give no signal; the resolver suggests Node/React presets for a PowerShell repository. Today a
maintainer notices by accident and reads logs by hand. *(known)*

## Scope

Items 1, 2a, 2b, 4, 5 and 6a of file:///C:/Dev/specrew-206-bug-bash/specs/206-bug-bash/bug-list.md, each
fix with a failing test first and one bug per commit; the nightly green, then silent unless a new failure;
a one-time triage of history with a closed frozen list. *(known)*

## Non-goals

Item 3's fix; item 6b's claim identity (B5F-022); feature 204's init/bootstrap scope; any change to the
co-review engine or the capture stores; a per-rule validator registry (options A or C). *(known)*

## Constraints

No writes to the real home folder (hook files hashed before and after every run); never
`specrew-update.ps1`; feature 203's protected files untouched; `.squad/active-features.yml` stays
uncommitted; the CI's markdownlint before every push and CI followed after; the first push is asked for;
never main; no pull request without asking. *(known)*

## Rollout

- `206-bug-bash` merges to main by a pull request only when the maintainer asks. *(known)*
- Success shows as the nightly's first green run on main, then a notification only on a new failure.
  That the green holds once 198/011 is abandoned and the frozen list exists is *assumed* until the
  full-repo replay runs on the feature's head.
- After the merge, features 203 and 205 take the fixes by merging main, and 203 removes its temporary
  60-second known-red limits for the two B5F-036 suites. *(known: maintainer's addition)*

## Open, by the maintainer's instruction

- **How the nightly notification reaches a person** (for example an issue opened on the first red night
  and closed on the next green one, versus an email): options are brought to the maintainer; none is
  picked silently. *(unknown)*

## Skipped at Light depth

- Alternatives and competitors: a defect sweep has no alternative product to beat.
- Outcomes and metrics: defined by the spec's success criteria SC-001 to SC-007.
