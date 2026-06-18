# Requirements NFR Lens: Iteration 002

**Depth**: medium  
**Confirmation**: human-confirmed / lens-question

## Binding Requirements

- Persistent instruction deployment occurs during `specrew init` for every
  supported host with a manifest-declared `InstructionsFile`.
- Instruction file paths come from host manifest `InstructionsFile`, including
  host-specific surfaces beyond `AGENTS.md` such as `CLAUDE.md` and
  `.github/copilot-instructions.md`.
- User-owned content survives unchanged outside the Specrew-owned section after
  init, update, and start-heal/refresh.
- The exact anti-raw-`specify.exe workflow` guard appears in persistent
  instructions and bootstrap.
- Bootstrap starts with the immediate next Specrew action before broader
  explanatory context.
- The packaged template/helper are included in `Specrew.psd1` `FileList`, and
  `specrew update` refreshes the managed section.
- Host-coupling firewall stays green; shared core reads manifest data and does
  not hardcode Antigravity or `agy` paths.
- Opus 4.6 and Gemini Flash real-host evidence gates the full parity claim.
- Feature-closeout, beta, stable, and release claims remain blocked.

## Quality Table

```text
Quality / constraint          Required threshold
----------------------------  -----------------------------------------------
Durability                    After specrew init, every supported host with
                              InstructionsFile has a persistent Specrew block.
Non-clobbering safety         Existing user content outside the Specrew block
                              survives init/update/start-heal unchanged.
Host neutrality               Shared core reads InstructionsFile from manifests;
                              no Antigravity/agy path literals in shared core.
Prompt focus                  Persistent file and bootstrap both carry the exact
                              coordinator + anti-raw-specify.exe workflow guard.
Bootstrap speed               Immediate next lifecycle action appears before
                              broad explanatory context.
Package/update correctness    Template/helper are shipped in FileList and
                              update refreshes the managed section.
Evidence honesty              Opus/Flash evidence gates parity; Flash failure
                              keeps an explicit weak-model caveat.
Boundary discipline           No feature-closeout, beta, stable, or release
                              claim in iteration 002.
```

## Acceptance Diagram

```text
init deploy proof
    + merge preservation
    + exact guard
    + manifest path
    + firewall
    + package/update/start-heal proof
        |
        v
real-host proof
    + Opus speed
    + Flash workshop/no raw workflow
        |
        v
full parity caveat can be removed only if evidence supports it
```
