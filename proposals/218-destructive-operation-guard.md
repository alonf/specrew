---
proposal: 218
title: Destructive-Operation Guard - Worktree Removal, Real-Home Writes and Lifecycle-State Backup
status: candidate
phase: phase-2
estimated-sp: 26-40
priority-tier: 1
discussion: maintainer conversation 2026-11-08 during Feature 203 (beta5 stabilization), after the crew force-removed its own session worktree - "I wonder how such a thing can happen?"; on where the guard belongs - "is it my home settings, or is it a service that Specrew provides? There is a good cause for Specrew to provide it since we do delete worktrees due to our review process"; and "you can write the proposal, create a PR and accept it".
---

# Destructive-Operation Guard - Worktree Removal, Real-Home Writes and Lifecycle-State Backup

## Why

Specrew creates and deletes git worktrees as part of its own process: review rounds check out a snapshot of
the reviewed tree, the live-engine pin is a detached worktree outside the project, and the crew's sweeps and
lanes run in temporary checkouts. Specrew also writes outside the project: `specrew init` and `specrew update`
deploy user-level hook files and a per-machine launcher into the home folder of every hook-capable host. Both
are destructive operations on state the human did not hand to the agent. Today the safety of each one rests on
a convention, a careful habit or the right test driver, and nothing checks it at the moment of the act.

### Empirical motivation (Feature 203, iteration 001, 2026-11-02 to 2026-11-08)

In seven days one feature hit the same shape four times: a check existed somewhere, the operation that needed
it ran without it, and the human found out afterwards.

- **The session worktree was deleted by a pattern match (DRIFT-049, B5F-035; 2026-11-08 00:21 local).**
  Clearing a stopped sweep checkout, the crew ran
  `git worktree list | Select-String '06fb5a00' | ForEach-Object { ... git worktree remove --force $p }`. The
  session's own worktree was at the same commit, so it matched too, and `--force` deleted it. The tracked work
  survived only because the tree was clean and the branch ref lived in the main checkout. The git-ignored
  lifecycle state did not: the start context and verdict history, the pin record, the review campaign and
  authority stores (13 review rounds of launches, results, dispositions and sign-offs), the spend ledger, the
  set of typed turns that had already minted an approval (`exhausted-turns.jsonl`), and the journals. The disk
  is an NVMe SSD with TRIM and there were no shadow copies, so nothing could be undeleted. Two files came back
  only because a second agent session happened to hold copies in its transcript; the rest is lost for good,
  and the loss of `exhausted-turns.jsonl` means a hook that re-reads the transcript could mint an already-spent
  approval again.
- **Review verification runs rewrote the real user-level hooks (DRIFT-021; 2026-11-02).** Round 5's
  verification left the Codex, Copilot and Cursor hooks pointing at a launcher written by an unreviewed review
  copy, naming that deleted copy as the module path. The maintainer's standing instruction is that these files
  are not changed without asking.
- **A test suite rewrote them again (DRIFT-044, B5F-032; 2026-11-07 05:46).** A suite ran the real
  `specrew-init.ps1` with no home override. About 25 suites run init or update without one; the home is
  redirected only by `-UserHomeOverride` or `SPECREW_USER_HOME_OVERRIDE`, because `GetFolderPath` ignores
  `USERPROFILE`.
- **And again, through the wrong driver (DRIFT-050; 2026-11-08 03:28).** After the worktree loss the crew
  wrote a new sweep driver instead of using the one that sets the home override for every suite. Three real
  hook files were rewritten to point at a launcher built from unreviewed code; which suite wrote them was never
  established, because nothing records who writes the real home.

### Why Specrew, not the human's own settings

