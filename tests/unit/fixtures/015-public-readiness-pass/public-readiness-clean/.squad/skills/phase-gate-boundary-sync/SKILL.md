---
name: "phase-gate-boundary-sync"
description: "Keep planning, implementation, and coordinator guidance aligned when a later-phase gate becomes the current slice entry condition."
domain: "governance"
confidence: "high"
source: "earned"
---

# phase-gate-boundary-sync

## Purpose

Prevent lifecycle drift when a requirement from a later delivery phase becomes the current iteration's actual go/no-go gate.

## When to Use

- A slice introduces a new pre-implementation or pre-review gate.
- Planning guidance, implementation readiness guidance, and coordinator policy can each misstate whether that gate is already active.
- The current work should tighten lifecycle language without falsely claiming later automation or enforcement already exists.

## Pattern

1. Update the planning checkpoint to describe the gate as required future readiness, not as already satisfied evidence.
2. Update the implementation checkpoint to name the concrete artifact, required sign-off fields, and any human-only deferral rule.
3. Update the coordinator policy so handoffs and readiness summaries carry the same boundary language.
4. Keep adjacent later-phase capabilities explicitly deferred unless the active slice truly delivers them.
5. Repair iteration state/plan/drift artifacts immediately after the guidance lands so execution truth matches the newly accepted gate language.
