---
proposal: 147
title: --host-options Host-Native Flag Passthrough (CLI + Per-Project Config Layer Above Proposal 069 Flag Mapping)
status: candidate
phase: phase-2
estimated-sp: 5-8
priority-tier: 1
discussion: surfaced 2026-05-30 during F-050 Cursor smoke-test discussion; extends Proposal 069 shipped F-040 flag-translation layer with arbitrary host-native passthrough Specrew doesn't model
---

# `--host-options` Host-Native Flag Passthrough (CLI + Per-Project Config Layer Above Proposal 069 Flag Mapping)

## Why

Each host CLI (cursor-agent, claude, codex, copilot, antigravity) exposes a rich flag surface — model selection, working dir, verbosity, auth, config paths, output formats. Specrew currently passes through ZERO of these unless they happen to map to a Specrew-defined flag from Proposal 069 (`--allow-all`, `--autopilot`, `--remote`).

**Empirical motivator:** F-050 Cursor Host Package surfaces cursor-agent's rich flag set — `--model`, `--print`, `--trust`, `--workspace`, `--allow-all`, plus auth and config flags. None of them are reachable via `specrew start --host cursor` today. User asks "can I pass `--model X` to cursor-agent?" — answer is "no, modify Specrew first" — wrong answer.

**Examples of host flags users want to pass:**

- `cursor-agent --model claude-4-7-opus` — pick a model for the session
- `claude --continue` — resume a previous Claude Code session
- `codex --temperature 0.2` — Codex sampling control
- `claude --system "extra system instructions"` — augment system prompt
- `cursor-agent --verbose` — debug a launch issue

These are not Specrew-model concerns; they're host-CLI concerns the user should be able to drive directly.

### Proposal 069 didn't cover this

[Proposal 069](069-multi-host-launch-path.md) (shipped F-040, v0.26.0) defined the Specrew flag-translation layer: Specrew-DEFINED flags (`--allow-all`, `--autopilot`, `--remote`) map to per-host equivalents through `ConvertTo-<Host>Flag` contract functions. That layer is necessary and correct. But it only covers flags Specrew models. Arbitrary host-native flags Specrew doesn't model have no passthrough surface today.

This proposal adds a SECOND layer above 069: arbitrary passthrough Specrew doesn't validate or interpret.

## What

### Option A: CLI flag (one-off)

```text
specrew start --host cursor --host-options "--model claude-4-7-opus --verbose"
specrew start --host claude --host-options "--continue --model haiku"
specrew start --host codex --host-options "--temperature 0.2"
```

Verbatim passthrough string. Tokenized at invocation time (respecting quoted values). User owns the string content; Specrew does NOT validate flag names against the host CLI — flags are host-specific by definition; user consults the host's own `--help`.

### Option B: Per-project config (persistent)

```yaml
# .specrew/host-cursor.yml
extra_args:
  - "--model"
  - "claude-4-7-opus"
  - "--verbose"
```

Loaded by the relevant host adapter at launch time. Per-developer (gitignored) by default — see Risks section.

### Resolution order

When launching `specrew start --host <kind>`:

1. **Specrew-owned positional args** (prompt + `--workspace` or per-host equivalent) — fixed by the host adapter contract
2. **Specrew-defined flag translations from Proposal 069** (e.g., `--allow-all` → `--force` for cursor) — owned by Specrew
3. **`.specrew/host-<kind>.yml` `extra_args`** (persistent passthrough)
4. **`--host-options "..."` tokens** (CLI passthrough; CLI wins on duplicates with config)
5. **Conflict detection:** if user-passed flag duplicates a Specrew-owned position, warn + strip user flag

### Conflict policy

Default behavior: **warn-and-strip.** Surface the conflict to the user with a clear message; preserve Specrew's launch-contract integrity.

Alternatives considered:

- **Hard-error:** rejected — user may not know which flags Specrew owns; warning is more usable
- **Silent-override:** rejected — risks silently breaking the launch contract

Implementation: each host adapter optionally provides `Get-<Kind>ConflictingFlags` (a new 6th contract function — opt-in). Hosts that don't define it get permissive passthrough (no conflict detection). Hosts opt in as failure modes emerge empirically.

### Per-host applicability — user's responsibility

A flag valid for `cursor-agent` is gibberish for `codex` CLI. Specrew does NOT validate flag names or syntax against the host CLI. Documentation says: `--host-options` is host-specific by definition; consult the host's own `--help` for what's available.

## Architecture (deliverable shape)

- **CLI parser:** `scripts/specrew-start.ps1` accepts `--host-options "<string>"` argument
- **Tokenization:** respects quoted values (`--system "hello world"` correctly preserves the quoted string)
- **Per-project config loader:** reads `.specrew/host-<kind>.yml` `extra_args` array if present
- **Host adapter contract extension:** new optional 6th function per host: `Get-<Kind>ConflictingFlags` returning the set of Specrew-owned flag names. Used for warn-and-strip detection. Opt-in per host.
- **Default behavior on missing `Get-<Kind>ConflictingFlags`:** no conflict detection (passthrough is permissive). Hosts opt in as they mature.
- **Output:** launch-time log line surfacing the resolved final argv for transparency
- **Docs:** README + user-guide entry with per-host examples
- **Tests:** all 5 hosts, conflict scenarios, missing config, malformed `--host-options`

