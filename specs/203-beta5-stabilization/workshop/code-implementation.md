# Lens: code-implementation (light)

**Feature**: 203-beta5-stabilization
**Confirmation**: human-confirmed / lens-question, closed with a typed `move on` on Claude, 2026-10-31,
receipt `a698204d0036dc9e0532147bcae46313792ea32a6110d7af5a3779b82a6c6f50`.
**Question**: inherit 202's implementation rules and change only what the budget model touches; reviewer.

## Source of code-rules truth

No new guideline or example project. 203 inherits
`specs/202-beta4-1-ux-stabilization/implementation-rules.yml`; the manifest is
`specs/203-beta5-stabilization/implementation-rules.yml`. Stack unchanged: PowerShell, Markdown, YAML,
JSON (the CI work is GitHub Actions YAML). No new dependency.

```text
 202 manifest (41 catalog rules, 9 custom rules)
   |-- unchanged: naming, small functions, composition without a DI framework, closed DTOs,
   |              immutable facts, CreateNew writes, StrictMode errors, validation boundaries,
   |              mirror parity, FileList, born-clean, scratch-only probes, consumer language,
   |              recovery wording, no new dependency
   |-- changed by 203: 6 rules
   '-- added by 203: 2 custom rules
```

## Changed

1. **`authz-security-context`.** The before-implement verdict, snapshotting the plan's rounds and host
   order, is the only grant. The top-up is the budget-reset fact, minted by the hook. The cycle reserves a
   round within `budget_total` before invocation. No agent mints, raises or resets.
2. **`careful-retries`.** Every rerun has a new run id and reserves one round before invocation; a release
   before invocation spends nothing. **Maintainer addition:** an infrastructure failure spends no round
   but is capped: after N consecutive infrastructure failures on a host the cycle moves to the next host in
   the approved order; when the order is exhausted it pauses for the human. Otherwise a failing reviewer
   loops without spending, the July runaway in another form. N is a named configuration value set in the
   plan. The exhausted-order pause is stop (d): no host left inside the approved order.
3. **`no-magic-numbers`.** The default round budget of 4 goes; rounds come from the plan (0 when none); the
   config ceiling is a named validation bound. The infrastructure-failure cap N is a named value.
4. **`budget-economics-fixtures` (custom, was `pause-economics-fixtures`).** Nothing spends beyond the
   snapshotted budget; reservation before invocation; exhaustion pauses at stop (a); an infrastructure
   failure never consumes a round; N consecutive infrastructure failures move to the next host, an
   exhausted order pauses. RED-first fixtures through the real entry points.
5. **`main-sync-before-implement-packet` (custom, replaces `beta4-line-sync`).** 203 branches from main at
   `df1141a8`. **Maintainer change:** main is merged in BEFORE each before-implement packet is presented,
   never after the approval, because a merge after it changes the tree the approval covered.
6. **`paired-honesty-tests` (custom, extended).** Every mint path gets the no-human-turn fault fixtures and
   the non-approval phrase fixtures (quoted, in backticks, pasted).

## Added

7. **`census-selection`.** Every new `.ps1` under `tests/` is a census suite or joins the reviewed
   non-suite list in the same commit.
8. **`blocking-text-for-humans`.** Any text a hook blocks with is plain words for a human and passes the
   banned-noun check.

## Reviewer

`specrew review --list-hosts --code-writer-host claude` listed codex (default), copilot, cursor-agent,
antigravity as independent and claude as also selectable. The maintainer chose codex at the agenda
confirmation; the plan's budget host order is codex, copilot, claude.

**Maintainer change:** the authorization reference is the typed agenda confirmation's receipt, not a
crew-made label, because the CLI treats that value as the human-provenance anchor. Run:
`specrew review --host codex --authorization-ref 9cf4941286e3612614fee43468e0ec6d4f5c551ca184e07ee52b4bab3b7c16e8`
(succeeded, written to `.specrew/reviewer-hosts.json`).

## Bindings

- `code-rules-source`: `inherit-202-manifest`
- `rules-changed`: `authz-retries-magic-numbers-economics-main-sync-honesty`
- `rules-added`: `census-selection-blocking-text`
- `infra-failure-cap`: `n-consecutive-then-next-host-exhausted-order-pauses`
- `main-sync`: `before-implement-packet-never-after-approval`
- `dependency-stance`: `use-existing-no-new-dependency`
- `reviewer-host`: `codex`
- `reviewer-authorization-ref`: `agenda-confirmation-receipt`
