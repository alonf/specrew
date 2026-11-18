# Problem-side gap list (FR-020): input for iteration 002

**Feature**: 205-workshop-lens-order | **Iteration**: 001 | **Written by**: T006 (tagging pass), 2026-11-10

This list was written while each lens's questions were tagged by space. It records the problem-space questions each
lens does not ask. No question was added or reworded in iteration 001, apart from the three approved splits (S1 to
S3) and the FR-004 move. Iteration 002 (problem-space completeness) has its own short workshop, where the maintainer
decides between adding new questions and adding a new lens.

| Lens | Space | Problem questions it asks now | Problem-side gaps seen |
| --- | --- | --- | --- |
| product-domain | problem | 8 areas (users, pain, context, constraints, outcomes, MVP, alternatives, adoption) | none seen |
| requirements-nfr | problem | design-driving NFRs, mandatory constraints, measurable thresholds, unknowns, acceptance criteria, scope | regulatory and compliance NFRs are not asked directly (they appear only in the question bank) |
| ui-ux | both | source of UX truth; primary journeys and recovery paths; accessibility, localization, RTL, theming and regulatory constraints | who the UI's users are (skills, devices, context of use): there are journeys but no personas |
| security-compliance | both | what data is sensitive (S1); which actions need audit records | which regulation or compliance regime applies; data residency; who the threat actors are |
| data-storage | both | whether persistent storage is required; what owns each data type; how retention is handled (S2) | what data exists; how sensitive it is; how much there is and how fast it grows; what must be carried over from an existing system (the maintainer's example) |
| integration-api | both | what owns the contract (S3) | which outside systems exist and which of their contracts must be honoured; those systems' limits, quotas and SLAs |
| devops-operations | both | which environments must be equivalent; what users, roles, service identities and permissions are needed | where it must run (platform constraints, as distinct from the hosting model chosen); who operates it, and when; the budget |
| architecture-core | solution | none (binding constraints and scope moved to requirements-nfr) | n/a (solution lens; its drivers come from the problem lenses) |
| component-design | solution | none | n/a (solution lens) |
| observability-resilience | solution | none | what operators need to diagnose; SLO and alerting expectations. Also the problem halves of two bullets ruled solution at the plan verdict: "What errors are expected, and which are exceptional?" (the domain's failure modes) and "What is the cost of observability, and what should not be logged?" (the observability budget, and data that must never be logged) |
| code-implementation | solution | none | n/a (solution lens) |

## Also carried to iteration 003

The plan verdict accepted that lists written with short names rather than lens ids fall outside the id sweep. These
are the skill's frontmatter description ("requirements/NFR, ui-ux, security, data, ...", reordered by hand in 001),
launch-contract rule 9a, and the reviewer prompt's lens list in
`scripts/internal/continuous-co-review/worktree-reviewer.ps1`. That last one was restored to origin/main at the
maintainer's direction (feature 203's folder) and is exempted in the parity test. Iteration 003 takes them as input.

Also for iteration 003: after feature 203 merges, reorder the comment at
`scripts/internal/continuous-co-review/review-signoff-evidence-gate.ps1:589` to index.yml order and remove its
temporary exemption from `tests/unit/lens-order-parity.tests.ps1`.
