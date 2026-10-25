# Lens: data-storage (light)

**Feature**: 202-beta4-1-ux-stabilization
**Confirmation**: human-confirmed / lens-question, closed with a typed `move on` on Claude, 2026-10-13. Receipt `d1fb1fd201d91c20ab707a455fa5ed8f691f28f7f2ff94c760775eb2e5ff5b37`.
**Question**: which record is authoritative for "current feature", where the resume narrative comes from, and where the turn draft lives (B4F-105, B4F-089, B4F-101).

## Records that described "current work" when the lens opened

```
 record                                   says                                  written by
 ---------------------------------------  ------------------------------------  ---------------------------
 git branch                               202-beta4-1-ux-stabilization          governed feature creator
 specs/202/lens-applicability.json        202 workshop in progress (5/7 lenses) workshop controller
 .specrew/start-context.json              199 at feature-closeout, inactive     boundary sync (stale: not
                                                                                updated on feature create)
 .specify/feature.json                    feature_directory: ""                 (empty)
 .specrew/handover/session-handover.md    199 narrative ("resume 199 ...")      Stop hook / agent author
 specrew status                           001-specrew-product, Shipped          dashboard default (B4F-105)
 ---------------------------------------  ------------------------------------  ---------------------------
 => four different answers
```

## Agreed read path

```
 status / orientation / resume
          |
          v
 .specrew/start-context.json  { active feature, last authorized boundary, pending, BRANCH written for }
          |
          |-- pointer.branch == current branch --> use pointer
          |
          '-- pointer.branch != current branch (branch switch, or a writer forgot)
                 --> treat as STALE
                 --> reconcile from the branch + the in-flight controller
                 --> disclose: which record won and why
                 --> ask the human ONLY when two in-flight features really compete

 resume "where we are / starting now"  <-- disk only: pending crossing, from_commit..HEAD, progress
 handover narrative                    <-- context only, shown with its age; flagged when older than
                                           the ledger or naming a different feature
```

## Decisions

1. **One stored pointer, guarded by branch (option a, amended).** `start-context.json` stays the single authority for the current feature, as CLAUDE.md already says. Every writer that creates or advances a feature keeps it current: the governed feature creator, the boundary syncs, and the workshop controller when a workshop starts. **Guard:** the file is not tracked in git and is per-worktree, so it goes stale on a branch switch as well as when a writer forgets. The pointer records the branch it was written for. When the current branch differs, readers treat the pointer as stale, reconcile from the branch and the in-flight controller, and disclose the reconciliation. A Shipped or closed feature is never shown as active while an in-flight one exists. The human is asked only when two in-flight features really compete. **Test:** every writer that creates or advances a feature updates the pointer.
2. **Resume narrative from disk (B4F-089, agreed).** The "where we are / starting now" lines come only from disk: the pending crossing, the commits from the handover's `from_commit` to HEAD, and workshop or iteration progress. The agent-written handover narrative is context only. It is shown with its age, and it is flagged rather than repeated when it is older than the ledger or names a different feature. A resume is a context gap, so the packet is sized to the gap.
3. **Per-session turn draft (B4F-101, option b, conditional).** The draft lives at `.specrew/runtime/turn-end/<session>/turn-message.md`, is ignored like the rest of the runtime folder, and is defaulted by the script. **Condition:** the agent never needs to know its session id or the hashed folder name. The draft-saving script resolves the per-session path itself. If a host cannot support that reliably, the problem is raised at design-analysis. It does not become a new run-time stop.

## Bindings

- `current-feature-authority`: `start-context-single-pointer`
- `pointer-branch-guard`: `stale-on-branch-mismatch-reconcile-disclose`
- `pointer-writer-test`: `every-feature-writer-updates-pointer`
- `resume-narrative-source`: `disk-only-handover-as-aged-context`
- `turn-draft-location`: `per-session-script-resolved`
- `turn-draft-session-resolution`: `script-owned-never-agent`
