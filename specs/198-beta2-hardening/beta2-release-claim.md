# Beta2 Release Claim — Narrowed

**Feature**: 198-beta2-hardening
**Status**: **APPROVED as the beta2 claim.** Wording approved 2026-07-30 with two edits (threat model
extended to checkout-borne links; applicability table qualified).

**Tag basis RE-CUT 2026-08-03, on the measured estimate.** The tag was previously gated on the whole
consumer-severe set (F11, F10, F17, F1). Surveying the implementation surfaces put that set at **~52 SP
against a 20 SP cap** — three iterations, not the two the plan assumed — with F10's requirement needing
a checkpoint-identity minting rule that does not exist and F17's needing two severity vocabularies
unified first. Rather than move the tag by two iterations, the maintainer re-cut what it gates on:

**beta2 gates on AUTHORIZATION-INTEGRITY only** — FR-066 (first-boundary arrival sync precedes the
first packet) and FR-068's evidence half (a verdict demand requires its stage's evidence to exist).
These are the defects where a human can be led to authorize an increment that does not exist, which is
the severest failure the governance model has. **The tag is cut after Iteration 011.**

**F10 and F17 move to beta3** and enter this document as named limitations 8 and 9, in the same honest
posture limitation 1 already takes. Iterations 012 and 013 of the five-iteration plan are formally
re-homed to beta3. The release gate and the maintainer's manual test follow Iteration 011.

**Limitation 1 stands at the tag** in its revised form — resolution contained, enumeration not — closed
by the beta3 containment consolidation. Iterations 009 and 010 remain at `reviewing` until then, per
the Iteration 003 precedent.
**Authored**: 2026-07-30, under the pre-decided fallback (maintainer decision 2026-07-29, item 7)
**Trigger**: the agreed termination rule fired. The final certifying round
`run-f198-i009-3d74f123-final` (digest `85bdfe01`) reported two new **major** findings of the
path-identity/containment class — DRIFT-198-I009-041 and -042 — one of them in a correction written
the same day. Per the rule, the campaign ends and the release claim narrows. There is no round nine.

## Why this document exists

Beta is the right vehicle for honesty about known limits. The alternative to narrowing was another
fix-and-review round, and the measured history of this surface argues against it: **eight rounds, with
every round after the third finding defects introduced by the round before it.** Continuing would have
bought more corrections of the same shape, not convergence.

This document states what the beta2 release **does** claim, what it **does not**, and what a consumer
should do about it.

## What beta2 DOES claim for cross-platform path identity

These are proven by runtime evidence, not by inspection:

- **One path-identity primitive, structurally enforced.** Exactly one definition of each path-identity
  function exists across the tree; no path comparison outside the primitive derives case semantics from
  the OS family; no path collection is deduplicated with a case-folding default. A same-named shadowing
  duplicate — the root cause of five non-converging rounds (DRIFT-198-I009-027) — cannot reappear
  silently.
- **Case semantics derived from the volume, not the OS family**, for real enumerated directory entries
  and for case-flipped lookups of them. Verified on three real volumes in CI: ext4 (case-sensitive),
  APFS (case-insensitive), NTFS (case-insensitive).
- **A differential harness whose oracle is the filesystem**, not authored expectation, and which is
  proven able to FAIL: a mutation gate runs it against deliberately-broken primitives and requires
  failures. Measured — an inverted-verdict mutant is caught on every volume; the historical OS-family
  mutant is caught on the one leg where the OS family disagrees with the volume (macOS), and the log
  records per leg whether the mutant was catchable there.
- **Ordinal dedup for path and file-identity collections** at every site the structural rules can see,
  in both the canonical packaged source and the deployed mirror.
- **A single containment choke point in the deployment path**, traversed by all five managed-file
  mutators and both recursive host-skill deletes, in both trees.
- **Reviewer-grant writes scoped to one field of one row** — recording an authorization for one host
  leaves every other row byte-identical, including a deliberately suspended row's policy text.
- **The certification lane honours Pester's terminal `Result`**, so a suite that dies in `BeforeAll` or
  `AfterAll` fails its leg instead of reporting a hollow green.

