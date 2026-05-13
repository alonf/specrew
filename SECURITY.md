# Security Policy

## Reporting a vulnerability

Specrew is alpha software. If you discover a security issue:

1. **Do not open a public issue.**
2. Open a private security advisory: this repository's **Security** tab → **Report a vulnerability**.
3. Alternatively, email Alon Fliess at <alonfliess@gmail.com>.

Please include:

- A description of the issue and where it lives in the codebase (file paths, ideally with line numbers)
- Reproduction steps or a minimal example
- The impact you observed
- Any mitigation you've already tried

## Response cadence

Specrew is maintained by a single developer. Target cadence:

- Acknowledgement: within 1 week
- Initial assessment: within 2 weeks
- Fix or coordinated disclosure plan: depends on severity

Specrew is not yet recommended for production. Security issues are taken seriously, but threat-model coverage is still maturing.

## Scope

**In scope:**

- `scripts/specrew.ps1`, `scripts/specrew-init.ps1`, `scripts/specrew-start.ps1`
- `extensions/specrew-speckit/scripts/*` (validators, governance helpers)
- `.specify/scripts/*` (vendored Spec Kit scripts — coordinate with upstream for shared issues)
- Generated install / bootstrap flows that touch the user's file system

**Out of scope** (unless Specrew bundling introduces the issue):

- Third-party dependencies (PowerShell, Pester, etc.) — report to those projects
- Upstream [Spec Kit](https://github.com/github/spec-kit) and [Squad](https://github.com/bradygaster/squad) vulnerabilities — report to those projects
- AI-model behavior of the underlying Claude / Codex / GitHub Copilot agents — report to the respective providers

## Disclosure policy

Coordinated disclosure preferred. Once a fix lands, we credit the reporter (with permission) in the `CHANGELOG.md` entry.
