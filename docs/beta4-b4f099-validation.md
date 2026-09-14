# B4F-099 bounded repair

The maintainer ruled B4F-099 into beta4 on 2026-09-14 UTC, limited to the four changes in the
regression report. PRED-BETA4-057 was committed in `91153385` before implementation. The authorized
delivery cycle is one freeze, one census, one installation and one router-skill project update.

The agent owns the visible question, agenda and boundary packet. The final tool call records the
draft and verifies its presentation; its result is information for the agent. Ordinary declarations
emit no human-facing text. A boundary declaration checks the authored packet and supplies only
missing approval/marker lines. Stop rejects prepared content absent from the assistant reply.
Opening orientation belongs to the agent, and its gate supplies only a missing expertise line.

Token resolution, typed authority receipts, crossing binding, missing-artifact withholding and
`Get-SpecrewVerdictCapturedDirective` retain their existing authority. Stale/skipped crossings still
receive the existing correction for the first unauthorized crossing. No new dependency or shipped
source file was introduced.

## Evidence and scope

[The integrated replay](../tests/integration/agent-led-workshop-replay.tests.ps1) exercises real prompt
and Stop providers, declaration, agenda/lens writers and verdict capture on a disposable project. It
applies the pre-answered Markdown checker: product-domain, one agenda, `yes`, architecture-core and
code-implementation with scoped `move on` replies, then a useful specify packet. The captured verdict
directs clarify to begin in the same turn. It verifies that presentation creates no approval itself.

The replay also substitutes the failing status-only reply for the prepared agenda and question,
rejects the generic packet, and checks the dials-only correction. A disposable mutation restores the
old rule 46A, the old in-flight `nothing needed` output, and removes the new presentation blocking
arms. It fails five assertions; the repaired replay passes. The mutation does not change token,
receipt or crossing machinery.

[Machine-readable evidence](beta4-agent-led-repair-evidence.json) records assertion results and log
hashes. The separate conformance suite retains negative and positive authority checks, including
wrong-session tokens, stale/skipped crossings, missing artifacts and loop bounds. Package, mirror,
skill, timestamp and capture guards supplement the composed replay. Changed PowerShell files have
no PSScriptAnalyzer errors; changed skill templates pass Markdown lint. The self-leak lint passes.

The abandoned `beta4-final-d8ce3ea9` project was not updated or repaired. Its original Claude transcript
remains at `C:/Users/alon/.claude/projects/C--Dev-walks-beta4-final-d8ce3ea9/d054058d-12c8-4046-b616-69b137fb08bf.jsonl`,
The original 208-line record has SHA-256
`DC3AEA61E2AA8AA323F3CD507B1C913C44191B59E2CB9A720C4D9F9689B63946` and remains an exact byte prefix.
Claude subsequently appended five session/history/cost metadata rows; the 213-line file now hashes to
`0781024B120A66712EB439BCFA318BF11B3C1B45C9894ABE36ACA5C7B2E9CE98`. No walk content was rewritten.

## Delivery record

The package is frozen at `97e03c80300a0d1305627e78e53b0896c317d62d`. The maintainer reviewed that
commit against PRED-BETA4-057 and accepted the four changes and their tests as ruled. Later branch
HEADs contain **tests and documentation past the censused SHA**, not another package candidate.
The existing dirty iteration-003 state and task-progress files remain outside this repair and unstaged.

Acceptance 5 remains the maintainer's Monday morning walk: orientation once, agenda once, `yes`
binds, `move on` per lens, a specify packet with real review targets, clarify begins on its verdict,
and the second feature's first question registers. Synthetic replay and CI do not satisfy
that acceptance. The stopping rule resumes after the one authorized delivery cycle; further scope
requires a new ruling.

### Census verdict

