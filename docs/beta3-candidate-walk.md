# v0.40.0-beta3 candidate walk

**Audience**: the maintainer. **Time**: 15–20 minutes. **Purpose**: verify the packaged delta on the exact
bits that will be tagged.

You are **checking** these bits, not exploring them. Every step states what you should see and what counts
as a failure. If a step fails, stop and report it rather than working around it.

---

## PRECONDITION - where the walk runs

**The walk runs the agent in a FRESH, EMPTY directory. Never in C:\Temp\b3census.**

That worktree is not a neutral place to stand: it is itself a governed Specrew project, with its own
lifecycle state, its own feature history, and the candidate's own source tree in it. Launching the agent
there does three things wrong at once:

- **it creates a real feature in the candidate tree** - the first walk did exactly this, scaffolding
  `specs/201-csv-to-json/` and switching the worktree onto a new branch;
- **it pollutes the census subject**, because the validator suites copy the repository including `specs/`;
- **it does not exercise what the walk is for.** The clean session-start path - a project with no history,
  reaching its first boundary for the first time - is the thing being checked, and an established project
  cannot show it to you.

`C:\Temp\b3census` is used for exactly two commands, both of which package or install the module and neither of
which launches an agent: Step 0's `-WhatIfOnly` and Step 1's install. **From Step 2 onward you are in
`C:\Temp\b3walk` and you do not go back.**

Stating this at the top rather than inside a step is deliberate: it is a precondition like any other, and
the rule this project runs on is that a control states the conditions it requires.

---

## Before you start: one question

**Which agent CLI do you want to walk on — Claude, Codex, or Copilot?**

The delta is neutral across all three (four scripts plus a digest injected everywhere), so **one host is
sufficient at this size**. If you have a preference tied to the San Diego demo, this is a free opportunity
to exercise that host on the exact bits you will be presenting.

---

## What this walk covers, and why one walk is enough

The packaged delta is **14 changes across 8 files**, and the two numbers are stated separately because
they answer different questions. Measured, not remembered: the FileList in `Specrew.psd1` was intersected
with `git diff --name-only 4f4dce52..7f8aa1e9`. **37 files changed in total; 29 of them are tests, harness
and records that do not ship.** One file carries six of the fourteen changes, so a single figure would
misdescribe whichever question you were asking.

The fourteen, enumerated so the count is checkable rather than asserted:

| # | file | change |
| --- | --- | --- |
| 1 | `refocus/general.md` | the redundant lede removed, to fit its own token ceiling |
| 2 | `confirm-workshop-lens.ps1` | comment rewrite |
| 3 | `confirm-workshop-lens.ps1` | malformed authority marker corrected |
| 4 | `shared-governance.ps1` | comment rewrites |
| 5 | `workshop-authority-store.ps1` | comment rewrite |
| 6 | `specrew-conformance-provider.ps1` | comment rewrite |
| 7 | `specrew-conformance-provider.ps1` | the scaffold-stub exemption, which had never once fired |
| 8 | `specrew-conformance-provider.ps1` | the workshop light form |
| 9 | `specrew-conformance-provider.ps1` | the feature spec no longer watched during a workshop |
| 10 | `specrew-conformance-provider.ps1` | the light form discharges its own obligation |
| 11 | `specrew-conformance-provider.ps1` | the pathless note removed |
| 12 | `create-governed-feature.ps1` | the scaffold reports whether it created a branch |
| 13 | `install-local-build.ps1` | `-WhatIfOnly` no longer requires an installed module |
| 14 | `templates/coordinator-instructions.md` | the machinery is invoked, never read |

Their categories:

| Category | Files |
| --- | --- |
| Comment rewrites (code-unchanged proof) | `shared-governance.ps1`, `workshop-authority-store.ps1`, `confirm-workshop-lens.ps1` |
| Behavioural fix (both directions proven) | `specrew-conformance-provider.ps1` *(also a comment rewrite; the inertness proof no longer covers it)* |
| Behavioural fix (three-direction proof) | `install-local-build.ps1` |
| Behavioural fix (four outcomes guarded) | `create-governed-feature.ps1` *(the scaffold now reports whether it made a branch)* |
| Machine-read comment correction | `confirm-workshop-lens.ps1` *(second change)* |
| **Shipped content injected into every session, every host** | **`refocus/general.md`** |
| **The first thing an agent reads in a new project** | **`templates/coordinator-instructions.md`** |

Four of those are the scripts a workshop-and-boundary walk exercises. `general.md` is loaded at session
start. So one governed feature - workshop through a lens, then one boundary with a typed verdict - covers
all of it.

## THIS IS THE FIFTH WALK. FOUR HAVE ENDED BEFORE A BOUNDARY. REACHING ONE IS THE WHOLE JOB.

