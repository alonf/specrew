---
description: "Closeout template for completed feature work"
---

# Feature Closeout

## Summary

- What shipped
- What remains for human follow-up
- Validation evidence

## State schema / fixture maintenance

- If this feature modified any state file schema, add a legacy fixture for the current Specrew version to `tests/fixtures/legacy-versions/`.
- Prefer hand-curated fixtures when historical drift or missing fields matter.
- Prefer generated fixtures when the contract is deterministic and easy to reproduce.
- Prefer snapshot-based fixtures when the real lifecycle output is the behavior under review.

## Follow-up

- Documentation updates
- Human approvals
- Release notes
