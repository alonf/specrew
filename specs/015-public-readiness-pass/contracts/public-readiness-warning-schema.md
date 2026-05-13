# Contract: validate-governance.ps1 Public-Readiness Soft-Warning Interface

**Feature**: 015 Public-Readiness Pass  
**Requirement**: FR-016  
**Date**: 2026-05-13

---

## Overview

`validate-governance.ps1` exposes a soft-warning output contract for public-readiness surface
checks. This contract defines what callers and consumers (CI scripts, human operators, downstream
tooling) can rely on when the new `Test-PublicReadinessSurfaces` function is added.

---

## Contract

### Function Signature (PowerShell)

```powershell
function Test-PublicReadinessSurfaces {
    param(
        [Parameter(Mandatory)]
        [string]$ProjectRoot
    )
    # Returns: [void]
    # Side effects: Writes WARN lines to stdout via Write-Host -ForegroundColor Yellow
    # Never throws; never calls exit; never sets $hasFailures = $true
}
```

### Output Schema

Each soft warning is emitted as a single line with the following structure:

```
WARN [public-readiness] <category>: <detail>
```

| Token | Values | Notes |
| --- | --- | --- |
| `WARN` | literal `WARN` | Distinct from `FAIL` used by hard-failure paths |
| `[public-readiness]` | literal namespace | Allows output filtering by namespace |
| `<category>` | `missing-artifact` / `stale-version-in-readme` | Extensible in future |
| `<detail>` | relative file path or description string | Human-readable; not machine-parsed |

### Warning Conditions

| Condition | Category | Detail Example |
| --- | --- | --- |
| `LICENSE` does not exist at project root | `missing-artifact` | `LICENSE` |
| `NOTICE.md` does not exist at project root | `missing-artifact` | `NOTICE.md` |
| `CHANGELOG.md` does not exist at project root | `missing-artifact` | `CHANGELOG.md` |
| `docs/versioning.md` does not exist | `missing-artifact` | `docs/versioning.md` |
| `README.md` does not contain any version string matching `\b0\.\d+\.\d+\b` | `stale-version-in-readme` | `README.md does not contain a version string` |

### Exit Code Contract

- **Exit code 0** — all iteration governance checks pass AND (zero or more soft warnings only)
- **Exit code 1** — at least one hard governance failure exists (unchanged from pre-feature behaviour)
- Soft warnings from `Test-PublicReadinessSurfaces` MUST NOT contribute to exit code 1

### Invocation Context

`Test-PublicReadinessSurfaces` is called unconditionally at the start of the main validation
function, before iteration-level checks. It runs on every `validate-governance.ps1` invocation
regardless of which iteration paths are targeted.

---

## Stability Guarantee

This is an **additive soft-warning contract**. Implementations MUST:

1. Never change existing hard-failure exit codes or structured-failure message formats
2. Never suppress an existing `FAIL` line in favour of a `WARN` line
3. Never emit `WARN [public-readiness]` lines from the hard-failure paths
4. Remain additive — additional warning categories may be added in future features without
   breaking existing callers (new categories are opt-in for downstream consumers)

---

## Consumer Guidance

- **CI scripts** filtering for `FAIL` will not see new `WARN` lines as failures (correct)
- **Human operators** reviewing validator output can filter `WARN \[public-readiness\]` to see
  all public-readiness drift warnings in one scan
- **Downstream tooling** treating exit code 1 as a hard block will not be affected (correct)
- **Future features** extending the public-readiness check should use the same namespace
  `[public-readiness]` and follow the `<category>: <detail>` format

---

## Reference Implementation Sketch

```powershell
function Test-PublicReadinessSurfaces {
    param(
        [Parameter(Mandatory)]
        [string]$ProjectRoot
    )

    $required = @(
        'LICENSE',
        'NOTICE.md',
        'CHANGELOG.md'
    )
    foreach ($file in $required) {
        $path = Join-Path $ProjectRoot $file
        if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
            Write-Host "WARN [public-readiness] missing-artifact: $file" -ForegroundColor Yellow
        }
    }

    $versioningPath = Join-Path $ProjectRoot 'docs' 'versioning.md'
    if (-not (Test-Path -LiteralPath $versioningPath -PathType Leaf)) {
        Write-Host 'WARN [public-readiness] missing-artifact: docs/versioning.md' -ForegroundColor Yellow
    }

    $readmePath = Join-Path $ProjectRoot 'README.md'
    if (Test-Path -LiteralPath $readmePath -PathType Leaf) {
        $readmeContent = Get-Content -Path $readmePath -Raw -Encoding UTF8
        if ($readmeContent -notmatch '\b0\.\d+\.\d+\b') {
            Write-Host 'WARN [public-readiness] stale-version-in-readme: README.md does not contain a version string' -ForegroundColor Yellow
        }
    }
}
```

---

## Traceability

- **FR-016** — public-readiness surfaces checked on every `validate-governance.ps1` invocation
- **NFR-005** — soft warning only; not a hard blocker
- **SC-007** — drift surfaced at any normal lifecycle gate, not only at feature closeout
