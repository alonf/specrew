# Feature 019 Cross-Platform Backlog

**Status**: active-deferred  
**Source Decision**: T003 approved on 2026-05-16 for Feature 019 Iteration 001  
**Purpose**: Preserve explicit Iteration 002 work without widening the current Windows-first slice.

## Iteration 002 Deferred Items

| Deferred item | Why deferred | Impacted tasks / artifacts |
| --- | --- | --- |
| `.github/workflows/cross-platform-validation.yml` with `ubuntu-latest` matrix | T003 kept Iteration 001 on manual evidence rather than CI matrix setup | T040, Phase 5 workflow surfaces |
| macOS testing | Outside the approved Windows-first Iteration 001 lane | T040, T054, T055 |
| 104+ embedded-backslash sweep across existing PowerShell scripts | Broad Join-Path audit hardening would widen the current slice | T041, FR-030 follow-up |
| WSL Ubuntu end-to-end verification using Copilot CLI | Explicitly deferred by the T003 verdict | T040, research.md R4 |
| README + `docs/getting-started.md` cross-platform claims | Documentation should not outrun the deferred validation evidence | README.md, docs/getting-started.md |
| First real PSGallery publish | Iteration 001 only authorizes dry-run/manual-gate validation | T039, T055, release workflow evidence |

## Iteration 001 Guardrail

Do **not** implement backlog items from this file during Iteration 001 unless a new human decision explicitly re-authorizes them.
