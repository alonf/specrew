# Security Baseline Lens: Iteration 001

**Feature**: 159-update-ux-small-fixes  
**Lens Ref**: security-baseline@v1.0.0  
**Phase**: before-implement planning

## Planned Review

- Verify stale running Specrew cannot mutate a newer-baseline project.
- Verify refusal happens before update deploy scripts, template refresh, dependency installs, and config writes.
- Verify remediation does not direct users to unsafe downgrade paths.
- Verify no new network, credential, privilege, or package-install behavior is introduced by Tier 1.

## Runtime Evidence Needed

- Stale refusal test with deterministic protected-surface snapshot/no-mutation proof.
- Equal/newer pass-through regression.
- Changed-file scope review proving Proposal 160 and Feature 141 surfaces are not changed except for explicitly justified shared active-message wording.
