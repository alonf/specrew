# Design Analysis: 202-beta4-1-ux-stabilization, Iteration 001

**Feature**: 202-beta4-1-ux-stabilization
**Iteration**: 001 (Tier 1: B4F-108, 104, 106, 096, 107, 100, 102, 105, 109, 089, 101)
**Date**: 2026-10-13
**Status**: presented for co-design; awaiting the maintainer's agreement

## Problem framing

The Tier 1 findings share one shape: per-turn and per-feature state is either remembered nowhere (B4F-104 re-arms every turn; B4F-108's latch never clears) or taken from the wrong record (B4F-105, B4F-089, B4F-109 read a closed feature's state). On top of that, hosts diverge where the architecture says they must not (B4F-107, B4F-108 parity). The workshop bound the outcome: fixes live once in the shared path, and adapters do host mechanics only. This analysis maps that rule onto the code as it actually is, and settles the mechanism choices the workshop deferred here.

## What the code map found (read-only, 2026-10-13)

- **No per-host adapter scripts exist.** Host differences are a data block (`RefocusHookBindings`) in `hosts/<host>/host.psd1`: event registrations and output and stop-block shapes. The host kind is baked into the hook command at deploy time (`deploy-refocus-hooks.ps1` `Get-SpecrewHookCommand`).
- **Input normalization lives in the dispatcher core** (`specrew-hook-dispatcher.ps1` ~1160-1203, including Copilot-specific `ask_user` parsing). A **second, divergent normalizer**, `bootstrap/HostEventAdapter.ps1` `ConvertFrom-SpecrewHostHookEvent`, uses a different session-key list.
- **The dispatcher exists in two byte-identical copies** (`scripts/internal/` and `extensions/specrew-speckit/scripts/`), as do the bootstrap and handover providers, refocus and deploy-refocus-hooks.
- **B4F-108:** the journal is opened with `FileShare.Read` (dispatcher 115). Its catch writes `.unhealthy` (122), and the reader treats `.unhealthy` as "every reply is hook output" (store 409-430). The receipt writer has about 12 silent `return $null` exits. The "selection channel" text is the conformance provider's `workshop-repair` block (~1970), which infers a cause from a missing receipt.
- **B4F-104:** `$boundaryBlock = $hasPending -and -not $markerForPendingCrossing` (conformance 1426). The turn counter steps on every Stop, and nothing remembers that this crossing was already presented.
- **B4F-100:** `Test-SpecrewTurnMessageVisible` (turn-end-store 555-562) checks that the whole collapsed draft is contained in the reply.
- **B4F-106/107:** there are two dials renderers. One is prose (`user-profile.ps1` `Get-SpecrewProfileOrientationLine`); the other is numeric (`turn-end-store.ps1` `Get-SpecrewOrientationDialsLine`, which is what the Stop repair hands over). There are no host branches; the Codex/Claude difference is which renderer reached the agent (inferred, not traced live).
- **B4F-096:** the orientation receipt is written only on the compliant path. "Bootstrap delivered" checks any session's render file, not this session's.
- **B4F-102:** `Invoke-SpecrewDesignAnalysisPlanBoundaryGate` names the missing file, not its producer.
- **B4F-105:** status reads only `.specify/feature.json`, then falls back to the lowest-numbered spec directory. It ignores start-context. `create-governed-feature.ps1` never writes start-context.
- **B4F-109:** the cycle-reset rule is duplicated in `Get-SpecrewPendingBoundaryCrossing` and `Add-SpecrewBoundaryAuthorization`, and neither recognises `feature-closeout -> specify`. The coverage line picks the latest delivered run across **all** campaigns and matches the active campaign by iteration number only.
- **B4F-101:** `declare-turn-end.ps1` never sees a session id. It locates the session from `-Token` through `conformance-sessions/<sha256(host|session)>/turn-token.json`. Per-session folders already exist under `turn-end/<ownerHash>/`.

## Key Design Decision Points

Already bound by the workshop and carried as constraints: the placement rule; the existing layered hooks with no new method; quality priority (integrity, parity, diagnosability, friction, latency); journal concurrency with share mode first and a lock only if case (e) proves it necessary; the outage buffer; three-valued origin; the current-feature pointer with a branch guard; the per-session draft path resolved by the script; codex as reviewer.

Open points this analysis decides with the maintainer:

