# Flush-Race Forensic — D-197-I009-003 (T109, FR-040/SC-025)

**Date**: 2026-07-08
**Verdict**: **REFUTED with evidence** — no flush/read race signature in the captured corpus; the
reverted 4×-tail-200 re-read mitigation is NOT re-added (no cheaper variant is needed).

## The suspicion (iter-009)

D-197-I009-003 suspected a flush/read race in the conformance Stop-provider: the provider reads the
transcript tail while the host is still flushing the last assistant message, so a **valid re-entry
packet on disk** could still evaluate `packetPresent=false` and trigger a spurious stop-block
(symptom: a "double render"). iter-009 shipped a 4×-tail-200 re-read mitigation, then **reverted it
for cost** (~17 s per material stop, starving the shared 20 s Stop budget) and instrumented the
decision inputs instead (`dx_lat_len`, `dx_lat_hits`, `dx_packet_present`, `dx_cc_loaded`,
`dx_transcript_*` on every journal record).

## The forensic (real captured data, self-host dogfood corpus)

Corpus: `.specrew/runtime/conformance-journal.jsonl` on the maintainer's machine — 21 records
(13 `observe`, 8 `stop-block`) spanning 2026-06-29 → 2026-07-08, all with live dx instrumentation.

The race signature would be: a block whose read message is **stale** relative to a packet the agent
had already rendered — concretely, either (a) a material/boundary block with `dx_packet_present=false`
whose read message is the *previous* turn (short/stale) while the durable transcript carries a
packet-bearing assistant message timestamped before the block, or (b) an unreadable/empty read
(`dx_lat_len=0` / `dx_cc_loaded=false`) racing a flush.

| recorded_at (UTC) | kind | dx_lat_len | dx_lat_hits | dx_packet_present | classification |
| --- | --- | --- | --- | --- | --- |
| 2026-06-29 23:34:26 | boundary | 2970 | 0 | false | legitimate: substantive message, zero packet headers |
| 2026-07-01 08:31:31 | material | 897 | 0 | false | legitimate: packet genuinely absent |
| 2026-07-01 14:41:48 | material | 2904 | 0 | false | legitimate: packet genuinely absent |
| 2026-07-01 17:33:25 | material | 958 | 0 | false | legitimate: packet genuinely absent |
| 2026-07-01 20:40:07 | boundary | 3388 | 5 | **true** | marker mismatch — the D-197-I010-001 bogus-cursor window (expected crossing `intake → specify` was wrong), NOT a read race: the packet WAS read |
| 2026-07-01 20:41:23 | boundary | 3164 | 6 | **true** | same as above (the forced re-render, same bogus expected marker) |
| 2026-07-01 23:01:29 | material | 268 | 0 | false | legitimate: short conversational close, no packet |
| 2026-07-08 07:45:02 | material | 6948 | 0 | false | legitimate + directly witnessed: the 6,948-char message was the iteration status REPORT (this session), which carried no packet; the agent then rendered the packet and the next stop passed |

Findings:

1. **Zero events show a stale or unreadable read.** Every block read a real, substantive message
   (`dx_lat_len` 268–6948, `dx_cc_loaded=true` throughout); every `dx_packet_present=false` block
   read a message that genuinely contained none of the six section headers.
2. The only two packet-present blocks are **marker-mismatch enforcement working as designed**, under
   the known (separately-tracked) boundary-cursor defect D-197-I010-001 — the packet itself was read
   correctly at block time, which is the OPPOSITE of the race hypothesis.
3. The 2026-07-08 event is first-party witnessed end-to-end in this session: legitimate block →
   packet rendered → subsequent stop passed. The mechanism works; no double-render occurred.
4. The instrumented false-negative (**a valid packet evaluating `packetPresent=false`**) has not
   reproduced once since the dx instrumentation shipped (iter-009 → today).

## Decision

- **D-197-I009-003 is CLOSED: refuted-with-evidence** (per the design N7 either/or and the maintainer's
  approved default: "N7 closes D-197-I009-003 as refuted-with-evidence if the forensic test finds no
  race"). No mitigation is re-added; the T099 material-turn gate keeps the parse cost bounded anyway.
- A permanent analyzer (`tests/continuous-co-review/unit/flush-race-forensic.Tests.ps1`) re-runs this
  classification against whatever journal corpus exists on the machine (honest skip when none): if the
  race signature EVER appears, the analyzer fails and reopens the question with a captured dx record —
  exactly the reproduction the reverted mitigation was waiting for.
