# Implementer decision — F-023 workflow hotfix

- **Feature**: 023-legacy-state-read-tolerance
- **Decision**: `workflow_dispatch` real publish modes now treat a non-empty `release_tag` as an idempotent lightweight-tag contract: fetch tags first, create-and-push the tag only when absent, and fail closed if an existing tag resolves to a different commit than the checked-out SHA.
- **Why it matters**: prerelease publish, stable publish, and prerelease promotion must all release the exact reviewed commit while staying safe against accidental tag drift. The same release context now also drives GitHub Release creation for every real tag-based publish path, with `--prerelease` reserved for prerelease publishes and `--latest` for stable baselines/promotions.
