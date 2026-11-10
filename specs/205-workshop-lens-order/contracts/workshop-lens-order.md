# Contract: Workshop Lens Order Public Surface

**Feature**: 205-workshop-lens-order
**Stability**: pre-1.0 (0.40.0 beta line)

## Lens catalog (`index.yml`)

The single source of the lens order and of each lens's space. Position in the list is the order.

### Exported API

| Symbol | Signature | Purpose | Errors |
| --- | --- | --- | --- |
| `lenses[].space` | one of problem, solution, both | the lens's question space | a missing or unknown value fails the parity test |
| `lenses[]` order | list position | the one workshop order | a disagreeing surface fails the parity test |

### Invariants

- `index.yml` wins on any disagreement, and the skill states this.
- A confirmed agenda keeps the order it was confirmed in.

## Lens file sections

### Exported API

| Symbol | Signature | Purpose | Errors |
| --- | --- | --- | --- |
| `### Problem questions`, `### Solution questions` | list items, or `No <space> questions: <reason>`, inside `## Design Decision Points` | tagged questions | a missing heading, an untagged point, or a mismatch with `space` fails FR-005 |
| `Get-SpecrewLensDecisionPoints` | unchanged signature | returns the points under both sub-headings | the counts must match SC-002 |

### Invariants

- A question is never filed under the wrong heading to make a check pass (FR-015).

## `confirm-workshop-agenda.ps1` (behaviour change)

### Exported API

| Symbol | Signature | Purpose | Errors |
| --- | --- | --- | --- |
| relative-order check | runs on render and on confirm of a new agenda | refuses an agenda whose selected lenses break the `index.yml` relative order | a terminating refusal via `New-SpecrewWorkshopAgendaRefusal`, naming the out-of-order lenses, the `index.yml` order, and one action; nothing is written |

### Invariants

- It never reorders an agenda.
- An agenda that is already confirmed is never re-checked (FR-013).

## `tests/unit/lens-order-parity.tests.ps1`

### Exported API

| Symbol | Signature | Purpose | Errors |
| --- | --- | --- | --- |
| mismatch line | `<path>:<line>`: expected `<index.yml order>`, found `<order>`; fix: `<action>` | one per mismatch | for a copy, the fix names the two deploy commands and says they are project-only |
| exit code | 0 or 1 | 0 when every check passes; 1 after reporting **every** mismatch | never stops at the first mismatch |

### Invariants

- `specs/` and `proposals/` are never scanned or rewritten.
- The full surfaces are named in the test itself.
