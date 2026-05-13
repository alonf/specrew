---
name: "public-readiness-release-review"
description: "Review release-truth and additive public-readiness governance changes without confusing tag objects, warning lanes, or closeout guidance."
domain: "review"
confidence: "high"
source: "earned"
tools:
  - name: "view"
    description: "Read the version surfaces, coordinator guidance, and review artifacts."
    when: "When verifying release truth across docs, config, and iteration artifacts."
  - name: "rg"
    description: "Find tag commands, force flags, and closeout-rule text quickly."
    when: "When checking for destructive tag handling or incomplete version-management wording."
  - name: "powershell"
    description: "Run validator lanes and git tag verification commands."
    when: "When additive-warning behavior and local/origin tag anchors need live proof."
---

## Context

Use this when a feature changes versioning surfaces, retroactive changelog/tag history, public-readiness validator warnings, or future closeout governance. The review question is not just whether the docs read well; it is whether every release-truth surface and every validator lane tells the same story without rewriting history or promoting advisory checks into blockers.

## Patterns

- Start from `.specrew\config.yml` as the source of truth, then verify `README.md`, `docs\versioning.md`, `CHANGELOG.md`, the product/spec status surface, and annotated tags all mirror that same version.
- Verify annotated tags with peeled refs, not just tag names: use local `git for-each-ref` plus remote `git ls-remote --tags origin refs/tags/<tag> refs/tags/<tag>^{}` and compare the peeled commit to the required ship anchor.
- Search the reviewed surfaces for `--force`, `--force-with-lease`, or equivalent destructive rewrite language. Accept duplicate-tag handling only when it fails or stays advisory; never accept a review that rewrites existing tags.
- Prove additive validator behavior with four lanes together: clean fixture pass with no warnings, drift fixture pass with soft warnings, a pre-feature live iteration pass unchanged, and repo-wide validator green.
- For future-closeout guidance, require explicit enumeration of the release-bookkeeping steps: config bump, changelog update, README/versioning refresh, release-tag creation, validator rerun, and the keep-open defer path.

## Examples

- `extensions\specrew-speckit\scripts\validate-governance.ps1`
- `tests\unit\fixtures\015-public-readiness-pass\public-readiness-clean\`
- `tests\unit\fixtures\015-public-readiness-pass\public-readiness-drift\`
- `docs\versioning.md`
- `CHANGELOG.md`

## Anti-Patterns

- Treating the tag-object SHA as the release anchor instead of the peeled commit.
- Accepting repo-wide validator green as proof that a new warning lane is additive.
- Clearing closeout guidance that says only "sync versioning" without naming the concrete release steps.
- Allowing any `--force`-style tag creation or rewrite behavior in a historical release workflow.
