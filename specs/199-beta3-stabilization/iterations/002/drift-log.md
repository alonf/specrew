# Drift Log: Iteration 002

**Schema**: v2

<!--
  Markdown authoring note (Specrew lifecycle convention):

  When you add new drift events to this file, watch for MD032 (blanks-around-lists).
  A sentence ending with a colon, immediately followed by a bullet list, is the most
  common violation. Always put a BLANK LINE between the colon line and the list.

  The F-033 pre-boundary markdownlint gate runs markdownlint-cli --fix on .md
  changes before every boundary-sync write, so most violations auto-fix — but the
  blank line you write in the first place avoids the cleanup churn.
-->

## Summary

**Total drift events**: 5 (DRIFT-199-I002-001 through -005)
**Resolution rate**: carried per event in its heading (3 resolved-by this iteration's requirements,
1 spec-updated/human-decision, 1 deferred to beta4 by ruling)
**Specification drift**: one spec amendment, recorded as DRIFT-199-I002-002

## Events

### DRIFT-199-I002-001 — TB-1 and TB-6 reproduced live on the shipping tree at 001's closeout (resolved-by FR-024, FR-032)

**Recorded verbatim from the maintainer, 2026-08-29, watching it happen:**

> TB-1 fired live. The closeout capture immediately minted crossing-6f2f32905a4eb56
> (iteration-closeout → plan) at commit 2d758a21, while
> specs/199-beta3-stabilization/iterations/ still contains only 001/ — no 002 directory, no
> plan.md, no design-analysis.md. A crossing demanding approved for plan exists over a stage
> with nothing in it, exactly as at 928c76e. It was also rendered into the reviewer session,
> which produced none of it — TB-6, in the same breath. Both recommended tag-blockers
> reproduced themselves on the shipping tree at the next boundary after being catalogued.
>
> Had the reviewer session rendered the options as its hook instructed, I was three retries
> deep and one paste away from authorizing a plan boundary over an empty directory. That is
> the argument for TB-1 half 2 and it is no longer theoretical.
>
> [TB-6] is not "the wrong session gets asked once" — it fires on every Stop, every turn,
> regardless of topic, for as long as any crossing is open, so a second session cannot hold an
> ordinary conversation in a governed project. It shares its design question with TB-1 and
> item eight: is this actor the one that owes this?

- **Observed, measured by the working session**: at 10:24:30Z the Stop hook wrote the
  `retro -> iteration-closeout` authorization (verdict 8) and in the same second minted
  `iteration-closeout -> plan` (`crossing-6f2f3290...`, commit `2d758a21`, tree `90be7bff`,
  `Multi-boundary gap: true`), then instructed this session to render the packet with the plan
  marker. The stage-evidence read was *unverifiable* - no iteration identity in the bound tree -
  which does not suppress the demand: the carve-out TB-1 turns on. The working session withheld
  the marker by hand under FR-024 half 2 and did the plan stage's work instead. This is not a
  reconstruction from a prior walk; it is a reproduction on the tree that ships, with the
  maintainer watching, one turn after the fix was designed.
- **Rebind or re-mint, determined from source rather than assumed**: the plan sync re-mints.
  `Set-SpecrewPendingBoundaryCrossingScope` derives `artifact_state_id` from the commit it is
  given (HEAD at sync time), builds a new identity through `New-SpecrewBoundaryCrossingIdentity`,
  and replaces `pending_crossing` with it; only when the new identity equals the existing
  `crossing_id` is `recorded_at` preserved. So once the tree carries iteration 002's artifacts and
  the plan sync runs, `crossing-6f2f3290...` is superseded by a new identity bound to the new
  commit and tree - never approved, never rebound. One consequence worth its own line: the
  verdict marker text is the same for both identities (`iteration-closeout -> plan`), so a marker
  rendered against the empty-stage crossing would still have captured against its successor;
  withholding it was the only safe act.
- **Citation**: FR-024 (mint gate and withhold), FR-032 (the owing actor); the crew brief's TB-1
  (KeyContextAI iteration 003, three crossings at `928c76e`).
- **Resolution**: fixed in this iteration - the live-filesystem mint gate at all three minting
  mechanisms, the packet re-mint guard, the withhold discipline stated once and mirrored
  everywhere (FR-024); the crossing record carries its owning session and the Stop-hook demand
  fires only there (FR-032).
- **Class closure**: the three share one rule - the actor that produced an arrival owes its
  packet, its mirrors and its evidence, and ownership is recorded with the artifact. Mutations:
  the ladder replays when the mint gate is removed; a second session's Stop demands a packet when
  the owner check is removed.

### DRIFT-199-I002-002 — the spec grows FR-024..FR-033 for the tag batch (spec-updated, human-decision)

