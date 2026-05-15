# Quickstart: Velocity Dashboard Visual Richness + PoC-Parity Restoration

This quickstart describes the intended Feature 018 workflow after implementation lands.

## 1. Render the dashboard in default rich mode

```powershell
pwsh -NoProfile -File .\scripts\specrew.ps1 where
pwsh -NoProfile -File .\scripts\specrew.ps1 status
pwsh -NoProfile -File .\scripts\specrew-where.ps1
```

Expected behavior in a capable terminal:

- Rich rendering is used by default.
- Header shows both `Today: YYYY-MM-DD` and `Captured: <ISO timestamp>`.
- Active work uses the active-feature arrow.
- Recent Shipped uses denser bars and richer metadata.
- Velocity shows the sample basis and the only sparkline in the dashboard.
- Roadmap phases show status markers plus description lines.

## 2. Force monochrome / ASCII-safe fallback

```powershell
pwsh -NoProfile -File .\scripts\specrew.ps1 where --ASCII
pwsh -NoProfile -File .\scripts\specrew.ps1 where --no-color
```

Expected behavior:

- No ANSI emphasis is emitted.
- No Unicode-only primitives are required for comprehension.
- Meaning and section order remain equivalent to the rich view.

## 3. Override Recent Shipped density

```powershell
pwsh -NoProfile -File .\scripts\specrew.ps1 where --RecentCount 6 --BarWidth 28
pwsh -NoProfile -File .\scripts\specrew-where.ps1 --RecentCount 4 --BarWidth 20
```

Expected behavior:

- Default Recent Shipped count is `6`.
- Default rich-mode bar width is `28`.
- Overrides change density only; they do not alter the underlying shipped data.

## 4. Verify closeout snapshot behavior

Closeout scaffolds continue to write:

```text
specs/<feature>/iterations/<NNN>/dashboard.md
specs/<feature>/closeout-dashboard.md
```

Expected behavior:

- Stored snapshots remain historical and immutable.
- ANSI escape sequences are removed from stored Markdown.
- Unicode glyphs may remain in the stored snapshot.

## 5. Run validation targets

```powershell
pwsh -NoProfile -File .\tests\integration\feature-017-dashboard-core.ps1
pwsh -NoProfile -File .\tests\unit\feature-017-dashboard.tests.ps1
pwsh -NoProfile -File .\extensions\specrew-speckit\scripts\validate-governance.ps1 -ProjectPath .
pwsh -NoProfile -Command "if (Get-Command Invoke-ScriptAnalyzer -ErrorAction SilentlyContinue) { Invoke-ScriptAnalyzer -Path . -Recurse -IncludeDefaultRules }"
```

Verification targets:

- Existing Feature 017 dashboard tests remain green.
- New rich-mode and monochrome-mode fixtures prove additive behavior.
- Snapshot persistence proves ANSI stripping and Unicode preservation.
- Rendering stays within the 1.5 second budget on the representative 16-feature repository.

## 6. Manual review checklist

- Confirm rich mode appears only when the host is eligible.
- Confirm fallback is clean under `--ASCII`, `NO_COLOR`, `NO_UNICODE`, dumb-terminal, and redirected-output scenarios.
- Confirm the sparkline appears only in the Velocity section.
- Confirm roadmap description lines truncate only beyond 80 characters with `...`.
- Confirm fixture and stored artifact text remains UTF-8 without BOM and LF-terminated.