## What beta2 does NOT claim — known limitations

**1. Path containment in the review authority store is proven for path RESOLUTION, not for
ENUMERATION.** *Revised 2026-08-01 — narrowed, not removed.*

Iteration 010 hardened `Get-ReviewAuthorityStorePath`: a reparse point at the store root, or at any
existing campaign/run ancestor, is now rejected before the path is returned, and every caller that
builds a path from a known relative string routes through it. That half is delivered, regression-tested,
and mutation-gated.

What remains open: paths obtained by **enumeration** never go back through that function. Four sites
enumerate directory entries and read them directly — campaign grant/reservation/spend/release facts, run
results, human dispositions, and claim facts. A reparse-point CHILD beneath a clean parent is therefore
still followed, and out-of-store data with a schema-valid shape can enter signoff and allowance
decisions. One of the four compares the resolved path afterwards, but reads the entry first and compares
lexically — which is the same "lexical containment is not containment" mistake one level down.

The store holds grants, reservations, spend records, and review results — the evidence chain itself.
This is reachable by a **checkout-borne link** (see the threat model below): no local user action is
required, only a fetched branch. (DRIFT-198-I009-041, partially corrected; DRIFT-198-I010-004, open and
blocking.)

**2. ~~The volume case probe returns the wrong answer when a directory entry is a dangling link.~~
WITHDRAWN — not reproducible.** This limitation was published in draft on a reported finding whose
behavioural premise later failed measurement. The premise was that `Directory.Exists` and `File.Exists`
both report false for a dangling symbolic link. Measured on all three CI volumes — NTFS, APFS and ext4 —
`File.Exists` returns **true** for a broken symlink on POSIX as well as Windows, because .NET's
`FileStatus` completes an `lstat` and treats the link entry itself as an existing non-directory. Both
candidate constructions were swept, a dangling symlink and a symlink loop, with no gap on any volume.
The probe's `-or` therefore never takes the "absent" branch and the verdict is never inverted.
(DRIFT-198-I009-042, re-dispositioned NOT REPRODUCIBLE AS REPORTED; evidence in DRIFT-198-I010-002.)

The entry is struck rather than deleted deliberately: a limitation that was stated and then withdrawn
on measurement is part of the honest record of how this claim was built.

**3. The differential harness does not cover link states.** It contains zero symlink, dangling-link, or
reparse-point fixtures. The volume is a sound oracle for what it is asked; it was never asked about
links. Limitation 2 was believed to sit inside this blind spot; extending the fixtures is what
established that it is not a defect at all. The blind spot was real — the fixtures were genuinely
missing — but what they found on being written was the absence of the reported defect rather than its
presence. The same link class reaches the quality-profile resolver's feature binding: its containment
validation is lexical, so a directory link inside the project can still bind a foreign feature's
planning inputs (found by certification `run-f198-beta2-4e7d002c-certify`, 2026-08-09; routed to
beta3 with this link cluster — planning input, not authorization integrity).

**4. The consumer applicability firewall's case-distinct behaviour is unproven by test.** The scanner
now dedupes file identities ordinally, but no fixture runs it over two case-distinct files and asserts
both reach finding generation. (DRIFT-198-I009-043, recorded residual)

**5. Structural enforcement is textual, not syntactic.** The rules are grep-based. They have been
widened three times, each time after a real escape — an accepted spelling, too narrow a scan root, too
narrow a pattern. A sufficiently different spelling can still pass. AST-based enforcement via the
PowerShell parser is a scheduled replan task, not delivered here.

**6. A declared reviewer model is recorded, not enforced at invocation.** (DRIFT-198-I009-007)

**7. A human-observed defect that a fresh reviewer rediscovers cannot be recorded as deferred.** The
review gate's deferral vocabulary covers findings carried across rounds, not fresh discoveries, so an
accepted known defect cannot be expressed to the gate. (DRIFT-198-I009-034, now in **beta3** with the
governance-vocabulary cluster — Proposal 206.)

