# Data and Storage Lens Workshop

## Lens

- **Lens ID**: `data-storage`
- **Depth**: medium
- **Confirmation**: human-confirmed
- **Confirmation scope**: lens-question

## Decision Agenda

- Is persistent storage required, or is derived/transient state enough?
- What owns each data type?
- Which storage model fits the first slice?
- What consistency model is required?
- How are schema changes, backup, restore, and retention handled?
- How does the design avoid direct access to another component's private storage?

## Agreed Data-Storage Direction

Iteration 001 uses versioned filesystem artifacts only. It does not introduce a database, queue, cache, event
stream, search index, blob store, or external data provider. Durable review evidence is written under
`.specrew/review/inline/<run-id>/...`, while temporary request bundles remain in per-run workspaces owned by
`ReviewRunWorkspaceManager`.

The durable system of record for review evidence includes run metadata, findings, dispositions, fix evidence
references, gate verdicts, and provenance. Temporary request bundles are immutable, unique to a run, never reused
across runs, and cleaned by default unless explicit debug preservation is enabled.

Durable artifacts should be committed to Git when they are boundary evidence. Temporary request bundles are not
committed by default.

## Storage Model

```text
+-----------------------------+       temporary / cleanup-owned        +------------------------------+
| ReviewRunWorkspaceManager   |--------------------------------------->| per-run request bundle        |
|                             |                                        | - diff/context payload         |
| owns temp workspace         |                                        | - provider input               |
| owns cleanup/debug preserve |                                        | - not reused across runs       |
+-----------------------------+                                        +------------------------------+
             |
             | normalized result + provenance
             v
+-----------------------------+       durable / audit-owned             +------------------------------+
| ReviewBlackboardWriter      |--------------------------------------->| .specrew/review/inline/run-id |
|                             |                                        | - run metadata                 |
| owns artifact schema writes |                                        | - findings                     |
| owns review-thread state    |                                        | - dispositions/resolution      |
| does not own temp bundle    |                                        | - gate verdict/provenance      |
+-----------------------------+                                        +------------------------------+
```

## Data Ownership

```text
+-------------------------+------------------------------------------------------------+
| Data-storage area       | Agreed Iteration 001 decision                              |
+-------------------------+------------------------------------------------------------+
| Store choice            | Versioned filesystem artifacts only; no database or        |
|                         | external store in the first slice.                         |
+-------------------------+------------------------------------------------------------+
| Durable system of record| .specrew/review/inline/<run-id>/ owns review evidence:     |
|                         | run metadata, findings, dispositions, fix evidence refs,   |
|                         | and gate verdict/provenance.                               |
+-------------------------+------------------------------------------------------------+
| Temporary working state | Per-run immutable request bundle in a temp workspace owned |
|                         | by ReviewRunWorkspaceManager; no reuse; cleanup by         |
|                         | default; debug preserve only when explicit.                |
+-------------------------+------------------------------------------------------------+
| Consistency             | Single-run deterministic artifact set keyed by run id.     |
|                         | Cross-run correlation uses finding ids/source run ids, not |
|                         | a shared database.                                         |
+-------------------------+------------------------------------------------------------+
| Schema evolution        | Durable artifacts include schema version. Unknown or       |
|                         | malformed versions are unsafe gate states.                 |
+-------------------------+------------------------------------------------------------+
| Git evidence policy     | Commit durable review artifacts when they are boundary     |
|                         | evidence; do not commit temp request bundles by default.   |
+-------------------------+------------------------------------------------------------+
```

## Binding Data-Storage Decisions

- Versioned filesystem artifacts are the only storage model in Iteration 001.
- `.specrew/review/inline/<run-id>/...` is the durable system of record for review evidence and gate state.
- `ReviewRunWorkspaceManager` owns temporary request-bundle storage, cleanup, debug preservation, and no-reuse
  guarantees.
- `ReviewBlackboardWriter` owns durable review artifact writes and does not own temporary bundle lifecycle.
- Durable artifacts include schema version information; unknown or malformed schema versions are unsafe gate
  states.
- Cross-run traceability uses stable finding ids and source run ids rather than a shared database.
- Durable review artifacts are committed when they serve as boundary evidence; temporary bundles are not committed
  by default.
