# Lens: code-implementation (light)

**Feature**: 202-beta4-1-ux-stabilization
**Confirmation**: human-confirmed / lens-question, closed with a typed `move on` on Claude, 2026-10-13. Receipt `a455ece50497961c03f61516fe3a2059c471c7ce495381385c26fae373c52be5`.
**Question**: which craft rules bind implement for 202, and which host reviews the code.
**Manifest**: `specs/202-beta4-1-ux-stabilization/implementation-rules.yml` (stack `powershell-markdown-yaml-json`, `feature_standalone`).

## Design time to implement time

```
 design time (this lens)                         implement time
 ------------------------------------------      -------------------------------------------
 199 manifest (46 rules, 4 off; 8 custom)       specs/202/implementation-rules.yml
   inherited as baseline ----------------+       |
 202 amendments (decisions 1-4 below) ---+-----> +--> specrew-code-rules skill: rules shown per
 dependency stance: none new ------------+       |    task while the agent writes code
 reviewer host + authorization ----------+       '--> continuous co-review on codex
```

## Decisions

1. **Source of rules: inherit 199's manifest, with one amendment.** There is no external guideline. The 46 catalog selections and the carried custom rules are inherited and rescoped to `feature-202`. **Amendment:** the "sync with remote main before implement" rule does not fit 202. The feature branches from `24e5701a`, and main does not carry beta4. For 202 the sync base is the beta4 line, `origin/201-first-run-experience`, until the maintainer decides the main merge separately. Custom rule: `feature-202.rule.beta4-line-sync`.
2. **Concurrency rule: scoped exception (agreed).** The hook-output journal write path permits concurrent appends through a compatible share mode first. A per-write cross-process lock on that journal only is allowed when fault-injection case (e) proves that the share mode alone can interleave or tear lines. No generic lock framework is added. The outage buffer stays on unique per-process files. This amends `code-rule.concurrency-over-locks`.
3. **Consumer language: keep the rule, fix the example wording (amended).** The banned-noun check stays. Recovery wording must never imply data loss when nothing is lost. The reference wording, given by the maintainer, is: "Specrew couldn't record your reply safely. May I clear the stuck error so it can record again? Nothing is deleted." It is asserted by message-content tests. Custom rule: `feature-202.rule.recovery-wording-no-implied-loss`. The ui-ux phrase "may I move this marker aside?" remains intent only, never shipped text.
4. **Test posture (agreed).** 199's posture applies, plus the following:
   - The B4F-108 cross-host test runs through each host's real adapter with recorded real payloads, which are captured in scratch directories only.
   - Fault-injection cases a-e, with case (e) on Windows, macOS and Linux.
   - The lens-6 pointer-writer test.
   - Error handling: an expected journal failure becomes a disclosed degraded state, never a thrown error that consumes the turn. Only an integrity contradiction fails closed. The journal append retry is a bounded backup only.
5. **Dependencies (agreed).** None are new: existing PowerShell, .NET file APIs and Pester.
6. **Reviewer: codex (human-selected).** It was authorized with `specrew review --host codex --authorization-ref workshop-202-beta4-1-ux-stabilization`, which succeeded and wrote `.specrew/reviewer-hosts.json`. **Known quirk, not a failure:** codex writes its findings to `.review/findings.jsonl` with empty stdout. The engine may retry and label the run partial while still harvesting the findings.

## Bindings

- `code-rules-source`: `inherit-199-manifest`
- `implement-sync-base`: `beta4-line-origin-201-first-run-experience`
- `journal-concurrency`: `concurrent-appends-permitted` (unchanged from observability-resilience)
- `journal-lock-exception`: `per-write-lock-only-if-case-e-proves-share-mode-insufficient`
- `recovery-wording`: `project-terms-no-implied-loss`
- `new-dependencies`: `none`
- `reviewer-host`: `codex`
- `b4f108-fault-injection`: `required` (unchanged)
