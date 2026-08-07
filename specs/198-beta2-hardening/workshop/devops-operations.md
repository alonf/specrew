# Workshop Record: devops-operations (medium)

**Feature**: 198-beta2-hardening
**Date**: 2026-07-09
**Confirmation**: human-confirmed ("Agree with all recommendations")

## Promotion topology (agreed)

```text
  SELF-HOST (GitHub, PR-protected main)            CONSUMER PROJECT (via init/update)
  ─────────────────────────────────────            ─────────────────────────────────
  PR lanes: Test · Specrew CI ·                    DEPLOYED (consumer-ized):
   Cross-Platform · SelfLeakLintLane (NEW,          specrew-methodology-gate.yml (NEW)
   blocking in OUR repo, lands iter 001)             = markdownlint (F-033 ignore set)
        │ merge to main                                + validator at DEPLOYED path
        ▼                                              + PSSA if *.ps1 exist
  tag v0.40.0-beta2  (no-dot form)                   triggers: main + [0-9][0-9][0-9]-*
        │ tag-push workflow                          posture: ADVISORY-FIRST (F-182)
        ▼                                          specrew-work-kind.yml (path-fixed)
  AUTO-PUBLISHES prerelease → PSGallery            NO LONGER deployed: deterministic-gate,
        │  (credentials doc fix in scope)           project-sync, confidence-lane
        ▼                                            → move to .github/workflows/ (204-W3)
  fresh consumer E2E on published bits             HEAL on update: retired templates
        │ maintainer manual PASS                    removed hash-guarded (204-W5),
        ▼                                           refocus-scopes.json synced (#2903)
  stable 0.40.0 promotion (separate, stays held)
```

## D1 — Gateway wiring (decided)

- **Validator scope on PRs**: FULL run of the deployed
  `validate-governance.ps1` (consumer projects are small; cheap). 087-style
  changed-iterations scoping is a later optimization under its own proposal.
- **Who gets the gateway**: keyed off the RECORDED provider (204-W7 makes
  init record it in repository-governance.yml): provider `github` or unset →
  deploy; explicitly non-GitHub → skip and name the manual validator path
  (`Invoke-SpecrewWorkKindValidation`). Never silently hand a GitHub Actions
  file to a non-GitHub project (FR-024). No remote-sniffing at init.
- **Action pins in shipped templates**: pin by major
  (`actions/checkout@v4`-style); pins ride the `specrew update` heal surface
  for refresh. Dependabot-style automation out of this slice.
- **Posture**: advisory-first per F-182 doctrine — deterministic hard-fails
  may block, warnings never; graduation to blocking is team opt-in; the
  README/user-guide states the posture explicitly (204 risk note).

## D2 — Surgery + bootstrap-commit posture (decided)

- Template removal on consumer update: AUTOMATIC, content-hash-guarded
  (F-116 pattern). Byte-identical retired template → removed; user-modified →
  left in place with a WARN naming it retired. Never delete user content.
- W5b bootstrap commit: greenfield → auto-commit
  `chore(specrew): bootstrap scaffold` at init end; brownfield → explicit
  offer, never auto-commit into existing history. Every future review/feature
  diff gets a clean baseline from minute one.

## D3 — Release mechanics for beta2 (decided)

- Tag `v0.40.0-beta2` (no-dot), ModuleVersion stays `0.40.0`,
  `Prerelease = 'beta2'` in Specrew.psd1.
- The release bookkeeping checklist becomes a PRE-TAG DETERMINISTIC CHECK
  (not a memory item): extensions/specrew-speckit/extension.yml + its
  .specify mirror + .specify/extensions.yml + .specrew/config.yml
  specrew_version + CHANGELOG + README + psd1 FileList — verified via
  validate-versions.ps1 (extended if it does not cover all seven) BEFORE the
  tag is pushed. (Beta1 dry-run lesson: a missed manifest.)
- The tag-push workflow AUTO-PUBLISHES prereleases;
  docs/operations/psgallery-release-credentials.md gets rewritten to describe
  the auto-publish reality (maintainer-sanctioned in-scope doc fix).
- Stable 0.40.0 promotion stays a separate maintainer PASS after a fresh
  consumer E2E on published beta2 bits.
