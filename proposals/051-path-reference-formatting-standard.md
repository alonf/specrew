---
proposal: 051
title: Path Reference Formatting Standard (file:/// URL + markdown-link surface rules)
status: candidate
phase: phase-2
estimated-sp: 5
discussion: tbd
---

# Path Reference Formatting Standard

## Why

Squad continues to emit bare paths in handoff prose despite the file:/// URL rule established in F-012 and the validator rule shipped in F-013. Most recent observation 2026-05-18: a handoff sentence read "The initial spec is on disk at `specs/001-physics-simulation/spec.md`" instead of `file:///C:/Dev/Specrew/specs/001-physics-simulation/spec.md`. This is the same gap captured in memory 2026-05-16 ("Squad file:/// URL compliance gap") that proposal 004's hardening was supposed to close.

Two separate problems compound:

**Problem 1: Compliance gap is still real.** F-013 validator rules + Squad coordinator-prompt updates didn't cover all path-emission paths. Some prose sentences still bypass the rule. Result: the user keeps having to mentally translate bare paths to clickable URLs, defeating the purpose of the rule.

**Problem 2: The chosen format isn't optimal for agent UIs.** Raw file:/// URLs are long and visually noisy. Markdown-link format `[spec.md](file:///C:/Dev/Specrew/specs/001-physics-simulation/spec.md)` renders cleaner in agent UIs (Claude Code, Copilot CLI, Codex CLI all render markdown), keeps the link clickable, but shows just the filename. Where markdown is supported, it's strictly better UX.

But: not all surfaces support markdown rendering. Plain PowerShell terminal output (e.g., `specrew where` output piped to a console) shows literal `[name](url)` text — uglier than the bare URL. So a one-size-fits-all rule fails one of the two surfaces.

## What

A two-surface formatting standard plus the enforcement to make it stick.

### Surface taxonomy

| Surface | Format | Rendering behavior |
|---|---|---|
| **Agent-UI prose** (Squad's handoff narrative, coordinator output) | `[spec.md](file:///C:/Dev/Specrew/specs/001-physics-simulation/spec.md)` | Markdown-link rendered as clickable text |
| **Shell command output** (e.g., `specrew where`, validator output) | Full `file:///` URL bare | Terminal-clickable via OSC 8 (modern terminals); legible everywhere |
| **Markdown artifacts on disk** (specs, retros, dashboards, etc.) | `[spec.md](file:///...)` | Renders cleanly in any markdown renderer (GitHub, VS Code preview, etc.) |
| **Decision-ledger / state files (governance YAML/JSON)** | Bare `file:///` URL | Machine-parseable; preserved as-is by serializers |

### Four pillars

1. **Tighten coordinator-prompt rules** so Squad emits format-compliant references in EVERY prose path: handoff narratives, decision-ledger entries, retro lessons, etc. Today the rule says "use file:/// URLs" — the new rule says "use markdown-link format for agent-UI prose and decision-ledger summaries; bare file:/// URL for shell output and YAML/JSON state".

2. **Validator hardening (Gap #10)** — extend `validate-governance.ps1` to detect bare-path patterns in agent-UI prose surfaces (handoff narratives, decision-ledger entries, retro/review/closeout artifacts). Match patterns like `at specs/...`, `see ./scripts/...`, `the file at .specrew/...` followed by a non-URL path. Severity: WARN initially (grace period), FAIL after one iteration of feedback.

3. **Markdown-link as standard for prose** — update `.squad/agents/*/charter.md` and coordinator-prompt explicitly to teach the new format. Include examples of correct vs incorrect.

4. **Auto-conversion helper** — add `Convert-PathToMarkdownLink` helper that transforms `path/to/file.md` → `[file.md](file:///$resolvedPath/file.md)`. Squad can call this helper when emitting paths in prose. Cuts down on Squad needing to manually construct the markdown-link syntax.

### Per-surface examples

**Agent-UI prose (correct)**:
> The initial spec is on disk at [spec.md](file:///C:/Dev/Specrew/specs/001-physics-simulation/spec.md). I'm sending it through clarify next.

**Agent-UI prose (incorrect, today's bug)**:
> The initial spec is on disk at specs/001-physics-simulation/spec.md. I'm sending it through clarify next.

**Shell command output (correct)**:

```
Dashboard snapshot: file:///C:/Dev/Specrew/specs/020-session-state-durability/iterations/002/dashboard.md
```

**Markdown artifact on disk (correct)** — in a retro or closeout file:
> The iteration plan is at [plan.md](file:///C:/Dev/Specrew/specs/020/iterations/002/plan.md) and the drift log is at [drift-log.md](file:///C:/Dev/Specrew/specs/020/iterations/002/drift-log.md).

**Decision-ledger / state file (correct)** — YAML key:value:

```yaml
spec_path: file:///C:/Dev/Specrew/specs/001-physics-simulation/spec.md
```

## Effort

~5 SP, single iteration. Roughly:

- `Convert-PathToMarkdownLink` helper + tests (~1 SP)
- Coordinator-prompt + Squad charter updates (`.squad/agents/*/charter.md`, `.squad/coordinator-rules.md` or wherever the path-emission rule lives) (~1.5 SP)
- Validator rule additions: bare-path pattern detection for agent-UI prose surfaces (~1.5 SP)
- Integration tests confirming Squad emits the right format per surface (~0.5 SP)
- Documentation: brief update to docs/governance-guide or similar explaining the surface taxonomy (~0.5 SP)

## Phase placement

**Phase 2, fast follow-up to F-020.** Composes naturally with:

- **Proposal 004 (Validator Hardening)** — adds gap #10 (path-format compliance) as a new validator rule; this proposal effectively delivers part of 004's queued scope
- **Proposal 012 (Visual Artifact Extension)** — both about agent-UI rendering quality; complementary not overlapping
- **Proposal 032 (Slash-Command Surface)** — slash-command output is shell-surface, follows bare file:/// URL rule

Sequencing option: ship this between the 049+050 version-surface refresh and the 047 governance profile. Small chore-scale work that improves daily UX without blocking the larger features.

## Open questions

1. **Display text in markdown-links**: filename only (`[spec.md](...)`)? Last two path segments (`[020-session-state-durability/spec.md](...)`)? Full path (`[specs/020-session-state-durability/spec.md](...)`)? Recommend filename-only for brevity; reader hovers/clicks for full path.
2. **Cross-platform path handling**: `file:///C:/Dev/...` on Windows, `file:///home/alon/projects/specrew/...` on Linux. Both are valid file URIs. The helper should resolve relative paths to absolute file URIs using PowerShell's `Resolve-Path` then prefix with `file:///`.
3. **Anchor support**: do we need `[spec.md#FR-001](file:///...spec.md#FR-001)` for in-file references? Probably yes — markdown renderers support fragment anchors. Defer to v2 if too complex.
4. **Validator severity progression**: WARN immediately, FAIL after one feedback cycle. Or FAIL immediately and treat existing bare paths as soft-violations during grace period?
5. **Auto-fix mode**: should the validator offer to auto-convert bare paths in commits via a `--fix` flag? Probably yes; it's a mechanical transformation.
6. **Squad charter wording**: how to teach Squad the surface taxonomy concisely? "If you're writing prose for the human to read, use `[name](file:///url)` markdown links. If you're writing for a script, log file, or YAML state file, use the bare file:/// URL."
7. **Backward compatibility**: existing artifacts with bare paths — leave alone (historical) or run a one-time migration commit? Recommend leave alone; only enforce going forward.
8. **Performance**: regex-based bare-path detection in the validator must handle large files (e.g., specs with hundreds of path references). Mitigation: scope pattern detection to recently-changed lines.

## Risks

- **False positives in validator**: pattern detection might flag legitimate bare paths (e.g., a code block showing how to type a path). Mitigation: skip detection inside fenced code blocks and inline code spans.
- **Coordinator-prompt drift**: Squad's coordinator prompt is large and complex; adding more rules might dilute existing ones. Mitigation: keep the rule wording concise; add only one new sentence + one example pair.
- **Markdown rendering inconsistency across agent hosts**: some hosts might render markdown links slightly differently. Mitigation: test in Claude Code, Copilot CLI, Codex CLI; document any host-specific quirks.
- **OSC 8 hyperlink support in terminals**: not all terminals render bare URLs as clickable. Mitigation: bare URL is still readable plain text; OSC 8 is a nice-to-have for terminal contexts.

## Cross-references

- **Memory note 2026-05-16** ("Squad file:/// URL compliance gap") — original observation that motivated this proposal
- **Feedback memory** ("Use file:/// URL format for all file path references") — user's standing preference; this proposal refines it with surface-aware rules
- **Proposal 004 (Validator Hardening)** — adds gap #10 to its queued scope
- **Proposal 012 (Visual Artifact Extension)** — agent-UI rendering composition
- **Proposal 032 (Specrew Slash-Command Surface)** — shell-surface output follows the bare-URL rule
- **Proposal 014 (Red Team Agent)** — could include "path-format compliance" as one of its adversarial checks
- **F-013 (Validator Hardening)** — original shipping vehicle for path-format rules; this proposal closes residual gaps

## Status history

- 2026-05-16: maintainer captured memory note about Squad emitting bare paths in some handoffs; feeds into proposal 004 Validator Hardening
- 2026-05-18: gap re-observed two days later (Squad's clarify-stage handoff used "specs/001-physics-simulation/spec.md" bare). Proposal 004's F-013 shipping didn't fully close the gap. Maintainer also raised the markdown-link format question for agent-UI prose surfaces. Both concerns combined into this proposal, with a surface-aware taxonomy as the resolution.