The single census, [34808258530](https://github.com/alonf/specrew/actions/runs/34808258530), is **red**:
420 of 424 suites passed (148 Pester files and 276 script files total; caller contamination false).
Prepublish package validation passed; publication was skipped. The four failures are dispositioned
below. No second census is dispatched, and subsequent focused results do not turn this run green.

| Failed suite | Observed failure and disposition |
| --- | --- |
| `flush-race-forensic.Tests.ps1` | Source-shape assertion expected declaration alone to credit a packet. B4F-099 requires a valid declaration plus visible content. Test-only correction retains the no-heuristic-reread assertions and verifies both conditions; focused Pester run passes 2/2. |
| `workshop-agenda-confirmation.tests.ps1` | The agenda correctly blocked without binding a digest, but the assertion expected the superseded rewrite remedy. Test-only correction in `c0d1e148` expects the ruled one-line presentation remedy. All authority assertions remain; focused suite and subsequent CI pass. |
| `psgallery-check.tests.ps1` | Offline bounded-time assertion measured 10,047 ms against a strict limit below 10,000 ms. Other assertions passed. The 47 ms overrun remains recorded; no timeout, test, or production change was made. |
| `validate-governance-changed-only.tests.ps1` | Three positive exit-code assertions failed. A scoped reproduction of the first case on frozen sources confirms its copied deployment receipt is stale: integrity validation flags the changed mirrored provider, workshop skill, and gate-stop skill. Scope selection and other assertions passed. The validator correctly refuses the mismatch; no validator or receipt repair was folded into this candidate. |

The fourth diagnosis comes from the actual validator output, not its exit code alone. The fixture
copies the repository's `.specify` deployment, including its old integrity receipt. The refused paths
are `scripts/specrew-conformance-provider.ps1`, `squad-templates/skills/design-workshop.md`, and
`squad-templates/skills/gate-stop.md`. This is a fixture/deployment mismatch; a normal project update
writes a fresh receipt. The scoped diagnostic is not a second census or a claimed suite pass.

### CI and the test/documentation delta

- `97e03c80`: [CI 34808258777](https://github.com/alonf/specrew/actions/runs/34808258777) failed Markdown
  lint (MD012 in findings, MD047 in predictions); non-packaged whitespace fixes are in `331aea94`.
- `331aea94`: [CI 34808371999](https://github.com/alonf/specrew/actions/runs/34808371999) passed 130/131
  honesty suites, including the complete conformance suite. Only the old agenda-remedy assertion
  failed; its test-only correction is in `c0d1e148`.
- **`c0d1e148` was CI red because of MD012 (multiple consecutive blank lines) in this validation
  document**, not a failed production assertion. That spacing was corrected in `27b40832`.
- `27b40832`: [CI 34809714198](https://github.com/alonf/specrew/actions/runs/34809714198) passed Lint,
  Self-leak firewall, Deterministic gate and Contract lane. The later forensic assertion correction
  has its own focused 2/2 pass; this CI result is not attributed to a later HEAD.

Post-freeze commits change only tests and documentation. Installed content comes from a clean
detached checkout of `97e03c80`; the later HEAD is explicitly not the censused or installed SHA.

### Maintainer review findings reserved for beta4.1

**B4F-100: whole-draft presentation matching.** `Test-SpecrewTurnMessageVisible` currently requires
the entire whitespace-normalized declared draft to occur in the reply. Tightening one packet sentence
after saving can block Stop with `presentation|declared message`; each miss can cost a human-visible
turn until the cap releases. This remains beta4.1 unless Monday's walk reproduces it. If it does, the
bounded alternative is to compare load-bearing lines: headings, review-target links, the question,
approval line and marker. No such relaxation is in the frozen candidate.

**B4F-101: draft placement.** `-MessagePath` has no fixed location, default or cleanup; the three
skills only say to save the draft. A draft saved under `specs/` can enter the next boundary commit or
dirty closeout. The beta4.1 repair is a fixed ignored `.specrew/runtime/turn-message.md`, named in the
three skills and defaulted by the script. This is recorded scope, not an implementation in beta4.

### Installed candidate and the single project update

The supported installer ran once from the clean detached frozen checkout. It byte-verified all 424
package files and verified the installed stamp: commit `97e03c80`, content SHA-256
`deb93b06c2d6f78f54a9ce558e1e66e5e2dde2695e46dae11f3ff0357eeac247`.
The stamp's `content_file_count` is 423 because it excludes `build-stamp.json` itself; the installer's
424-file verification includes that file. Installed version is `0.40.0-beta4`.

`specrew update --project-path C:/Dev/agentic-architecture-router-skill` ran once and exited 0.
The project's extension integrity marker was checked: zero drifted or missing files. The six repaired
script/template copies match the module byte-for-byte. Review runtime resolution selects the project
bundle and verifies both sides against
`62bcfae29901f4095ba1300e10e0e3b827e6c23b962851ecec393e01c7ce1dbf`.

Six saved user records remain byte-identical. The seventh, the exhaustion journal, retains all 705
baseline lines byte-for-byte plus four timestamped host-event appends (709 lines at verification);
no records were restored or discarded. The updater reported 31 consumer-assumption advisories and
preserved user-authored files; those advisories do not expand this bounded repair.

The authorized cycle is complete. The stopping rule is back in force. Monday's installed-host walk
remains acceptance 5; B4F-100 and B4F-101 retain the dispositions above. The abandoned d8ce3ea9 walk
and transcript remain evidence of the failing candidate.