- **Observed**: 2026-08-29, at the opening of iteration 002. The ten batch items (seven from two
  field walks, item eight from DRIFT-199-I001-152, item nine from the first sealed closeout, item
  ten - TB-6 - from DRIFT-199-I002-001) are not in spec.md's FR-001..FR-023, and the plan's spine
  is FR-to-task traceability.
- **Citation**: TG-004 - scope is closed "unless it blocks the acceptance bar itself; the
  reconciliation path ... is a drift-log entry citing the governing FR plus a maintainer ruling".
- **Ruling**: the maintainer accepted the report (2026-08-29), added item eight, ruled the split of
  TB-3, the class scope of item eight, the merged F-1/B-6 writer, the TB-4 sibling reader, item
  nine and item ten, and ruled the six remaining items and the UX programme to beta4.
- **Resolution**: spec-updated - User Story 8, FR-024..FR-033, SC-011..SC-020, TG-003 and TG-004
  amended in file:///C:/Dev/specrew-beta3-stabilization/specs/199-beta3-stabilization/spec.md.
- **Class closure**: NONE - a spec amendment under TG-004's own exception is the governed path,
  not a defect.

### DRIFT-199-I002-003 — the closeout seal is written before the dashboard it seals (resolved-by FR-031)

- **Observed**: 2026-08-29, at iteration 001's closeout, the first closeout under the W51 seal.
  `sync-boundary-state.ps1` runs index -> seal -> dashboard render; `dashboard.md` carries a
  `Captured At` timestamp, so the re-render always changes bytes and the seal never matches. The
  validator then refused the closeout it had just produced (`closed-iteration-edited:
  dashboard.md`), and the background full validation printed that one finding 253 times.
- **Citation**: the seal's own contract ("written LAST at iteration-closeout, after every record
  has landed"); W77's class (a sync's own write refused by its own gate).
- **Recovery taken**: re-sealed through `Write-SpecrewIterationSeal` after the render;
  `Test-SpecrewIterationSealIntegrity` clean; recorded in 001's retro rulings.
- **Resolution**: fixed in this iteration under FR-031 (maintainer ruling: "guaranteed, not
  conditional ... every tester's first closeout fails").
- **Class closure**: the seal becomes the closeout sync's last write, with a test asserting the
  seal hashes the rendered dashboard.

### DRIFT-199-I002-004 — a verdict behind a leading quote bar is classified as discuss, silently (resolved-by FR-010, this iteration)

**Recorded with the weight the maintainer assigned it, 2026-08-29:**

> It bit me directly. My approved for iteration-closeout failed because the verdict was pasted
> with a leading quote bar, and nothing said so until the recap. A silently-ignored authorization
> phrase is DRIFT-012's shape and it cost two retries. Give it the same weight as the others.

- **Observed**: the maintainer's closeout verdict began with the terminal quote bar `▎` and then
  `approved for iteration-closeout — ...`; `Test-SpecrewHumanVerdictToken` returned
  `Action=discuss, IsApproval=False` because the leading-approval-phrase rule saw the bar first
  and the discuss clause then matched "Prompt 1:". No refusal, no journal line; the Stop capture
  would have fallen back to the already-recorded retro pair. The retro verdict had captured only
  because its first line carried no bar. The working session caught it with a read-only check and
  asked once for the bare phrase - two retries for the maintainer, the recap being the first
  place anything said so.
- **Citation**: FR-010 and User Story 3 ("the maintainer's verdicts always capture") - an existing
  requirement of this feature, so the fix traces to FR-010 and needs no new requirement; W54's
  class and DRIFT-012's shape (the silently ignored near-miss authorization phrase).
- **Resolution**: fixed in this iteration as an FR-010 defect: when a verdict-shaped turn is not
  captured, the capture says so and names what it received and what would capture (SC-020). The
  recognizer is not widened.
- **Class closure**: silent fallback to an older pair is the defect, not the classification; the
  leading-quote-bar turn is the pinned fixture.

### DRIFT-199-I002-005 — one repo-level validator finding printed once per validated iteration (deferred, beta4)

- **Observed**: 2026-08-29. The trust-hardening `closed-iteration-edited` finding was printed once
  per iteration validated - 153 lines describing one fact.
- **Citation**: the refusal standard (B-4.1), inverted: naming every instance of something that
  has one.
- **Resolution**: deferred to beta4 with the refusal standard (maintainer ruling 2026-08-29).
- **Class closure**: NONE in this iteration - beta4's standing check over refusal surfaces.

### Resolution Strategies (Unused)

The following resolution strategies remain available if drift is detected later in execution:

- **spec-updated**: Update the spec to reflect implementation choice
- **implementation-reverted**: Revert implementation to match spec
- **deferred**: Mark drift as deferred to next iteration
- **human-decision**: Escalate to Alon for resolution

### Notes

- This artifact was scaffolded before review starts so drift can be logged immediately when detected.
- Counts in the Summary were measured against the entries on 2026-08-29.
