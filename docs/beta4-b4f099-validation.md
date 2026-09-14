# B4F-099 bounded repair

**Released SHA: `8d3f99061e41396eaa4ac665d3883bcc75f88730`.** PRED-BETA4-058's sanctioned
CI/census pair is green (424/424 census files), followed by byte-verified installation and one further
router-skill update. The [final verdict](#pred-beta4-058-verdict---green-before-installation) records the
order and verification. The earlier red `97e03c80` is not frozen; its premature install/update remains
a B4F-027 process deviation. Historical claims below preserve that episode and are superseded by this
current result. Acceptance 5 is GREEN by the maintainer's 2026-09-14 re-scoped walk verdict.
**Beta4 is released; the stopping rule is closed.** The maintainer accepted independent Gallery
verification and initialization, with B4F-103 record-only and no republish. The
[final disposition](#b4f-103-maintainer-disposition---record-only-beta4-released) supersedes the initial
raw comparison's pending release disposition; the historical measurements remain intact.

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

## PRED-BETA4-058 correction evidence before the new census

The prediction and B4F-027 process deviation were committed in `82a080a1` before the new correction.
The two test-only assertion corrections already exist in `c0d1e148` and `4dae0a1b`; the new candidate
includes both commits. Production source remains unchanged.

**Decision: re-stamp the repository receipt; leave the fixture and validator unchanged.** The
validator's own failing output was:

```text
The deployed Specrew machinery under .specify/extensions/specrew-speckit does not match what was installed
(modified: scripts/specrew-conformance-provider.ps1, squad-templates/skills/design-workshop.md,
squad-templates/skills/gate-stop.md).
```

The repository's integrity checker independently named exactly those three paths and no missing files.
`Write-SpecrewDeployedExtensionMarker` regenerated the receipt with its existing version metadata.
It replaced those three hashes and inventoried nine existing but previously unlisted files, taking the
receipt from 164 to 173 entries. The resulting checker reports checked=true, drifted=0, missing=0.
This is derived inventory, not a production implementation change or a fabricated per-file digest.

The same positive ChangedOnly fixture setup now receives this validator output and exits 0:

```text
[validator-scope] changed-only to origin/main...HEAD (1 iterations, 1 files in diff)
PASS C:\Users\alon\AppData\Local\Temp\s58-a28a0aa9\explicit-changed-only\specs\013-validator-hardening\iterations\001
[validator-timing] mode=scoped elapsed_ms=64121 iterations_validated=1 trigger_source=local
```

Existing fixture warnings remain; the integrity refusal is gone. The full scope suite is still owed
by the new census; this focused reproduction is not described as that full suite.

The complete PSGallery suite passes with a named `offlineStartBoundMilliseconds = 15000` test bound.
Its timer covers the full child PowerShell/start invocation; exit-code and no-warning assertions
remain. The production timeout is unchanged. PowerShell parse errors: zero.

The next step is one sanctioned CI/census pair on the committed candidate. Installation and the
further router update remain withheld until green, and the walk stays on hold.

## PRED-BETA4-058 verdict - green before installation

**Walk SHA: `8d3f99061e41396eaa4ac665d3883bcc75f88730`.** The sanctioned pair ran once on this
candidate: [census 34813894967](https://github.com/alonf/specrew/actions/runs/34813894967) and
[CI 34813883244](https://github.com/alonf/specrew/actions/runs/34813883244), both green.
The complete census reports **files=424, pester=148, scripts=276, failed=0,
caller_contaminated=False**. All four previously failed files now pass, including the full ChangedOnly
suite. Prepublish validation and the dry-run stamp/publication step passed. CI passed Lint, Self-leak
firewall, Deterministic gate and Contract lane. No re-dispatch was used.

The process ordering is recorded from the completed runs and actual invocation timestamps (UTC):

| Event | Time |
| --- | --- |
| CI completed green | 2026-09-14 06:56:55 |
| Census workflow completed green, including dry-run stamp | 2026-09-14 07:26:38 |
| Installation started | 2026-09-14 07:27:28.4289886 |
| Installation completed successfully | 2026-09-14 07:27:48.9542563 |
| Further router update started | 2026-09-14 07:28:38.2241794 |
| Further router update completed successfully | 2026-09-14 07:28:48.8107569 |
| Post-update checks completed | 2026-09-14 07:29:49.1843814 |

Both run records were checked for the exact candidate SHA and completed success before the installer
was invoked. The installed stamp was checked for `8d3f9906` before the router update. Installation
ran once from the clean detached candidate checkout and byte-verified all 424 package files; the stamp
covers 423 content files, excluding itself. Content SHA-256 remains
`deb93b06c2d6f78f54a9ce558e1e66e5e2dde2695e46dae11f3ff0357eeac247` because this correction
changes tests, a derived repository deployment receipt and records, not packaged implementation.

The single further router update reports `0.40.0-beta4`. Its extension integrity check finds zero
modified or missing files, all six repaired script/template copies match the module byte-for-byte,
and both review-runtime hashes are
`62bcfae29901f4095ba1300e10e0e3b827e6c23b962851ecec393e01c7ce1dbf`.
All seven user records saved immediately before this update are byte-identical afterward. The updater's
31 consumer-assumption advisories remain recorded without expanding this repair. The source project's
two pre-existing dirty iteration-003 files remain unstaged.

The old installation ahead of green remains a B4F-027 process deviation, recorded before correction in
`82a080a1`; the new result does not ratify it. `97e03c80` remains the rejected census candidate.
This final evidence commit is documentation only, past the censused and installed `8d3f9906`; it does
not claim another source freeze or another CI/census pair.

PRED-BETA4-058 holds for the bounded correction and ordered delivery. The stopping rule is back in
force. The walk can now use `8d3f9906`; acceptance 5 is still the maintainer's installed-host walk.
B4F-100 and B4F-101 remain beta4.1, with only B4F-100's recorded exception if that walk trips it.
The abandoned d8ce3ea9 walk and original transcript remain preserved evidence.

## Maintainer walk verdict - GREEN on the re-scoped acceptance

On 2026-09-14, 08:29-09:11 PDT, the maintainer walked `8d3f9906` in
`C:/Dev/walks/beta4-final-8d3f9906`, using claude-opus-5 after an initial Fable turn, and ruled the
re-scoped acceptance **GREEN**. This is installed-host evidence, supplied by the human; it completes
acceptance 5 within that scope and authorizes tagging and publishing exactly `8d3f9906`.

- Orientation appeared once, in the first reply, as `0.40.0-beta4`.
- The agenda block appeared in the crew's message. The maintainer reported agenda receipts at
  08:41:52 and 08:42:00 PDT; the persisted controller binds the second receipt to the literal `yes`,
  as detailed below. Both rows remain in the evidence.
- One `move on` per lens: product-domain 08:32:28, architecture-core 08:43:42, code-implementation
  08:46:25 PDT.
- The specify packet named review targets, carried three real discussion prompts, ended with the
  marker, and used no lint picker. The spec was committed in-turn as `9adb8f2`.
- `approved for specify` was captured at 15:52:18Z and clarify began in the same turn;
  `approved for clarify` was captured at 15:56:38Z and plan began in the same turn.
- Feature `002-fix-broken-links` was created with its workshop controller and registered its first
  product-domain question while feature 1 was parked at clarify with a design-analysis draft.
- Unexpected repair prompts **0**, post-verdict asks **0**, partial acceptances **0**.

**Limits and deferred findings:** the product-domain correction step was not exercised, for the third
walk running. The subsequent plan-stage detour is beyond the accepted path: missing producer remedy
in the design-analysis refusal is B4F-102 (beta4.1); a clarify discussion default purported to skip a
mandatory stop is B5F-002 (beta5); authoring/committing the plan and five design artifacts before that
stop, with a false skipped declaration in `17462e4`, is B5F-003 (beta5). The gate correctly refused
the skip. These are recorded, not fixed, and do not broaden this release's accepted scope.

## Agenda receipt observation - persisted binding and remaining limit

The authority journal contains two feature-001 agenda receipts with the same question hash and
agenda digest, both labelled `UserPromptSubmit` / `claude`. They carry different response hashes,
so the store's identity function gives them different receipt IDs; this is not evidence that the
same `yes` was captured twice. The controller's `agenda_turn_receipt` names only the second row,
`4dfa36bca93c3182bb51fbe9c36d54682923acb807d2fd11cea9fa4c01d82a58`, recorded at
15:42:00.3389434Z. Its response hash is SHA-256 of the literal `yes`, which appears as a user message
at 15:41:58.994Z in the transcript. The subsequent confirmation invocation persisted that binding.

The first row, `8c7360e0c4fc3d3f49c346eccbc205d58267e6445604feaa2178d1dce45d2705`,
was recorded at 15:41:52.4237990Z with response hash
`fb021f566a5a68a4f4975df6b7c6fa26909cbb8ee046443817f7a704bd3a19a4`. No corresponding
input at that time, or string matching that hash, was found in the retained transcript. Its originating
input/event remains unattributed. The evidence establishes one persisted agenda binding to `yes`;
it does not justify inventing an explanation for the earlier input. This observation stays open
without a repair or an expansion of the accepted path. Full identities are retained in the JSON
companion evidence record.

## Publication completed - exact-byte Gallery check failed (B4F-103)

The authorized annotated tag `v0.40.0-beta4` was pushed and remotely verified after publication:
tag object `09f93247cf1264e78a42e29ce21f4da5cf061b94` peels to exactly
`8d3f99061e41396eaa4ac665d3883bcc75f88730`. The documentation HEAD is past that release SHA;
these verdict and verification records do not change the tagged source.

[Tag-triggered publication 34867622327](https://github.com/alonf/specrew/actions/runs/34867622327)
completed successfully. Its mandatory census passed **424/424** (148 Pester, 276 scripts,
failed 0, caller_contaminated False); prepublish validation and publish-module also passed.
This is the tag workflow's required gate, not a re-dispatch of the earlier sanctioned census pair.
PSGallery confirmed publication at 17:05:23Z on 2026-09-14; the GitHub prerelease was published
at 17:05:35Z with its module zip attached.

Release: [Specrew v0.40.0-beta4](https://github.com/alonf/specrew/releases/tag/v0.40.0-beta4).
Gallery: [Specrew 0.40.0-beta4](https://www.powershellgallery.com/packages/Specrew/0.40.0-beta4).

The downloaded Gallery `.nupkg` is 2,254,740 bytes, archive SHA-256
`d9c31711f918adfbac1d9230fef82a41e4d7afce25c22fd957d6a0341612c6b6`.
Its embedded stamp and the independently re-hashed local installation agree on commit `8d3f9906`,
423 content files and content SHA-256
`deb93b06c2d6f78f54a9ce558e1e66e5e2dde2695e46dae11f3ff0357eeac247`.
**That stamp equality does not pass actual package verification.** Hashing the downloaded content
with the same algorithm and declared file scope yields
`0c480fb8381135eef8d5af9ab6bb203e711c407750e3f1b6d587661ad7c92122`:

- Three declared `.gitkeep` files are absent: `extensions/specrew-speckit/hooks/.gitkeep`,
  `extensions/specrew-speckit/templates/quality/lenses/.gitkeep`, and
  `extensions/specrew-speckit/templates/quality/presets/.gitkeep`. The publish log records NU5119
  for each. NuGet's default exclusions removed them. Their local sizes are 0, 2 and 2 bytes.
- `Specrew.psd1` differs only at line endings on lines 3 (`ModuleVersion`) and 463 (`Prerelease`):
  CRLF became LF. All text and values are equal after CRLF-to-LF normalization. Applying the existing
  metadata writer to a temporary copy of the installed manifest reproduces the Gallery manifest
  hash exactly: `20729334e0b77e3a79c480d1e597f491b8dbd7387e502a17f179011dd0ca44cd`.
  The release path writes the build stamp before this metadata rewrite.
- The other **419** present content files are byte-identical. There are **420** actual content files
  in the declared scope, excluding the stamp. Four NuGet metadata files are outside that scope.

This is a bounded explanation of the failed identity check, not a waiver or a functional-install
claim. B4F-103 records the stamp/serialized-package disagreement. Publication succeeded; exact-byte
Gallery verification is **FAILED**. No source repair, retag, republish, installation, router update,
or extra census was made. The stopping rule remains in force, and the walk's re-scoped GREEN verdict
is retained separately from this packaging finding. The two pre-existing dirty iteration records
remain unstaged. Machine identities, timestamps and checks are in the JSON companion record.

## B4F-103 maintainer disposition - record-only; beta4 released

**Maintainer ruling, 2026-09-14:** B4F-103 is record-only, with **no republish**. The stopping rule is
**closed**; **beta4 is released** at `8d3f9906` as
[Specrew v0.40.0-beta4](https://github.com/alonf/specrew/releases/tag/v0.40.0-beta4).
The original raw comparison above remains a historical measurement, not an unresolved release blocker.

Independent verification on the maintainer's machine compared the Gallery `0.40.0-beta4` package
against the byte-verified `8d3f9906` build:

- **419 of 419 shipped content files are identical.**
- `Specrew.psd1` differs only by the publish-time stamp, reproduced by the metadata replay.
- The maintainer reports the three absent files as zero-byte `.gitkeep` placeholders that NuGet
  excludes (NU5119). They carry no missing template content. The earlier agent comparison's local
  placeholder sizes remain in its historical record; this is the maintainer's independent copy.
- `.specrew/version-check-cache.json` is a runtime file the module writes locally, not package content.
- `specrew init` from the Gallery copy deploys hook wiring, skills and every template directory that
  had content. The only absent directory, `hooks/`, held nothing.

These are maintainer-supplied runtime observations; no new installation or initialization was run
by the agent for this disposition. The narrower accepted claim is declared shipped-content agreement
plus the observed Gallery initialization, with the publish-time manifest transformation accounted for.
The original raw hash/count result is not rewritten into a passing check.

**Beta4.1 follow-up:** the exact-byte Gallery comparison excludes NuGet-dropped zero-byte placeholders
and the publish-stamped manifest line(s), or the package stops shipping `.gitkeep`; either route
compares the declared content scope. Local runtime files remain outside package content. This is
[B4F-018's rule](beta4-findings.md#b4f-018---the-spine-finding-a-claim-measured-over-a-narrower-set-than-the-claim-covers),
carried into B4F-103's comparison correction. The correction is recorded for beta4.1, not implemented
in beta4. The other beta4.1/beta5 findings retain their ruled dispositions.
