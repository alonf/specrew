# Contract: Managed-Skill Preserving Guard Public Surface

**Feature**: 161-managed-skill-preserving-guard
**Stability**: pre-1.0 (internal deploy contract)

## deploy-squad-runtime.ps1 — managed/preserve classification

The deploy script's legacy-cleanup classification is the contract under
investigation. Its observable surface is the deployment-action vocabulary and
the resulting disk state, not an exported function signature.

### Exported API (behavioral)

| Symbol | Signature | Purpose | Errors |
| --- | --- | --- | --- |
| `Test-IsManagedLegacySkillDirectory` | `(SkillDirectoryPath, Definition): bool` | Decide managed (safe to remove/refresh) vs user-edited (preserve) for a legacy `.copilot/skills/specrew-*` dir | never throws on missing/empty `SKILL.md` (returns false) |
| `Set-ManagedFile` | `(TargetPath, Content, Actions): void` | Create/overwrite a managed file; records `created`/`updated`/`preserved` | filesystem errors propagate |
| `Get-ManagedSkillMarkerContent` | `(SkillDirectory): string` | Canonical `.specrew-managed` sidecar content (`schema: v1`, `owner: specrew`, `kind: project-skill`, `directory: <name>`) | none |
| Deploy action record | list of `{Action, Path}` | The harness's assertion surface | n/a |

### Invariants (contract this feature must uphold)

- **I1 — Provenance wins**: a directory with a `.specrew-managed` marker is
  always classified managed.
- **I2 — User data is never lost**: a genuinely user-authored directory (no
  marker, content never canonical) is always preserved — pre-fix, post-fix,
  and refuted-no-fix (FR-005 / SC-003).
- **I3 — Active roots stay current**: every deploy writes current canonical
  `SKILL.md` + marker into all active skill roots (`.claude/skills`,
  `.cursor/rules`, `.github/skills`, `.agents/skills`).
- **I4 — Idempotency**: an immediately repeated deploy run reports
  preserved/no-change for managed surfaces.
- **I5 — F-160 compatibility**: exact-current-canonical content without a
  marker remains classified managed; all existing
  `managed-runtime-sidecar.tests.ps1` assertions keep passing.
- **I6 — Conditional change only**: classification behavior changes ship only
  with a CONFIRMED verdict; source and `.specify` mirror stay in parity when
  they do.

## New test surface introduced by this feature

| Artifact | Contract |
| --- | --- |
| `tests/integration/managed-skill-stuck-preserving.tests.ps1` | Standalone `pwsh` harness; exit 0 = all assertions pass; exit 1 with FAIL lines otherwise; zero writes outside its temp sandbox; deterministic across runs |
