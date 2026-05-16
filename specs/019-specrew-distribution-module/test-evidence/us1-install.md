# US1 Install Evidence

**Iteration**: 001  
**Scope**: Windows-first proxy evidence only  
**Status**: implemented and validated; first live PSGallery install remains pending the manual publish gate

## Evidence Summary

1. **Manifest validity / importability**
   - Command: `Test-ModuleManifest .\Specrew.psd1`
   - Result: `Name=Specrew`, `Version=0.18.0`, `PowerShellVersion=7.0`, `CompatiblePSEditions=Core`
   - Command: `Import-Module .\Specrew.psd1 -Force`
   - Result: import succeeded; only the expected unapproved-verb warning surfaced

2. **Exported command surface**
   - Command: `Get-Command -Module Specrew`
   - Result: `specrew`, `specrew-init`, `specrew-review`, `specrew-start`, `specrew-team`, `specrew-update`, `specrew-where`

3. **CLI catalog**
    - Command: `Import-Module .\Specrew.psd1 -Force; specrew help`
    - Result: help output listed `init`, `start`, `review`, `where`, `status`, `update`, `team`, and `help`

4. **Fresh-directory bootstrap from a manifest-shaped bundled module**
    - Command: `pwsh -NoProfile -ExecutionPolicy Bypass -File .\tests\integration\distribution-module-init.ps1`
    - Result: PASS
    - Package proof: the test stages its scratch module from `Specrew.psd1` `FileList`, so the installed-module evidence now matches the shipped package surface
    - Verified artifacts:
      - `.specify\templates\spec-template.md`
      - `.squad\identity\now.md`
      - `.squad\decisions.md`
      - `.github\agents\squad.agent.md`
     - `.github\workflows\specrew-ci.yml`
     - `.specrew\config.yml`

## Iteration 001 Truth Note

- The feature now has a packaged module, importable command surface, and installed-module bootstrap proof captured against the manifest-shaped package surface.
- A real `Install-Module Specrew -Scope CurrentUser` run cannot be claimed yet because Iteration 001 explicitly avoids the first live PSGallery publish.
- Human-owned follow-up for the first live install path remains in T042/T053.
