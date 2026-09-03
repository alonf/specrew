# v0.40.0-beta3 candidate walk

**Audience**: the maintainer. **Time**: 15–20 minutes. **Purpose**: verify the packaged delta on the exact
bits that will be tagged.

You are **checking** these bits, not exploring them. Every step states what you should see and what counts
as a failure. If a step fails, stop and report it rather than working around it.

---

## Before you start: one question

**Which agent CLI do you want to walk on — Claude, Codex, or Copilot?**

The delta is neutral across all three (four scripts plus a digest injected everywhere), so **one host is
sufficient at this size**. If you have a preference tied to the San Diego demo, this is a free opportunity
to exercise that host on the exact bits you will be presenting.

---

## What this walk covers, and why one walk is enough

The packaged delta is **six distinct files in four categories**:

| Category | Files |
| --- | --- |
| Comment rewrites (code-unchanged proof) | `shared-governance.ps1`, `workshop-authority-store.ps1`, `confirm-workshop-lens.ps1`, `specrew-conformance-provider.ps1` |
| Behavioural fix (three-direction proof) | `install-local-build.ps1` |
| Machine-read comment correction | `confirm-workshop-lens.ps1` *(second change)* |
| **Shipped content injected into every session, every host** | **`refocus/general.md`** |

Four of those are the scripts a workshop-and-boundary walk exercises. `general.md` is loaded at session
start. So one governed feature — workshop through a lens, then one boundary with a typed verdict — covers
all of it.

`install-local-build.ps1` needs no walk step of its own: contributor-only, unreachable from any lifecycle
path per the call graph, carries a three-direction proof, and **you exercise it incidentally in step 1**.

---

## Step 0 — PROVE YOU ARE RUNNING THE CANDIDATE (do not skip)

**A walk against the wrong bits proves nothing while looking like a pass.** Four checks in this session ran
without confirming their starting conditions, three of them after the rule was written down. This walk is a
check too, and it is the most expensive one to get wrong, because a tag would follow it.

**Do not use the version string** — it cannot distinguish two builds of `0.40.0`, and you hit exactly this
problem earlier when the version commands would not show you a hash. Use commit and content hash.

```powershell
# 1. What the candidate SHOULD be (run from the respin worktree, prints without installing):
pwsh -File scripts/internal/install-local-build.ps1 -WhatIfOnly
```

```powershell
# 2. What is ACTUALLY installed and loaded:
$m = Get-Module -ListAvailable -Name Specrew | Sort-Object Version -Descending | Select-Object -First 1
$s = Get-Content -LiteralPath (Join-Path $m.ModuleBase 'build-stamp.json') -Raw | ConvertFrom-Json
"installed : commit $($s.commit)  content $($s.content_sha256)"
"files     : $($s.content_file_count)   base: $($m.ModuleBase)"
```

**Proceed only when the `commit` and `content` values match between the two, and `content_file_count` is in
the low 400s.**

**FAILURE — stop here if:**

- the hashes differ → you are not running the candidate and the walk would be vacuous
- `content_file_count` is small (single digits or tens) → the install is not a real Specrew build

---

## Step 1 — Install the candidate

**Install from the candidate build directly. Do NOT use `specrew update`.** The standing rule against
updating walk projects holds; this is a fresh project taking the candidate build directly, and saying so
here rather than leaving it to habit is deliberate.

```powershell
cd C:\Temp\b3census          # the respin worktree, at the commit being tagged
pwsh -File scripts/internal/install-local-build.ps1
```

**Expect**: `packaged <N> files from <commit>`, `version 0.40.0 prerelease 'beta3'`,
`commit <sha> content <sha256>`, `target <module path>`, then an install confirmation.

**Then re-run Step 0's second command.** The installed stamp must now match the candidate.

**FAILURE**: any refusal, or a stamp that still does not match.

---

## Step 2 — Fresh project, governed feature

Use a directory that does not exist yet and is visually distinct from your other walk projects.

```powershell
mkdir C:\Temp\b3walk
cd C:\Temp\b3walk
git init
specrew init
```

**Expect**: init completes; `.specrew/`, `.specify/`, `.squad/` and the host skill directories are created.

**FAILURE**: init refuses, or reports missing dependencies you have installed.

---

## Step 3 - Launch the host, and READ THE FIRST LINE

Launch your chosen CLI in `C:\Temp\b3walk` (`claude`, `codex`, or `copilot`).

**Session start loads the refocus digest**, so the `[specrew-refocus]` line printed at the top of the
session is part of what you are checking. `general.md` changed in this delta - a redundant lede was removed
to bring it under its own token ceiling - and **that line is the evidence it still renders**.

**Expect**: a `[specrew-refocus] trigger=... scope=general ... tokens~...` line, followed by the
orientation showing Specrew is active, the lifecycle position, and where artifacts live. The core rules
should read coherently - the heading `Specrew refocus - always-true core` is now followed directly by the
governed-subject sentence.

**FAILURE**: no refocus line; a refocus line reporting zero sources; orientation missing; or the core rules
reading as though a sentence were cut mid-thought.

---

## Step 4 - Workshop, through at least one lens

State a feature request - anything substantive, e.g. *"a small CLI that converts CSV to JSON"*.

**Expect**: the design workshop opens with the **product & problem domain** lens before any spec, asks
questions as visible prose, and waits for your typed reply. Answer at least one lens and let it close.

**This is the main event.** It exercises `confirm-workshop-lens.ps1` (both comment changes, including the
authority-marker correction), `workshop-authority-store.ps1` (the transition table), and
`shared-governance.ps1` throughout.

**Expect on closing a lens**: an acknowledgment that the lens was recorded, and a durable artifact under
`specs/<feature>/workshop/`.

**FAILURE**: the workshop refuses to close a lens it should accept; a refusal naming a parameter you did
not supply; any message citing an internal `DRIFT-` identifier; or a lens closing with no artifact written.

---

## Step 5 - One boundary, with a typed verdict

Let the lifecycle reach its first boundary stop (specify).

**Expect**: the six-section re-entry packet as prose, four sendable response lines, and - invisible in the
rendering but present - the `SPECREW-VERDICT-BOUNDARY` marker as the last line.

Reply with the typed phrase exactly, as the **whole message**:

```text
approved for specify
```

**Expect**: the verdict is captured from your typed turn and the boundary advances.

**This exercises** `specrew-conformance-provider.ps1` (the stop/packet path) and the crossing machinery in
`shared-governance.ps1`.

**FAILURE**: the packet renders without the four response lines; the verdict is not captured and you are
asked again; the boundary advances without a captured verdict; or the packet offers a picker, a numbered
list, or a menu.

---

## What a pass looks like

All of: hashes matched at step 0, install clean, init clean, refocus line rendered, one lens closed with an
artifact, one boundary crossed on a typed verdict. **15-20 minutes, not a full lifecycle.**

Report the result and I will proceed to the tag. **No commit lands on `respin/beta3-census` after the walk**
- the next git operation on that branch is the tag itself, because any commit in between invalidates the
walk and it starts over.
