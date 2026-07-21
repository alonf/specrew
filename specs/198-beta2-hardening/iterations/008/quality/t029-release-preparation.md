# T029 Prerelease Preparation Evidence

**Task**: T029
**Starting commit**: `923b16b4fb03db7eea0f61ad1538504e387cc605`
**Target tag**: `v0.40.0-beta2`
**Scope state**: authorized through green release-PR checks; merge, tag, and publication wait for the maintainer

## Authorized Boundary

The maintainer authorized preparation, validation, push, PR creation, and observation of required PR checks.
After those checks pass, the authoring identity must stop. It must not bypass protected-branch review, attempt the
merge, retry a refusal, create the release tag, publish, or promote stable without the maintainer's next explicit
instruction.

## Release Identity Surfaces

| Surface | Required value |
| --- | --- |
| `Specrew.psd1` `ModuleVersion` | `0.40.0` |
| `Specrew.psd1` `Prerelease` | `beta2` |
| Source extension manifest | `0.40.0` |
| Deployed extension manifest mirror | `0.40.0` |
| Installed extension registry | `0.40.0` |
| `.specrew/config.yml` | `0.40.0` |
| Release notes and changelog | `0.40.0-beta2` |

## Required Publication Evidence

After the maintainer authorizes merge and the tag-driven workflow completes, T029 must record all three facts:

1. the immutable tag and commit it resolves to;
2. the **Publish Specrew module** workflow run ID/URL and outcome;
3. the visible PSGallery `0.40.0-beta2` listing.

No stable tag or promotion is part of T029.

## Preparation Validator Correction

The first local release-surface assertion stopped before the broader suite because its extension-manifest regex
anchored `version:` at column zero. Both shipped extension manifests correctly store the base version as the
indented YAML key/value `version: "0.40.0"`; extension surfaces do not carry the prerelease suffix. The maintainer
authorized one corrected validation attempt. The corrected assertion accepts YAML indentation while still
requiring the exact base value `0.40.0`; only `Specrew.psd1` requires `Prerelease = 'beta2'`.

The corrected sequence then exposed a separate prepublication-harness incompatibility. Commit `f01a4dcf` moved
the Docker image to Spec Kit `0.12.9` / Squad `0.11.0`, but the upgrade fixture still bootstrapped published
Specrew `0.27.6`. That baseline calls the removed `specify init --ai` surface and therefore cannot initialize
under Spec Kit `0.12.9` (`--integration` is the replacement). The Devin feature worktree retains the earlier
`0.8.4` / `0.9.1` pins; it did not introduce this Beta2 pin sweep.

The authorized correction makes the historical and candidate identities explicit. Phase 4 keeps the real
`0.27.6` bootstrap under Spec Kit `0.8.4` / Squad `0.9.1`. Phase 5 loads the Beta2 candidate and calls its
production `Update-Specrew -All -SkipUpdateCheck` path, which upgrades the tools to the candidate's exact
`0.12.9` / `0.11.0` `max_tested` pins while refreshing project surfaces. Exact pre/post probes fail closed, and
the contract regression prevents collapsing the two identities, removing Phase 4, or bypassing production update
with harness-owned tool installs.

The one authorized corrected Docker harness run passed on 2026-07-21 in `181.1 s`. It proved all 392 `FileList`
entries, base-version parity at `0.40.0`, exact baseline tool identities, successful published-`0.27.6`
initialization, production-path upgrades to the exact candidate pins, project transition to `0.40.0`, post-update
FileList integrity, and zero duplicate Squad rows. The strengthened harness-contract regression also passed before
the container run. No second Docker harness run was used.

## Release PR Gate Corrections

PR #3090 initially exposed three bounded problems before merge handoff:

- Markdown lint reported 31 mechanical findings across eight historical/current Markdown files. The exact
  PR-changed Markdown surface now passes `markdownlint`, with no content change beyond the necessary nested-code
  wording repairs.
- Independent review found that campaign-mode `specrew review --live` did not reload a project-level recorded
  reviewer authorization. Commit `e305ecec` routes the persisted selected host/model/reference through the existing
  selection policy into the one-slot campaign grant. A real public-command, provider-free regression proves one
  grant fact, zero spend facts, and fail-closed preflight; 85 focused campaign/selection/authorization tests pass.
- Changed-only governance surfaced the already-recorded Iteration 005 missing-`plan.md` exception. Iteration 005 now
  has an archival `abandoned` plan plus matching canonical state fields, following the repository's existing
  post-hoc disposition precedent. It records T035–T039 as delivered and T040 as deferred, does not fabricate a
  review/retro/closeout cycle, and grants no new implementation authority. The explicit Iteration 005 governance
  validation passes.

The subsequent required deterministic gate run `29795301413` exposed seven Linux/aggregate-lane defects rather
than release-surface failures. The bounded correction keeps the proof obligations intact:

- origin-root scrubbing now recognizes foreign Windows absolute paths without resolving them as Unix-relative;
- Linux lease liveness uses the kernel `/proc/<pid>/stat` start tick, with a cross-process regression and
  conservative compatibility for in-flight legacy lease records;
- the detached-service handoff fixture creates its harmless process before installing the Pester mock, avoiding
  Linux mock recursion while still proving that a failed handoff stops the process and releases the lease;
- stale-boundary output and synthetic Windows path-length assertions are lexical and formatting-independent;
- the distribution-upgrade fixture archives one immutable tracked candidate snapshot instead of repeatedly
  copying from a live checkout;
- unprivileged generic Linux skips only the duplicate native-process matrix cases; the dedicated three-OS job
  retains `SPECREW_REQUIRE_POSIX_RUNTIME_PROOF=1`, provisions cgroup v2, and must execute every adapter/runtime
  case.

Local correction evidence is provider-free: the two script regressions pass; Windows Pester records 45 passed and
one Linux-only skip, including all eleven native fake-provider/Job Object cases; WSL Pester records the origin,
lease, service, and generic-lane corrections green, with eleven explicitly reported unprivileged cgroup skips.
The PR remains blocked until fresh required checks verify the committed correction on hosted Windows, Linux, and
macOS.
