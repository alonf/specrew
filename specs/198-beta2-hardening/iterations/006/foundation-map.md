# Review Authority Foundation Map

This is the executable construction map for Iteration 006. The checked-in authority mode remains
`legacy` while the replacement is constructed. Cutover is an explicit `legacy -> disabled -> campaign`
change through `review-authority-mode.json`; missing, malformed, unsupported, or unknown configuration
enables neither path.

| Layer | Component | Responsibility | Mechanism dependencies |
| --- | --- | --- | --- |
| Cutover | `review-authority-cutover.ps1` | Select exactly one terminal authority path and fail closed | JSON configuration only |
| Core | `review-authority-core.ps1` | Campaign, run, allowance, acceptance, currentness, and lineage decisions | none |
| Ports | `CampaignRepository`, `RunRepository`, `ClaimRepository` | Sole logical mutation paths for review authority facts | implemented by store adapter |
| Ports | `ReviewTargetPort` | Freeze, identify, and compare a review target | implemented by Git/non-code fixtures |
| Ports | `HarnessPort`, `RuntimePort`, `ClockPort` | Invoke one reviewer, control its process tree, and observe time | fake adapters in Iteration 006 |
| Store | `review-authority-store.ps1` | Immutable JSON facts, run-owned claim generations, reconciliation | filesystem `FileMode.CreateNew` |
| Target | `review-target-port.ps1` | External Git target and thin target-neutral non-code fixture | Git adapter or fixture |
| Ingress | `review-result-ingestor.ps1` | Validate candidate JSON and publish controller-owned terminal JSON/Markdown | core plus store ports |
| Application | `review-campaign-orchestrator.ps1` | Synchronously compose target, harness, runtime, clock, store, and ingress | ports only |

Legacy lease and result files remain readable historical evidence after cutover. They are never imported
or promoted into campaign authority automatically. Five real harness adapters, three production runtime
adapters, progress/retro projection, cross-OS proof, live smokes, and final legacy removal belong to
Iteration 007; this map does not claim those capabilities are complete.

Operational warning: do not change the checked-in mode from `legacy` before Iteration 007 wires a
production command to the campaign orchestrator. `campaign` deliberately suppresses legacy spawn and
promotion; in Iteration 006 the replacement application service is executable through tests and the
bounded T050 operational adapter, but it is not yet a public production CLI path.