A guard in one maintainer's home settings protects one machine and one host. The operations are Specrew's:
its review engine removes snapshots with `git worktree remove --force` on a path read from a record
(`scripts/internal/continuous-co-review/review-target-port.ps1`, three call sites), the pin script does the
same (`scripts/internal/live-engine-pin.ps1`, Create's rollback and Remove), and its deployer writes the home.
None of these checks that the path is not the caller's own folder or a governed project. Specrew also teaches
its crews to create and clear checkouts, so the agents that copy those habits are Specrew's agents. The guard
belongs with the operations.

## What - Four Pillars

### Pillar 1 - One guarded worktree removal in the engine

- A single helper (working name `Remove-SpecrewWorktree`) is the only way engine code removes a worktree. It
  takes one exact path and refuses when:
  - the path is not listed by `git worktree list --porcelain` for that repository, or is the main worktree;
  - the path is, or contains, the caller's working directory, the project root, or the folder of any running
    Specrew session that recorded itself (its session marker);
  - the worktree holds governed lifecycle state (`.specrew/start-context.json`) and was not created by Specrew
    as disposable.
- Specrew records each worktree it creates as disposable (review snapshot, pin, sweep or lane checkout) in a
  user-level ledger outside every worktree, with the creating command and time. `--force` is used only for a
  recorded disposable worktree; anything else is removed without `--force`, so git refuses when the tree holds
  changes.
- The three `review-target-port.ps1` call sites, the pin script's two, and the worktree reviewer's
  `Remove-Item -Recurse` fallbacks move onto the helper.
- A guard test fails the build on any new `git worktree remove` or recursive delete of a worktree path in
  engine code outside the helper.

### Pillar 2 - A real-home write fence

- **One place, not per suite (B5F-032's class fix).** A deploy whose project root is under the temp folder, or
  that runs under a test harness, never writes the real home. It writes a redirected home, or refuses, unless
  the caller passes an explicit real-home flag. Tests that need the real-home path prove it against a sentinel
  home.
- **Every real-home write is journaled.** The deployer records, for each file it writes outside the project,
  the path, the hash before and after, the command and the project that triggered it, in a user-level journal.
  A rewrite like DRIFT-050's then names its writer instead of leaving it "not established".
- **A sweep check Specrew ships.** The regression runner snapshots the protected home surfaces before a run and
  fails the run when any byte changed. Today that check lives in one crew's scratch driver, and a new driver
  skipped it.
- The protected surfaces are the same list Proposal 217 names for the companion: host hook and settings files
  (`~/.claude/settings*.json`, `~/.codex/hooks.json`, `~/.copilot/hooks/`, `~/.cursor/hooks.json` and the other
  hosts' equivalents), the per-machine launchers and bindings under `~/.specrew/`, and user profiles.

### Pillar 3 - A pre-tool guard Specrew deploys to the agent host

Pillars 1 and 2 cover Specrew's own code. The DRIFT-049 command was typed by an agent, not run by the engine,
so a second layer sits in front of the agent's shell:

- Specrew deploys a deterministic pre-tool hook (no model call) on every host that exposes one; on Claude Code
  this is a `PreToolUse` hook matched to the shell tools, which blocks by exit code 2 and shows its reason to
  the agent. It blocks:
  - a `git worktree remove` whose targets come from a listing, a pattern match or a loop rather than
    written-out paths;
  - a removal, or a recursive delete, whose target is, or contains, the session's own folder, the project root,
    or a `.specrew/` state folder;
  - an agent edit of a protected home surface (Pillar 2's list) that does not go through Specrew's deployer.
- The block message says what was refused and why, and that the human can run the command themselves if they
  want it. The guard never offers its own override; the human's `!` command, or their own terminal, is the
  override.
- Cost: the hook runs on shell calls only and exits at once when the command holds none of its keywords. A
  measured prototype starts in about 0.07 s under node and 0.27 s under pwsh, on a call that already starts a
  shell. A 12-case prototype (the DRIFT-049 command, an `xargs` loop, the session folder written four ways, a
  parent folder, and exact-path, variable, sibling-prefix and unrelated commands that must pass) was built and
  was built during the 203 investigation and passes.
- The guard is deployed by init and update like the other hooks, and is subject to Pillar 2's journal. On
  hosts that also execute Claude Code's hook files (Copilot CLI does), it is deployed once, not doubled.

### Pillar 4 - Lifecycle-state backup outside the worktree

Git-ignored lifecycle state is, by design, not in git, so a deleted worktree takes it with it. The state that
cannot be regenerated is backed up where a worktree removal cannot reach it:

- **What:** `.specrew/start-context.json`, `.specrew/last-start-prompt.md`, `.specify/feature.json`, the
  review campaign and authority stores, the spend ledger, `.specrew/authority/` (exhausted turns and
  withdrawals), the live-engine pin record and bindings, and the verdict journals.
- **When:** at every boundary crossing and boundary sync, at each review round's launch and sign-off, and at
  session start; copies with unchanged content are not repeated.
- **Where:** a per-project folder under the user-level Specrew folder, keyed by the project's identity, not its
  path, with bounded retention.
- **Restore** is a governed command that lists the snapshots and restores one on the human's explicit choice.
  A restore may only take authority away, never add it: sets of spent or exhausted approvals are merged as a
  union with what is on disk; an approval that was unspent in the snapshot is not restored; verdict history is
  restored only up to the last crossing the committed tree confirms. The restore reports what it restored and
  what it refused.

### Functional requirements (candidate level)

1. Every engine worktree removal goes through one helper with the Pillar 1 refusals; a guard test fails on any
   other removal path.
2. A deploy for a temp-folder project or under a test harness never writes the real home unless explicitly
   told to.
3. Every real-home write by Specrew is journaled with path, before and after hashes, command and project.
4. The regression runner fails a run that changes a protected home surface.
5. Specrew deploys a deterministic pre-tool guard on every host that exposes a pre-tool hook, blocking
   generated worktree-removal targets, removals of the session or project folder, and agent edits of protected
   home surfaces.
6. Irreplaceable lifecycle state is backed up outside the worktree at boundaries, review launches and
   sign-offs, and session start.
7. Restore is human-chosen and can only reduce authority.

### Out of scope

- General sandboxing of the agent's file system. Reviewer confinement is Proposal 203's (reviewer containment, a different item from Feature 203); this proposal guards
  named destructive operations on Specrew-owned and protected state, not every `rm`.
- Killing processes. The DRIFT-049 command also stopped every process whose command line matched the hash;
  stopping processes stays a human decision under Proposal 217's never-delegable list, and is not given a
  separate guard here.
- Backing up tracked work. Git and the remote cover it; this proposal backs up only git-ignored state.
- Undeleting files. On SSDs with TRIM it is not possible, which is why Pillar 4 copies ahead of time.

## Effort

- **Slice A - engine safety (~8-12 SP):** Pillar 1 (helper, ledger, call-site moves, guard test) and Pillar 2
  (temp-folder fence, real-home journal, runner check). Closes B5F-035 and B5F-032's class fix.
- **Slice B - host pre-tool guard (~8-13 SP):** Pillar 3 on Claude Code first, then each host with a pre-tool
  hook surface; deployed by init and update; doubling check for Copilot.
- **Slice C - state backup and restore (~10-15 SP):** Pillar 4, with the authority-only-shrinks restore rules
  and their tests.
- **Total:** ~26-40 SP.

## Phase placement

Phase 2 (convention enforcement and state durability), next to Proposal 035. Slice A is the urgent part: its
two findings, B5F-035 and B5F-032, are already open in Feature 203, and every further 203 sweep and review
round runs the unguarded code. The recommended placement is Slice A inside 203's iteration 002, decided by the
maintainer at that iteration's plan boundary, with Slices B and C as their own feature after 203 merges.
Slice B deploys through init and update, so it is sequenced with the init and bootstrap feature that is
required before 0.40.0 stable rather than run beside it on the same files.

## Open questions

1. Does Slice A go into 203's iteration 002, or wait for its own feature? It closes two open 203 findings but
   adds scope to a stabilization feature.
2. Which hosts besides Claude Code expose a pre-tool hook that can block a shell call, and with what exit
   contract? Hosts without one get Pillars 1, 2 and 4 only; is that stated in the host capability matrix?
3. Is the guard on by default for consumer projects, or for Specrew's own repository first? Consumers delete
   worktrees too, but a false block in a consumer project costs more trust than one in Specrew's.
4. Retention for Pillar 4: a count of snapshots, an age, or one per boundary kept for the feature's life?
5. Should the real-home journal also record writes by host CLIs Specrew starts (for example a reviewer CLI
   updating its own config), or only Specrew's deployer?

## Risks

- **False blocks.** A pattern guard can refuse a legitimate command (for example a script that lists
  worktrees for display and removes one by a written path in the same line). Mitigation: the prototype passes
  exact-path, variable and sibling-prefix cases; the block names the rule and leaves the human's own command as
  the way through; false blocks are counted in the friction measure from the beta4 UX ruling.
- **A guard that can be routed around.** A deterministic text check cannot see through every indirection (a
  script file, an alias, a base64 command). It is a seatbelt for the observed failure shapes, not a sandbox;
  Pillars 1 and 4 still hold when it is bypassed.
- **Backup that revives authority.** Restoring an old authority store could bring back an approval that was
  already spent. Mitigation: Pillar 4's restore can only shrink authority, with tests for each store.
- **Hook cost and doubling.** Each shell call pays a process start. Mitigation: keyword pre-check and fast exit;
  one deployment per host, with the Copilot doubling case tested.

## Cross-references

- Related proposals: 035 (session-state durability; Pillar 4 adds the off-worktree copy that 035 does not
  have), Proposal 203 (reviewer containment, not Feature 203; file-system confinement of the reviewer is there, not here), 205 (self-leak
  firewall; the real-home fence is the same idea for the home folder), 217 (companion reviewer; shares the
  protected home-surface list and the never-delegable stop of crew processes).
- Source artifacts: Feature 203 iteration 001 drift log, DRIFT-021, DRIFT-044, DRIFT-045, DRIFT-049 and
  DRIFT-050; `docs/beta5-findings.md` B5F-032 and B5F-035.
- Composability with: the live-engine pin (Feature 203 T002), the continuous co-review engine (Feature 197), and
  the init and update deployers.

## Status history

- 2026-11-08: created as candidate. Written after the DRIFT-049 worktree loss and the DRIFT-050 real-home
  rewrite on the same night, on the maintainer's ruling that Specrew, not the maintainer's home settings,
  should provide the guard because Specrew's own review process creates and deletes worktrees.
