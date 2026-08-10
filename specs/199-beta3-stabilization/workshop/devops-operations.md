# DevOps-Operations Lens Record: 199-beta3-stabilization

**Feature**: 199-beta3-stabilization
**Depth**: light
**Captured**: 2026-08-10
**Confirmation**: human-confirmed ("Train confirmed as drawn" plus the markdownlint ruling)

## The promotion path for v0.40.0-beta3 (agreed)

```text
branch 199-beta3-stabilization
   │  (feature lifecycle completes: implement → review-signoff → retro →
   │   feature-closeout, boundary commits throughout)
   v
PR to main ──> merge commit on main
   │
   v
CERTIFICATION REVIEW on the merge candidate      ← same discipline as beta2:
   │   (campaign certification runs; findings      certify BEFORE the tag
   │    adjudicated by the maintainer)
   v
tag v0.40.0-beta3 AT THE MERGE COMMIT
   │   annotated tag naming the release claim
   v
publish workflow (GitHub Actions, incl. tag-time prepublish gate)
   │
   v
PowerShell Gallery listing (Prerelease flag) ──> Gallery verification:
   │                                             listing live + install check
   v
maintainer PASS/FAIL ruling on the installed prerelease
   │
   └─ PASS → stable promotion (NOT this feature — beta-stable model,
             explicitly out of beta3's scope, as with beta2)
```

## Release-notes obligations (bound)

1. What this release fixes: the review-loop experience.
2. The updated known-issues list.
3. The explicit claim-alignment sentence: the evidence-pipeline and path-identity
   consolidations named in the beta2 claim ship in beta4.

## Install-path guidance (ledger item 4, doc half)

The default `-Scope CurrentUser` path becomes campaign-capable with the S1 reparse fix;
docs keep the `-Scope AllUsers` alternative and gain the single advisory sentence about
governed repositories living outside synced folders (security-compliance ruling).

## Human ruling — markdownlint CI chore lands IN scope

The `Deterministic gate / generator-markdown-parity` INCONCLUSIVE (markdownlint-cli
absent on the runner) is fixed in this feature as RELEASE HYGIENE — ruled under the
closed-scope exception, not against it: the red is certain on beta3's own PR (it failed
the alignment PR and main's last runs), so carrying it would schedule emergency work
mid-release. The one-line CI install lands now as a planned chore, recorded as the
198-carried item it is, not a new finding.