**Read this before anything else.** Four walks have run on this delta and **not one has crossed a
boundary with a typed verdict** - the single behaviour the release most needs proven. Each stopped
somewhere earlier and each found something real, so the walks have been worth running. But the thing they
were for is still unverified.

| walk | how far it got | what it found |
| --- | --- | --- |
| 1 | stopped on turn one | a packet interrupting the workshop's first question |
| 2 | never left the scaffold | a branch reported but never created |
| 3 | reached the workshop | a packet interrupting mid-lens |
| 4 | reached the workshop | the same note repeated on every turn |
| **5 (this one)** | **must reach Step 5** | |

**Steps 0 to 4 are setup. They are not the walk.** A run that installs cleanly, initialises cleanly, opens
a lens and then stops has not verified this release - it is a fourth walk that ended before the point.

**If something goes wrong before Step 5, note it and keep going.** Nothing before the boundary is worth
abandoning the walk for unless it physically blocks you. Write it down and continue.

**Three things to watch for, in this order:**

| # | Watch for | Where | New in this candidate |
| --- | --- | --- | --- |
| 1 | the agent reaches its first question **without opening any Specrew source** | Step 4 | yes |
| 2 | the scaffold **states plainly whether it created a branch** | Step 4 | yes |
| 3 | outside work is mentioned in **one sentence, mid-conversation**, with no packet and no re-ask | Step 4 | yes |
| 4 | **THE BOUNDARY ADVANCES WHEN YOU TYPE YOUR VERDICT** | **Step 5** | **the one still unproven** |

The first three are fixes the previous four walks paid for. **The fourth is the one that decides whether
this release is verified.**

`install-local-build.ps1` needs no walk step of its own: contributor-only, unreachable from any lifecycle
path per the call graph, carries a three-direction proof, and **you exercise it incidentally in step 1**.

---

## Step 0 - WRITE DOWN WHAT THE CANDIDATE IS (do not skip)

**A walk against the wrong bits proves nothing while looking like a pass.** Four checks in this session ran
without confirming their starting conditions, three of them after the rule was written down. This walk is a
check too, and it is the most expensive one to get wrong, because a tag would follow it.

**Do not use the version string** - it cannot distinguish two builds of `0.40.0`, and you hit exactly this
problem earlier when the version commands would not show you a hash. Use commit and content hash.

This step does not compare anything yet. It records the two values you will compare **after** you install,
because right now there is deliberately nothing to match: the installed module was destroyed by a broken
control earlier in this work, and Step 1 is what replaces it.

```powershell
# Run from the respin worktree. Prints what WOULD be installed; installs nothing.
cd C:\Temp\b3census
pwsh -File scripts/internal/install-local-build.ps1 -WhatIfOnly
```

**Expect** a line of the form `commit <sha> content <sha256>`, a file count of 414, and
`WhatIfOnly: nothing was installed.` **Write the commit and content values down.** They are the walk's
subject.

**IGNORE THE `installed` COLUMN IN THE TABLE THIS PRINTS. It says `False` and that is not an answer about
your machine.** The field records whether *this invocation* installed anything, so under `-WhatIfOnly` it is
hard-coded `False` and can never say anything else. It is not a check of whether the candidate is present,
and reading it as one here is the natural mistake, because this step is about exactly that question.

The same applies to `install_root`: it shows where an install *would* go, not what is there now.

**Where the real answer comes from** is the stamp inside the installed module, which Step 1 reads. Nothing
in this step's output can tell you what is installed.

**FAILURE - stop here if**: the command refuses, or reports a file count in the single digits or tens, which
would mean the source tree is not a real Specrew build.

---

## Step 1 - Put the candidate ENGINE on this machine (no project involved)

**No, this step does not need `specrew init`.** That question is the right one to ask and the step did not
answer it, so here is the distinction the whole walk rests on:

| | what it is | what it touches |
| --- | --- | --- |
| **Step 1** (this step) | the **Specrew module** - the engine itself | your PowerShell modules directory, machine-wide. **No project.** |
| **Step 2** (next step) | a **throwaway project** to exercise the engine on | a new folder, `C:\Temp\b3walk`, where `specrew init` runs |

You are installing a tool now, and pointing it at a subject later. `specrew init` cannot run in this step
because there is no project yet; that is what Step 2 creates.

**This is also why `specrew update` is the wrong command here.** `specrew update` refreshes the copy of the
machinery deployed *inside a project*. It is not how the module gets onto the machine, and the standing rule
against running it on a walk project still holds.

```powershell
pwsh -File scripts/internal/install-local-build.ps1
```