**8. The review round ceiling is charged per campaign, not per checkpoint — so a lifecycle that
produces findings at two or more checkpoints pays for all of them out of one budget.** *Added
2026-08-03 with the tag re-cut.*

This is the **F10 round-ceiling tax**, and it is a defect of FR-019's SCOPE rather than of its
implementation: the machinery charges exactly what the requirement told it to charge. FR-019 was
amended on 2026-08-02 so the allowance keys to lifecycle checkpoint identity, but **the amendment is
specification only — no implementation ships in beta2.** Measured surface: two independent allowance
systems plus a third dormant one, with the legacy ceiling held in a repo-global singleton keyed on
changed-path overlap, and no checkpoint-identity minting rule in existence.

Consumer effect: runs halt at the ceiling whether or not any individual checkpoint is converging. The
maintainer's own consumer manual test halted on every run. **Read limitation 8b with this one — the
escape route the halt message names does not work in the shipped mode.** (F10; FR-019 amended,
unimplemented; beta3.)

**8b. The ceiling-halt message, and the CLI help, name remediation commands that throw in the shipped
default mode.** *Added 2026-08-03; found while writing limitation 8.*

`review-authority-mode.json` ships `{"mode": "campaign"}` and is in the module FileList, so **every
consumer runs in campaign mode**. In that mode `specrew review` rejects every `--remediate` choice
except `override-block`. But the ceiling-halt text tells the consumer to *"run `specrew review
--remediate more-time`"*, and `--help` advertises all seven choices with no indication that six of
them fail. The documented escape from limitation 8 is nailed shut.

**The door that does work in campaign mode is a new explicitly authorized run** — a fresh
`--authorization-ref`, which mints a new grant with a slot. Re-using a previous reference yields the
same grant and no new slot, so the reference must be new. See the affected-users table.

**Confirmed as STANDING at the tag, 2026-08-03.** A message-only fix was scheduled inside Iteration
011 (T093) and was **deferred to beta3 when Iteration 011's T090 re-estimated upward at its start
gate** — the pre-agreed relief valve, which traded exactly these 1.5 SP rather than absorb an
overrun. That trade was the right one: T090 closes an authorization-integrity defect, and this one is
a wrong instruction with a working alternative documented below. It becomes **beta3's first item**,
ahead of FR-019, because it is limitation 8's consumer face.

**9. The finality/closeout check is not guaranteed to converge.** *Added 2026-08-03 with the tag
re-cut.*

This is **F17**. FR-067 was specified on 2026-08-02 — explicit severity threshold, residuals as a
first-class terminal outcome, no self-referential audit blocking — but **no implementation ships in
beta2.** Today there is no third terminal state between "clean" and "blocked": findings below the
blocking bar still route to a human turn rather than closing with recorded residuals. A closeout that
writes `state.md`, `plan.md` or `tasks.md` can re-arm the very check it is completing, because
FR-045's carry-forward allowlist covers only the six generated review artifacts and denies exactly
those files.

Two prerequisites are recorded so the beta3 work starts from measurement: the severity vocabulary is
not one vocabulary (`blocking|major|minor|note` in the authority core versus `blocking|advisory|nit`
in the reviewer, with the only rank map in a third file), and the digest strip list cannot be widened
as a shortcut because that file documents exclusion as a false-allow vector. (F17; FR-067 specified,
unimplemented; beta3.)

**10. At the design-analysis stop, the human decision is transcribed by the agent, not
hook-captured.** *Added 2026-08-09 at the tag, from the maintainer's known-issues review (B3-003).*

The design-analysis stop asks the human to choose an option BEFORE any boundary crossing exists to
bind the verdict to — the crossing cannot mint until the decision it authorizes exists. The verdict
is therefore agent-transcribed into the committed Human Decision record, with disclosure, rather
than captured by the verdict hook from the human's typed reply. Consumers should verify the
committed Human Decision text against what they actually chose before approving the plan boundary.
Beta3 vehicle: the crossing-vocabulary cluster (a decision-pending state or a design-option
crossing kind).

**11. After feature-closeout, the next feature's first boundary cannot mint its crossing.** *Added
2026-08-09 at the tag — promoted from the drift log to this claim.*

The crossing detector has exactly one reset edge (`iteration-closeout -> plan`). A project whose
cursor sits at `feature-closeout` has no edge into the NEXT feature's `specify`, so a SECOND
feature in the same project gets no first-boundary approval demand — the prompt simply never
appears. This feature's own ledger began cleanly only because the work ran in a fresh worktree.
Workaround: start the next feature from a fresh checkout/worktree, which re-initializes the
project's boundary ledger. Beta3 vehicle: the same crossing-vocabulary cluster (the feature-cycle
reset edge).

**12. Verdict capture refuses evidence-less crossings only when the evidence is CHECKED and
absent; unverifiable states keep legacy capture.** *Added 2026-08-09 at the tag, from
certification `run-f198-beta2-0fa26271-certify` under the maintainer's trajectory ruling.*

The capture-refusal hardening added pre-tag refuses authorization when a crossing's stage evidence
is checked against its bound tree and genuinely absent — everywhere. When the evidence CANNOT be
checked (no bound tree identity, unreadable tree, unresolvable feature path, or an evidence-check
error), capture retains its legacy behavior and a matching marker plus human approval still
records authorization. This is the capture-order class's third layer in one certification
lineage; per the trajectory ruling it moves to a **beta3 design owner** — authority advances only
on positively verified evidence, a capture-pipeline redesign rather than another guard — instead
of a fourth patch.

**13. Containment case comparison follows the platform default, not the volume.** *Added
2026-08-09 at the tag, from the same certification and ruling.*

The evidence gate's project containment refuses prefix siblings, traversal, and absolute escapes
on every platform. Its case comparison, however, is the platform default (case-insensitive on
Windows and macOS): on a volume whose case sensitivity disagrees with the platform default — a
case-sensitive NTFS directory, case-sensitive APFS — case-distinct sibling checkouts fold
together and a foreign sibling can be read as in-project. The containment class's third layer;
per the same ruling it moves to a **beta3 design owner** — all containment routes through the
release's volume-derived path-identity primitive — instead of a fourth patch.

## Who is affected, and what to do

| If you | Then |
| --- | --- |
| Run Specrew on a case-insensitive volume (default macOS, Windows) and have **verified** there are no reparse points in the project | Limitations 1 and 3 are not reachable in normal operation (2 is withdrawn). **Do not assume this — verify it**, and note that limitation 1's ENUMERATION half needs only a link at a leaf entry beneath an otherwise clean store, which is a lower bar than the root/ancestor half. Reparse points arrive benignly and without any user intent: OneDrive / Dropbox / iCloud cloud-placeholder files, Windows directory junctions, and toolchain link farms (`node_modules` stores, package-manager caches, build output links) all create them. See the detection commands below. |
| Have symlinks or junctions inside the project, especially under `.specrew/` | Limitations 1 and 2 are reachable. Prefer a project tree without reparse points beneath `.specrew/review/`, and do not place the authority store behind a link. |
| Run on a case-sensitive volume (typical Linux) | Limitation 1 is reachable. Limitation 2 is withdrawn on all volumes, not merely unreachable here. |
| Rely on the consumer applicability firewall for governance advisories | Limitation 4 applies: a case-distinct duplicate of a policy file may not be scanned. Avoid case-only filename distinctions in `docs/`, `specs/`, `.github/`. |
| Run a lifecycle that produces review findings at **two or more checkpoints** | Limitations 8 and 8b apply, and they compound. Your rounds are charged against one shared budget, so you will reach the ceiling sooner than the per-checkpoint arithmetic suggests — possibly on every run. **When you halt, do NOT follow the halt message's instruction to run `specrew review --remediate more-time`: that command throws in the shipped campaign mode.** The working escape is a **new explicitly authorized review run** — supply a fresh `--authorization-ref <ref>`, which mints a new grant with a review slot. The reference must be one you have not used before; re-using an earlier reference resolves to the same grant and grants no new slot. This is a human decision by design: the allowance guards real AI spend, and only a person may extend it. |
| Reach a closeout or finality check with findings outstanding | Limitation 9 applies. Findings below the blocking bar do not close the check on their own — they route to a human turn rather than terminating with recorded residuals. If the closeout writes `state.md`, `plan.md` or `tasks.md`, expect the check to re-arm on its own writes. Budget a human decision at closeout rather than expecting it to converge unattended. |
| Approve a design-analysis option | Limitation 10 applies: the committed Human Decision record is agent-transcribed with disclosure. Read it back and confirm it says what you actually chose before approving the plan boundary. |
| Start a SECOND feature in a project that closed its first | Limitation 11 applies: the first-boundary approval demand cannot mint in place. Start the new feature from a fresh checkout/worktree (fresh project state) so the boundary ledger initializes clean. |
| Approve a boundary while the project's state is degraded (missing or unreadable crossing records) | Limitation 12 applies: the evidence-absent refusal covers checked-and-absent states; an UNVERIFIABLE evidence state still captures your approval. Before approving, confirm the boundary packet cites a bound tree and that the stage's artifacts exist in it — an approval given while evidence "could not be checked" is an approval you could not have verified either. |
| Run governed projects on volumes whose case sensitivity disagrees with the platform default (case-sensitive NTFS directories, case-sensitive APFS) | Limitation 13 applies: case-distinct sibling checkouts can fold together in containment checks. Avoid case-distinct sibling directory names beside governed projects on such volumes. |

### Detecting reparse points in your project

"No symlinks" is not a safe default assumption — check it:

```text
# Symlinks recorded in the git index (mode 120000), any platform:
git ls-files -s | findstr 120000          # Windows
git ls-files -s | grep 120000             # POSIX

