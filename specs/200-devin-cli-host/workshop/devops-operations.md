# DevOps and Operations — Feature 200

```text
Pull request
    |
    +-- registry/manifest contract
    +-- multi-host launch contract
    +-- host-coupling firewall
    +-- generated host FileList parity
    +-- agents-block migration/idempotency
    |
    v
Prerelease package
    |
    +-- FileList-faithful install
    +-- one-run specrew update migration
    +-- real Devin smoke
    |     interactive start
    |     SessionStart bootstrap
    |     boundary Stop
    |     handover outcome
    v
Promote host status / stable release
```

## CI and Packaging

- Add registry, launch, firewall, generation parity, and migration checks explicitly to
  `.github/workflows/specrew-ci.yml`.
- Extend the existing prepublish FileList harness for generated host-package membership.
- Test absent, legacy three-host, partial, and current managed agents blocks.
- Prove migration and generation are idempotent.
- Exercise generic path and argument behavior on Windows and at least one Unix environment.

## Rollout

- Initial Devin status: `experimental`.
- Promotion to `supported` requires prerelease evidence from the actual CLI:
  - interactive `specrew start`;
  - SessionStart bootstrap;
  - boundary Stop behavior;
  - the handover behavior selected by the transcript spike.
- Rollback changes manifest status to `experimental` or `deferred`. No core host branch.

## Documentation and Proposal Scope

Feature 200 updates:

- README and user-facing host documentation.
- Host architecture and add-a-host guidance.
- Changelog/release notes.
- Relevant test documentation.
- Proposal 194 so future monitoring includes Devin and derives host inventory from registry
  or manifest metadata.

Feature 200 does not implement Proposal 187/194's scheduled monitor.

General arbitrary-version update convergence is recorded as a separate proposal/PR
follow-up and is not authored in this feature.
