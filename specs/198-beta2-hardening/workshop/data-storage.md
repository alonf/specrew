# Workshop Record: data-storage (light)

**Feature**: 198-beta2-hardening
**Date**: 2026-07-09
**Confirmation**: human-confirmed ("confirm b")

## Data at rest (agreed)

```text
  SelfLeakDenyList     extensions/specrew-speckit/data/… (ships in FileList)
    format: JSON, schema_version (per I3)      [precedent: refocus-scopes.json]
    entry:  { pattern (regex), class (release-model | dev-path | feature-id |
              maintainer-id | registry | repo-ref | decision-ref),
              reason, source (field-report/proposal ref), added (date) }
    annotation escape, per file kind (settles 205 open q3):
      .md              <!-- specrew-self-ok: <reason> -->
      .ps1/.psd1/.yml  # specrew-self-ok: <reason>
      semantics: same line or the line immediately above the hit

  MachineryPathList    same data dir; the S2 path-granular globs; consumed by
                       digest strip + worktree strip (single truth)

  ReviewerHostCatalog  + default_timeout_seconds (int) per row; absent → 600
                       floor (tolerant reader, per I3)

  RepositoryGovernance + release_model recorded at init (204-W7)

  Navigator state      last-REVIEWED checkpoint identity (W9) + fire-time
                       tree id (W10) persist in the review run records under
                       .specrew/review/** (durable store — tracked by design)
```

## W13 identity mechanism (decided: option b)

Digest formula UNCHANGED — trackers stay identity. The SIGNOFF GATE, on an
evidence-vs-current mismatch, computes the delta: if it is tracker-only AND
TrackerHonestyCheck passes, the gate accepts the evidence as fresh and
ANNOUNCES the accepted reconcile (transparency NFR #2), recording it in the
gate output. "What is certified is what was reviewed" holds unconditionally;
the bypass is an explicit, visible, gate-level decision — never a change to
the identity formula. (Option (a), excluding trackers from the digest, was
rejected: it would re-open the certified-but-unreviewable class W5 kills.)
