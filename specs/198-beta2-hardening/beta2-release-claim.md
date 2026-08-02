# Beta2 Release Claim — Narrowed

**Feature**: 198-beta2-hardening
**Status**: proposed wording, awaiting the maintainer's verdict
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
presence.

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
accepted known defect cannot be expressed to the gate. (DRIFT-198-I009-034, in iteration 012 scope)

## Who is affected, and what to do

| If you | Then |
| --- | --- |
| Run Specrew on a case-insensitive volume (default macOS, Windows) and have **verified** there are no reparse points in the project | Limitations 1 and 3 are not reachable in normal operation (2 is withdrawn). **Do not assume this — verify it**, and note that limitation 1's ENUMERATION half needs only a link at a leaf entry beneath an otherwise clean store, which is a lower bar than the root/ancestor half. Reparse points arrive benignly and without any user intent: OneDrive / Dropbox / iCloud cloud-placeholder files, Windows directory junctions, and toolchain link farms (`node_modules` stores, package-manager caches, build output links) all create them. See the detection commands below. |
| Have symlinks or junctions inside the project, especially under `.specrew/` | Limitations 1 and 2 are reachable. Prefer a project tree without reparse points beneath `.specrew/review/`, and do not place the authority store behind a link. |
| Run on a case-sensitive volume (typical Linux) | Limitation 1 is reachable. Limitation 2 is withdrawn on all volumes, not merely unreachable here. |
| Rely on the consumer applicability firewall for governance advisories | Limitation 4 applies: a case-distinct duplicate of a policy file may not be scanned. Avoid case-only filename distinctions in `docs/`, `specs/`, `.github/`. |

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
