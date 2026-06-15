# Requirements NFR Workshop Record

**Lens**: requirements-nfr · **Depth**: medium · **Confirmation**: human-confirmed
**Facilitated**: one decision at a time with the human (2026-06-08).

LIR-007 turns the already-decided properties (FR-006/007/011/012) into **measurable**
review criteria.

```text
Priority order (compatibility + regression safety are NON-NEGOTIABLE / mandated)
1. Compatibility    specrew start remains supported (FR-006, User Story 2)
2. Idempotency      launcher + hook does not double-bootstrap (FR-007, SC-002)
3. Reliability      direct launch works across hook-bound hosts (SC-001)
4. Scope control    B1/B3 unchanged (FR-011, SC-005); B4/Antigravity deferred (FR-012)
```

## Decision 1 - measurable NFR criteria

**Chosen: option 2 - measurable acceptance criteria per NFR, each mapped to an SC/FR + a
concrete test.**

| NFR | Measurable pass/fail | Maps to |
| --- | --- | --- |
| Backward compatibility | `specrew start` smoke still works + docs reframed | SC-006, FR-006 |
| Idempotency | launcher + hook in one startup -> exactly one bootstrap (dedupe test) | SC-002, FR-007 |
| B1/B3 regression safety | B1 post-compaction + B3 boundary-cross digest unchanged vs F-171 | SC-005, FR-011 |
| Deferred scope held | **negative test**: no B4 / Antigravity code path executes | FR-012 |

- Rejected: option 1 (qualitative checklist - not evidence); option 3 (perf SLOs -
  over-built; no lens flagged perf as a driver).

## Priority / conflict note

No live NFR conflict exists - compatibility, idempotency, and B1/B3 regression safety are
all "preserve existing behavior" and do not fight. The only latent tension (keeping
`specrew start` adds surface vs a hook-only world) is **already resolved by the maintainer**
(FR-006 / User Story 2). Recorded priority: **compatibility and regression-safety are
non-negotiable and outrank any simplification.**
