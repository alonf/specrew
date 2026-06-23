# Code & Implementation — Feature 200

## Source and stack

The implementation style follows this repository's existing host packages, adjacent PowerShell scripts, and PowerShell integration tests. The resolved stack is PowerShell 7 with PSD1 manifests, YAML/JSON managed data, and GitHub Actions. No new runtime or test dependency is approved.

```text
Repository host examples + shared-core patterns
                     |
                     v
       implementation-rules.yml
          /          |          \
         v           v           v
 hosts/devin/   generic core   tests + CI
 package        cleanup only   deterministic proof
         \           |           /
          +----------+----------+
                     |
                     v
       folder-only extensibility evidence
```

## Binding implementation posture

- Use the existing manifest plus five-handler functional host contract.
- Keep `hosts/_registry.ps1` as the canonical runtime catalog.
- Derive FileList and managed coordinator configuration as projections, not additional catalogs.
- Use registry queries and manifest capabilities instead of host-name switches or enums.
- Add only generic mechanisms that are required by the confirmed design: coordinator eligibility, deterministic host-package generation, registry-driven migration, direct event-map hook configuration, and firewall purity.
- Preserve user-owned hook and instruction content and reject unsafe rewrites.
- Keep transcript/export evidence bounded and redact conversation content and credentials.
- Do not edit `scripts/internal/bootstrap/ConversationCaptureAccessor.ps1`; unsupported transcript shapes remain deferred Slice B work.
- Require deterministic integration coverage plus prerelease real-host Devin evidence.

## Dependencies

Use existing project tools and add no dependency.

## Confirmation

Human-confirmed for the lens question on 2026-06-24. The maintainer confirmed the repository baseline and proposed implementation posture without changes.
