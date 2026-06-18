# DevOps Operations Lens: Iteration 002

**Depth**: medium  
**Confirmation**: human-confirmed / lens-question

## Decision

Deployment happens through three operational paths:

1. `specrew init` deploys persistent instruction files for all supported host
   manifests.
2. `specrew update` refreshes the managed section from the packaged template.
3. `specrew start` may heal/refresh the file, but is not the only deployment
   path.

Validation happens in two lanes:

1. Scratch-project init/update/start-heal tests prove persistent instruction
   deployment, merge preservation, idempotency, package FileList inclusion, and
   host-manifest location use.
2. Real-host Antigravity tests prove the model behavior improvement on Opus 4.6
   and Gemini Flash.

## Diagram

```text
Package/source lane
  Specrew.psd1 FileList
      |
      +--> instruction template/fragment included
      +--> deploy helper included
      |
      v
Operational lane
  scratch project
      |
      v
  specrew init
      |
      +--> AGENTS.md / CLAUDE.md / copilot instructions created or merged
      +--> user content preserved
      +--> specrew update refreshes managed section
      +--> specrew start heals/refreshes if needed
      +--> host-coupling firewall green

Manual lane
  real Antigravity
      |
      +--> Opus 4.6 time-to-workshop
      +--> Gemini Flash workshop/no raw workflow
```

## Release Boundary

No push, PR, beta, stable, or feature-closeout work belongs to iteration 002.
Those remain later explicit gates.