## Composition map

- [Proposal 069](069-multi-host-launch-path.md) (Multi-Host Launch Path + Per-Host Flag Pass-Through, SHIPPED F-040/v0.26.0) — 147 extends 069's flag-translation contract with arbitrary passthrough; 069's `ConvertTo-<Host>Flag` remains responsible for Specrew-defined flag mapping
- [Proposal 114](114-cursor-host-package.md) (Cursor Host Package, F-050 in-flight) — empirical motivator; cursor-agent has the richest flag surface among current hosts
- **Proposal 058** (Plugin-Based Distribution, candidate) — per-host packaging could carry per-host conflict-flag declarations
- [Proposal 067](067-small-fix-slice-type.md) (Small-Fix Slice Type) — natural slice shape for 147
- [Proposal 146](146-specrew-refocus-slash-command.md) (Refocus Slash Command, draft) — sibling parallel-slice candidate
- [Proposal 138](138-spec-kit-underutilized-surfaces.md) (Spec Kit Underutilized Surfaces, candidate) — sibling parallel-slice candidate

## Sizing + sequencing

**Size: ~5-8 SP, single-iteration small-fix slice**

| Work | SP estimate |
| ---- | ----------- |
| CLI parser + tokenization | ~1-2 SP |
| Per-host config loader (`.specrew/host-<kind>.yml`) | ~1 SP |
| Host adapter contract extension (`Get-<Kind>ConflictingFlags` 6th function, opt-in) | ~1-2 SP |
| Conflict detection + warn-and-strip logic | ~1 SP |
| Tests (all 5 hosts, conflict scenarios, missing config, malformed input) | ~1-2 SP |
| Docs (README + user-guide) | ~0.5 SP |

**Sequencing:**

No dependency on F-051/F-052/F-053. Slot as a **parallel small-fix slice** alongside Proposals 146 / 138 / 011 in the F-051 parallel bundle (per the post-F-049 actual sequencing). Bundle now includes:

- 146 — `/specrew.refocus` (5-8 SP)
- 138 — Spec Kit Underutilized Surfaces (8-15 SP)
- 011 — Architecture Intent Checkpoint (10 SP, optional)
- **147 — `--host-options` passthrough (5-8 SP)**

Alternative: fold 147 into F-050 feature-closeout if you want it in v0.29.0 alongside Cursor. Small enough to bundle; provides immediate value for the Cursor host's rich flag surface.

## Open questions

- **Tokenization edge cases:** quoted strings with embedded spaces (`--system "hello world"`) need correct parsing. PowerShell `[CommandLineToArgs]` is one option; explicit regex tokenizer is another. Decide at spec time.
- **Logging the resolved argv:** verbosity level? Always show, or only with `--verbose` Specrew flag?
- **Config file format:** YAML (matches other `.specrew/` files) or simpler line-delimited?
- **Antigravity / Codex / Copilot specifics:** these hosts have different flag surfaces; some accept config files of their own (Codex `.openai.json` etc.); does Specrew passthrough compose well? Audit per host at spec time.
- **Cursor `.cursor/rules/*.mdc` interaction:** Cursor's rules surface is auto-attached, not invocable. `--host-options` to cursor-agent doesn't affect rule attachment. Doc note.
- **Telemetry:** should Specrew record what host-options users pass? Privacy + opt-in considerations.

## Risks

- **User passes contradictory flags:** e.g., `--host-options "--print"` on cursor while Specrew expects interactive launch. Warn-and-strip catches this case if `--print` is in `Get-CursorConflictingFlags`; if not, passthrough proceeds and Cursor may behave unexpectedly. Mitigation: populate conflict lists per host as failure modes emerge empirically.
- **Per-host config drift across machines:** `.specrew/host-<kind>.yml` checked into git or per-developer? If shared, one dev's `--model` preference applies to all. If per-developer, gitignore + documentation. **Per-developer (gitignored) is the safer default**; document the choice explicitly.
- **Tokenization mismatch between OS shells:** PowerShell quoting vs bash quoting vs Windows cmd quoting. Test matrix per host's actual CLI invocation surface.
- **Flag-name collision after Specrew adds new owned flags:** if Specrew later adds `--workspace` as a Specrew-defined flag for some new feature, existing user `--host-options "--workspace X"` configs break. Mitigation: never reuse owned-flag names; document the Specrew-owned namespace explicitly; treat it like a stable API.
- **Documentation drift between host CLI versions:** cursor-agent v2026.05.28 may have different flags than v2026.06.XX. Specrew doesn't track host CLI versions for flag validity. Mitigation: user consults host's own `--help`; Specrew docs link to upstream host docs.
