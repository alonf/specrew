# Product & Problem Domain — Feature 200

**Depth**: Standard
**Context**: Feature standalone
**Confirmation**: human-confirmed (`lens-question`)

## Users and Stakeholders

Specrew maintainers need to add and validate hosts without weakening shared-core
abstractions. Developers need Specrew lifecycle behavior when running through Devin CLI.
Future host-package authors need the documented folder-only extension contract to be true.

Incorrect behavior can cause missed lifecycle stops, incomplete handovers, package/install
drift, or regressions across the five existing hosts.

## Pain and Current Workaround

The host registry and package contract are mostly data-driven, but remaining shared
validation enums, hand-maintained package entries, and coordinator-tier literals still
force core edits. The current workaround preserves explicit firewall exceptions, so each
new host risks expanding coupling instead of proving extensibility.

## MVP

- Replace the three host validation allow-list entries with registry-driven validation.
- Generate host-package `FileList` entries deterministically and parity-test the result.
- Add a permanent host-addition purity assertion and shrink the firewall allow-list.
- Add the Devin host package with its manifest, five handlers, and coordinator rules.
- Add manifest-driven coordinator eligibility and migrate `iteration-config.yml`.
- Pin `devin 2026.7.23 (3bd47f77)` as the tested build identifier.
- Run the transcript/handover spike before planning that implementation.

## Transcript and Handover Gate

The early real-host spike selected outcome 2:

1. The live Stop payload was exactly the documented narrow shape:
   `hook_event_name=Stop` plus `stop_hook_active=false`. It carried no assistant message,
   so Tier-3 is unavailable.
2. `--export` wrote ATIF before the Stop hook fired.
3. A scratch Devin-local normalizer converted ATIF user/agent steps to the existing
   Claude-like JSONL turn shape. The unchanged parser captured both synthetic canary turns.

Full handover therefore remains in the MVP without any edit to
`scripts/internal/bootstrap/ConversationCaptureAccessor.ps1`.

The spike also found a pinned-build Windows constraint: Claude-format hook commands failed
with `program not found` until Git's `sh.exe` was added to `PATH`, although Devin's general
Windows non-interactive shell is PowerShell. Devin remains experimental while this
compatibility requirement is handled and revalidated.

## Non-Goals and Constraints

- No Slice B transcript-turn-shape refactor in this feature landing.
- No edit to `scripts/internal/bootstrap/ConversationCaptureAccessor.ps1`.
- No Devin Desktop/Cascade integration or legacy Windsurf/Cascade paths.
- No hand-authored Devin/Windsurf literal outside `hosts/devin/`, except generated
  artifacts and the maintained tested-version declaration.
- No firewall allow-list growth.
- No regression to existing hosts.

## Success

Devin is integrated through the host contract and validated on the real CLI. Shared edits
are generic abstraction completions. The allow-list shrinks by five production entries,
package generation is reproducible, and handover evidence matches the spike outcome.