- **DA-1 Adapter seam.** Where host input normalization lives, given that no adapter scripts exist.
- **DA-2 Presentation memory.** How "presented once per session, again after a context gap" is remembered (B4F-104).
- **DA-3 Orientation ordering.** The mechanism FR-014 left to design-analysis (B4F-096).
- **DA-4 Draft path.** How the agent saves a draft without knowing its session (B4F-101).
- **DA-5 Feature identity.** One rule for which feature is current, used by status, resume, the cycle reset and the coverage line (B4F-105/109/089).

## Alternatives

The governing choice is DA-1, the adapter seam, because every other fix lands on the turn record it produces. Options A (Simplest), B (Reasonable) and C (By-the-book) are the DA-1 alternatives. In the co-design presentation they were listed as c, b and a respectively. DA-2 to DA-5 each had one recommended mechanism weighed against today's failing behavior, listed after the options.

### Option A - Simplest: leave normalization in the dispatcher (presented as DA-1 option c)

- **Approach**: no structural change; fix bugs in place.
- **Trade-offs**: keeps two divergent normalizers, Copilot-specific code inline, and no declared contract, so parity stays untestable. This is B4F-108's root pattern.
- **Effort**: about 1 SP. **Reversibility**: n/a.

### Option B - Reasonable: declarative bindings plus one shared normalizer (RECOMMENDED; presented as DA-1 option b)

- **Approach**: `host.psd1` declares the input field map and origin rules, and may name one transform from a small shared registry. One `ConvertTo-SpecrewTurnRecord` replaces both existing normalizers.
- **Trade-offs**: a host stays data, so Cursor and Antigravity remain cheap. The registry covers quirks that data cannot express. The contract is testable through the real launcher and dispatcher.
- **Effort**: about 2.5 SP. **Reversibility**: high.

### Option C - By-the-book: per-host adapter scripts (presented as DA-1 option a)

- **Approach**: one normalization script per host, called by the launcher.
- **Trade-offs**: an explicit per-host seam, but five scripts to maintain, with logic drifting into adapters and against the placement rule. A new host costs code.
- **Effort**: about 4 SP. **Reversibility**: medium.

### DA-2 to DA-5 (one recommended mechanism each, against today's behavior)

