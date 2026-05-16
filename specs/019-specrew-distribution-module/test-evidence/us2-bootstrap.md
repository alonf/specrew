# US2 Bootstrap Evidence

**Iteration**: 001  
**Scope**: Windows-first installed-module behavior  
**Status**: validated

## Evidence Summary

1. **Installed-module bootstrap**
   - Command: `pwsh -NoProfile -ExecutionPolicy Bypass -File .\tests\integration\distribution-module-init.ps1`
   - Result: PASS
   - Coverage:
     - `specrew init` succeeds from an installed-module layout
     - rerunning `specrew init` preserves existing `.specify`, `.squad`, and `.github` surfaces
     - bootstrap now includes `.github\agents\squad.agent.md`, which `specrew start` requires

2. **Lifecycle handoff from installed module**
   - Manual evidence command: import the scratch module produced by `distribution-module-init.ps1`, put a fake `copilot.cmd` on `PATH`, then run:
     - `specrew-start -ProjectPath .scratch\distribution-module-init\project "Validate installed module start flow"`
   - Result:
     - Specrew wrote `.specrew\last-start-prompt.md`, `.specrew\start-context.json`, and `.specrew\start-summary.md`
     - the fake Copilot log captured `--agent Squad`, `.specrew\last-start-prompt.md`, `.specrew\start-context.json`, and `--allow-all`

3. **Broader lifecycle behavior**
   - Command: `pwsh -NoProfile -ExecutionPolicy Bypass -File .\tests\integration\start-command.ps1`
   - Result: PASS
   - Coverage:
     - intake/resume prompt generation
     - same-window launch behavior
     - delegated routing serialization
     - fallback reporting and prompt-approval handling

## Bounded Repair Captured During Final Validation

- Final validation exposed that the bundled GitHub template tree did not include `.github\agents\squad.agent.md`.
- Repair applied inside Iteration 001:
  - added `templates\github\agents\squad.agent.md`
  - extended `specrew-init` bootstrap validation to require the coordinator prompt
  - updated `tests\integration\distribution-module-init.ps1` to keep this path under regression coverage