**You can skip the install if the check below already shows the candidate.** It was run when the candidate
was built, so the module on this machine should already be the right one. Running it again is safe and
idempotent; it does a clean replace and preserves PowerShellGet's provenance file and the version-check
cache.

**Expect**: `packaged <N> files from <commit>`, `version 0.40.0 prerelease 'beta3'`,
`commit <sha> content <sha256>`, `target <module path>`, then an install confirmation.

**Now the comparison Step 0 set up.** This is the gate:

```powershell
$m = Get-Module -ListAvailable -Name Specrew | Sort-Object Version -Descending | Select-Object -First 1
$s = Get-Content -LiteralPath (Join-Path $m.ModuleBase 'build-stamp.json') -Raw | ConvertFrom-Json
"installed : commit $($s.commit)  content $($s.content_sha256)"
"files     : $($s.content_file_count)   base: $($m.ModuleBase)"
```

**Proceed only when `commit` and `content` match the values you wrote down in Step 0.**

**Three different file counts are correct here, and they are meant to differ.** Expect exactly:

| number | what it counts |
| --- | --- |
| **413** | `content_file_count` - every staged file except `build-stamp.json`, which cannot contain its own hash |
| **414** | what the installer reports as `packaged` - the 413 plus the stamp |
| **416** | files in the install root - the 414 plus two the installer deliberately preserves across a clean replace: PowerShellGet's `PSGetModuleInfo.xml` and the module's `.specrew\version-check-cache.json` |

**FAILURE - stop here if:**

- the hashes differ from Step 0 - you are not running the candidate and the rest of the walk would be vacuous
- `content_file_count` is small (single digits or tens) - the install did not replace the broken remnant

---

## Step 2 — Fresh project, governed feature

Use a directory that does not exist yet and is visually distinct from your other walk projects. **This is the second pass, so if `C:\Temp\b3walk` is left over from an earlier attempt, delete it first** - a project with history cannot show you the clean session-start path this walk is checking.

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

**WATCH 1 - the agent reaches its first question without reading source.** The previous walk spent over
three minutes opening `create-governed-feature.ps1` and `create-new-feature.ps1` before asking anything,
because the instructions named those paths and never said they are not for reading. That clause is now in
the shipped template. **You should see the orientation and then the first question. Any stretch of file
reads before the first question means the clause did not land.**

**WATCH 3 - outside work is mentioned in one sentence, not a packet.** If the agent touches something
outside the workshop notes - the specification placeholder is the usual one - it should say so in **a
single sentence inside its normal reply**, name the specification as not yet agreed, and **carry straight
on with the open question**. **A five-part packet here, or the question re-asked as a separate block, is
the defect this candidate fixes.** The previous walk hit exactly that mid-lens.

**WATCH 2 - the scaffold says whether it made a branch.** Look for a `BRANCH:` line alongside `BRANCH_NAME:`
in the feature-creation output. **It should say the branch was not created and why**, and say that nothing
failed - this project will stay on `master`, which is correct and expected. A bare `BRANCH_NAME:` with no
`BRANCH:` line means the reporting fix did not reach you.

**FAILURE**: the workshop refuses to close a lens it should accept; a refusal naming a parameter you did
not supply; any message citing an internal `DRIFT-` identifier; a lens closing with no artifact written; or
**a five-part re-entry packet before you have answered anything** - that is the defect the previous rebuild
fixed, and seeing it again means it did not take.

**Do not stop here for a cosmetic problem.** Note it and continue to Step 5, which is the step that has
never been reached.

---

## Step 5 - One boundary, with a typed verdict (THIS IS THE STEP THAT MATTERS)

**No walk on this delta has reached this step. Four have tried.** Everything above exists to get you
here, and if you have arrived with unresolved notes from earlier steps, that is fine - finish this step
first and report the notes afterwards.

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

**WATCH 3 - the boundary advances on your typed verdict.** This is the behaviour the delta most needs
proven and the one two walks have missed. The packet should render as prose with four sendable response
lines, you type the phrase as your whole message, and the boundary moves.

**FAILURE**: the packet renders without the four response lines; the verdict is not captured and you are
asked again; the boundary advances without a captured verdict; or the packet offers a picker, a numbered
list, or a menu.

---

## What a pass looks like

All of: hashes matched at step 0, install clean, init clean, refocus line rendered, one lens closed with an
artifact, one boundary crossed on a typed verdict. **15-20 minutes, not a full lifecycle.**

**The last item is the one that decides it.** A walk that does everything else and does not cross a
boundary is not a pass - it is a third walk that stopped before the point.

Report the result and I will proceed to the tag. **No commit lands on `respin/beta3-census` after the
walk.** The next git operation on that branch is the tag itself, because any commit in between invalidates
the walk and it starts over.
