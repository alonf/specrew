# UI/UX Workshop Record

**Lens**: ui-ux · **Depth**: medium · **Confirmation**: human-confirmed
**Facilitated**: one decision at a time with the human (2026-06-08).

The "UI" is the agent-rendered SessionStart bootstrap. Classification logic was
decided in architecture-core; this lens decides what the user *sees*.

```text
=== SessionStart bootstrap (agent-rendered, visible PROSE) ===
[1] Orientation        Specrew version · host · project · lifecycle position
[2] Handover summary    only if validated: "Last session (<ts>): <msg> -> next: <step>"
                        if stale/invalid -> omit, or label "(historical, not current)"
[3] State line          "Welcome back" | "Full bootstrap" |
                        "Cleared a stale anchor to <feature>" |
                        warning: "prior session may have exited uncleanly"
[4] Menu (TEXT first)   Resume - <feature> at <boundary>  (only if a valid resume exists)
                        New    - start a new feature
                        Pick   - choose an existing feature
-----------------------------------------------------------------
[5] Structured picker   ONLY after [1]-[4] visibly rendered, and only where the picker
                        does not hide that text (F-165 discipline)
```

## Decision 1 - render sequence + render-first ENFORCEMENT

**Chosen: sequence option 1 (strict render-first, picker optional) + enforcement A.**

- Steps [1]-[4] always render as visible prose before any structured picker, carried
  as the directive `render_first` field.
- **Enforcement (the key finding):** a SessionStart hook injects directive *text*, which
  is advisory only - an agent under tool-gravity can still call `AskUserQuestion`, which
  on Claude collapses the prose into short header/option fields. That is the original
  F-165 bug and the same failure that collapsed this feature's own workshop. The hook
  does NOT mechanically prevent collapse.
- Therefore the bootstrap menu routes through a **`disallowed-tools: AskUserQuestion`
  skill** (gate-stop-style), so on Claude the picker is not in the toolset and prose +
  free-text choice is forced. This makes **FR-004 / SC-001 mechanically enforced**, not
  hoped-for.
- Rejected: B (revive the dormant PreToolUse render-gate hook - already superseded by
  the gate-stop skill, brittle to detect "render happened"); C (directive instruction
  only - the empirically weak status quo that fails on Claude).

## Decision 2 - per-host picker vs prose-only fallback

**Chosen: option 2 - prose-first floor + empirically-gated per-host picker opt-in.**

- Prose render of [1]-[4] is the guaranteed floor on **every** host (Claude, Codex,
  Copilot, Cursor) - the menu is always visible and answerable by free text.
- A structured picker is layered on **only** where FR-005 per-host testing proves it
  renders after/with the visible text without hiding it. This sets the policy; the
  actual per-host enable/disable is confirmed during implementation testing
  (FR-005 / SC-001).
- Rejected: option 1 (prose-only everywhere - abandons safe picker UX); option 3
  (picker-primary - highest collapse risk, cuts against the render-first decision).

## Decision 3 - surfacing the distinct bootstrap modes/warnings as states

**Chosen: option 2 - self-explaining states.**

- Always render a mode line ([3]): Welcome back / Full bootstrap / Cleared a stale
  anchor / Handover historical / Unclean prior exit / Partial-invalid input.
- Render a **one-line reason only when something non-default happened** (anchor cleared,
  handover ignored/historical, unclean prior exit, project-state mismatch), drawn from
  the directive `validation_findings`.
- Directly delivers the "make anchor clearing explicit/observable" + "explain why full
  bootstrap, not resume" obligations from architecture-core decision 3 and
  integration-api decision 3. Avoids the silent-failure confusion of the merged-Feature-171
  stale-recovery incident, without the noise of a full diagnostic dump every launch.
- The journal/log/test evidence for these same states is owned by the
  observability-resilience lens.