- **DA-2 Presentation memory.** Record "presented" per (session, crossing) and clear it on a context gap, rather than keying on the turn counter, which is today's failure.
- **DA-3 Orientation ordering.** Supply the finished orientation as system output on the first prompt, rather than demanding it at Stop after the reply, which is today's failure.
- **DA-4 Draft path.** The script takes the draft on stdin and resolves the per-session path from the token, rather than having the agent compute the path.
- **DA-5 Feature identity.** One resolver plus `feature_ref` on new ledger entries, rather than per-reader rules (today's B4F-105/109 spread).

## Crew Recommendation

Option B for DA-1, and the recommended mechanism for each of DA-2 to DA-5. Option B is the only DA-1 choice that satisfies the workshop's placement rule (adapters do mechanics only) and gives the B4F-108 cross-host test a declared contract to run through. It also keeps the experimental hosts at the cost of a data row.

## Co-Design Record

Human-agreed: yes

**Co-design agreed by the maintainer, 2026-10-13, Claude session:** component map approved as drawn, with no renames, splits, merges or reassignments. All five DA points were answered in one typed reply ending with `move on`, three of them with amendments, recorded verbatim in substance below. The tuning values and the dispatcher/provider parity test are agreed as plan items.

### Agreed component map

```text
 HOST BINDINGS (data, per host)         hosts/<host>/host.psd1  RefocusHookBindings
   claude | codex | copilot | cursor* | antigravity*      (* = experimental tier)
        |  event names, output/stop shapes, + INPUT FIELD MAP + named TRANSFORM + ORIGIN RULES (DA-1)
        v
 LAUNCHER            ~/.specrew/specrew-hook-launch.ps1  (stdin once, find project)
        v
 DISPATCHER          specrew-hook-dispatcher.ps1  (x2 identical copies: internal + extensions)
   ConvertTo-SpecrewTurnRecord  -> {event, typed text, host, origin, session}   (DA-1)
     uses the shared transform registry for host quirks (e.g. Copilot replay / skipped question)
   Write-DispatcherHookOutputAuthorityRecord  share-mode append, retry, outage buffer, health
        |
        +--> PROVIDERS   bootstrap(20) | handover(30) | conformance(40) | refocus | navigator
        |      conformance: presented-crossing memory (DA-2), substance-only checks,
        |                   meaning-line set (B4F-100), system-filled deterministic lines (DA-3)
        |      handover:    receipt writer, disclosed refusals (B4F-108)
        v
 STORES              workshop-authority-store | turn-end-store (+ per-session draft, DA-4)
                     hook-output journal | health journal | start-context ledger (+ feature_ref)
        v
 READERS             status/where dashboard | orientation/resume | gate refusals
                     all read ONE feature resolver (DA-5)
```

### Component responsibilities (every component, named)

- **Host bindings**
  - `host.psd1` (claude, codex, copilot validated; cursor, antigravity experimental). Declares event registrations, output and stop-block shapes, the input field map, origin-detection rules (data), and optionally the name of one transform from the shared registry. No logic.
- **Launcher**
  - `specrew-hook-launch.ps1`. Reads stdin once, resolves the project, invokes the dispatcher with the deployed binding. Unchanged.
- **Dispatcher**
  - `ConvertTo-SpecrewTurnRecord` (new). The only normalizer, replacing the dispatcher inline parsing and `HostEventAdapter.ps1` `ConvertFrom-SpecrewHostHookEvent`. It applies the binding's field map, named transform and origin rules, and produces the standard turn record.
  - **Shared transform registry** (new, small). Named, tested transforms for host quirks that field maps cannot express (Copilot replayed directives, `User skipped question`).
  - `Write-DispatcherHookOutputAuthorityRecord`. Appends with a share mode that permits concurrent appends; bounded retry (at most 5 attempts within 250 ms) as a backup; outage buffer; health transitions. No permanent latch; a legacy `.unhealthy` marker is treated as an ordinary degraded state.
- **Providers**
  - `conformance`. Stop decisions only on substance. Presented-crossing memory (DA-2). The declared meaning-line set (B4F-100). System-filled deterministic lines, marked and journaled (B4F-106).
  - `handover`. Receipt minting. Every refusal is disclosed in the same turn with its actual cause and consumed status. The "selection channel" inference is removed (B4F-108 defect 3).
  - `bootstrap`. Supplies the finished orientation as system output on the session's first prompt (DA-3), using the single prose dials renderer (B4F-107).
  - `refocus` and `navigator`. Unchanged.
- **Stores**
  - `workshop-authority-store`. Integrity check over the journal plus the outage buffer; no latch.
  - `turn-end-store`. Per-session turn records, presented-crossing memory, and the per-session draft at `turn-end/<ownerHash>/turn-message.md` (DA-4). The numeric dials renderer is removed.
  - `hook-output journal` and `health journal`. Hashes, event names and timestamps only.
  - `start-context`. The pointer records its branch; new ledger entries and crossings carry `feature_ref`; the cycle-reset rule lives in one shared function. Legacy entries are never rewritten.
- **Readers**
  - `Resolve-SpecrewActiveFeatureRef`. The single feature resolver for status, orientation, resume, the cycle reset and the coverage line, applying the DA-5 precedence.
  - `design-analysis-gate`. Its refusal names the producing step (B4F-102).

### Agreed decisions (maintainer amendments in bold)

1. **DA-1: option b, with an escape hatch.** Hosts declare input field maps in `host.psd1`. **A host binding may name a transform from a small shared registry, because field maps alone cannot express the Copilot-specific parsing already in the dispatcher (replayed directives, "User skipped question"). Origin-detection rules are data too.** Hosts stay declarative. The cross-host test runs through the real launcher and dispatcher with each deployed binding.
2. **DA-2: agreed, with one change.** "Presented" is recorded per (session, crossing id). **A moved HEAD is NOT a context gap:** the agent's own mid-session bookkeeping commits (drift entries, findings) caused this session's repaints. Context gaps are exactly:
   - a changed crossing id;
   - a change to the artifacts under review;
   - SessionStart new/resume/compact;
   - the long gap (8 hours).
3. **DA-3: agreed.** The orientation is supplied as system output on the session's first prompt. **On hosts that show hook output directly, the agent must not also render the orientation; there are no duplicates.** Which validated hosts display hook output directly is measured in a scratch-directory plan task.
4. **DA-4: agreed.** `declare-turn-end.ps1` accepts the draft on stdin and stores it at the per-session path; the agent passes only `-Token`. **Draft intake over stdin needs explicit UTF-8 handling on every OS, with a test using non-ASCII text, Hebrew included; stdin and argv encoding have bitten Specrew before (B4F-065).** If a validated host supplies no session id, its draft path is per-token, and this is reported at plan.
5. **DA-5: agreed, with one correction: the branch is not the feature.** This worktree ran feature 199 on branch `201-first-run-experience`. The resolver decides in this order, and always discloses which source decided:
   1. the in-flight controller or pending crossing;
   2. the pointer, if it was written for the current branch;
   3. the branch name, as a hint only.

   New ledger entries and crossings carry `feature_ref`. The cycle reset is one shared function. The coverage line filters by `feature_ref`. `create-governed-feature.ps1` writes the pointer. Legacy entries are never rewritten.

### Agreed flows

**Flow: typed workshop reply, healthy and degraded (B4F-108)**

```mermaid
sequenceDiagram
  participant H as Host (codex)
  participant L as Launcher
  participant D as Dispatcher
  participant S as Handover receipt writer
  participant J as Journal + outage buffer
  H->>L: user-prompt event (stdin)
  L->>D: event + deployed binding
  D->>D: ConvertTo-SpecrewTurnRecord (field map, origin rules) -> origin typed-user
  D->>S: turn record
  S->>J: integrity check (journal + buffer)
  J-->>S: no hook-output match
  S-->>H: receipt minted; checkpoint closes
  Note over D,J: journal locked -> retry <=5 in 250 ms -> buffer -> degraded disclosed same turn -> clears on next good append
```

**Typed workshop reply on Codex (B4F-108), healthy:**

```text
host event -> launcher -> ConvertTo-SpecrewTurnRecord (codex binding: field map + origin rules)
  -> origin typed-user -> handover receipt writer
  -> integrity check: journal + outage buffer, no match -> receipt minted -> checkpoint closes
```

**Same reply while the journal is locked:**

```text
hook output append -> fails -> bounded retry (<=5 in 250 ms)
  -> still failing -> hashes to per-process outage buffer -> health journal: degraded
  -> same turn: "Specrew couldn't record your reply safely ..." + whether the turn was consumed
  -> next successful append -> buffer flushed and removed -> health: recovered -> next reply mints
```

**Unchanged pending crossing (B4F-104, DA-2):**

```text
packet presented once -> presented(session, crossing) recorded
  -> later turn: no context gap -> reply answers; at most one-line mention; no Stop block
  -> context gap (crossing id / reviewed artifacts changed, SessionStart new/resume/compact, 8 h)
       -> memory cleared -> packet owed once again
```

## Spec reconciliation from this co-design

DA-5's correction changes FR-018 ("reconcile from the branch and the in-flight work") to the agreed precedence. The spec is reconciled in the same commit as this record. Drift entry: iterations/001/drift-log.md, DRIFT-001.

## Human Decision

**Chosen Option**: Option B (DA-1: declarative bindings plus one shared normalizer), with the recommended mechanisms for DA-2 to DA-5.
**Given**: 2026-10-13, by the maintainer, in one typed reply at the design-analysis co-design, ending with `move on`. The component map was agreed as drawn.
**Human reason, modifications and instructions (verbatim in substance)**:

- DA-1: "option b, with an escape hatch". A host binding may name a transform from a small shared registry, and origin-detection rules are data too.
- DA-2: "a moved HEAD is NOT a context gap". Only a changed crossing id or reviewed artifacts, SessionStart new/resume/compact, and the long gap count.
- DA-3: no duplicate orientation on hosts that show hook output directly.
- DA-4: explicit UTF-8 for stdin on every OS, with a non-ASCII (Hebrew) test (B4F-065).
- DA-5: "the branch is not the feature". Precedence: in-flight controller or crossing, then the pointer for this branch, then the branch as a hint, always disclosed.
- Plan items: the dispatcher/provider parity test; tuning values of 5 attempts in 250 ms and an 8-hour long gap.

**Decision commit**: `b3c622fc` (the commit that first recorded this Co-Design Record).
**Transcription disclosure**: this decision is agent-transcribed from the maintainer's typed co-design reply in the governing session. It records the design choice only. The plan itself is approved, or not, at the plan boundary with its own typed verdict.