# Reparse points on disk, Windows — junctions and cloud placeholders included:
dir /AL /S

# POSIX, including links whose target does not exist (the DRIFT-198-I009-042 case):
find . -type l
find . -xtype l                           # dangling links specifically
```

The git-index check matters most for the checkout case below: it shows links that arrive with someone
else's commits rather than ones you created.

### Threat model

None of these are remote-attacker paths. Each requires a link inside the project tree, or a filename
that differs only by case — i.e. an actor who can write to the repository, **or whose commits are
checked out locally: git carries symlinks in tree objects, so checking out an untrusted branch, fork
PR, or template repo materializes attacker-authored links without the local user creating one. This
matters for Specrew specifically, which runs over branches under review.** They remain integrity and
correctness limits, not a remote compromise surface.

## What is deliberately NOT claimed

Beta2 does not claim that cross-platform path identity is fully hardened. It claims a single
primitive, volume-derived semantics for enumerated entries, a falsifiable three-volume harness, and the
specific containment and dedup corrections listed above — with the limitations named. That is a
narrower and truthful claim, and it is the claim the evidence supports.

## Provenance

- Convergence assessment and the full defect ledger:
  file:///C:/Dev/specrew-beta2-hardening/specs/198-beta2-hardening/iterations/009/drift-log.md
- Immutable review results (eight rounds):
  file:///C:/Dev/specrew-beta2-hardening/specs/198-beta2-hardening/iterations/009/evidence/
- Final round: `run-f198-i009-3d74f123-final`, digest `85bdfe01`, containment verified, validation
  valid, currentness current, completion complete, both controller verification commands green,
  `can_approve_current: false`.
- Beta2 tag certification: `run-f198-beta2-0fa26271-certify` (digest `4928a36f`), adjudicated
  2026-08-09 under the maintainer's trajectory ruling. **Measured tag-basis statement, correcting
  the pre-merge phrasing**: `git diff 0fa26271..67a5d7bc` (certified head → tag commit
  `v0.40.0-beta2`) is 15 files — the three documentation-only closure commits plus proposals,
  methodology documents, and the repository-governance record carried by `main`'s own reviewed
  history — **zero code files**; no engine, script, or test file differs between the certified
  head and the tag. The copy of this document pinned at the tag, and the release-notes Review
  Proof there, predate this correction.
