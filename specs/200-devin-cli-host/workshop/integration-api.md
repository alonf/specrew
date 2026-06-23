# Integration and API — Feature 200

```text
specrew start --host devin
          |
          v
New-DevinLaunchInvocation
          |
          | interactive positional bootstrap prompt
          v
       devin CLI
          |
          +--------------------+
          |                    |
          v                    v
.devin/hooks.v1.json      AGENTS.md / skills / agents
direct event map
          |
          +-- SessionStart
          +-- UserPromptSubmit
          +-- Stop
          |
          v
Shared Specrew dispatcher
          |
          +-- DEVIN_PROJECT_DIR project resolution
          +-- decision-block Stop response
          +-- bounded handover ladder

Automation-only:
  devin -p <canary prompt> [--export <controlled path>]
```

## Launch Contract

- `specrew start` remains supported and must launch Devin.
- Normal sessions use interactive mode with the bootstrap prompt as positional input.
- `devin -p` is reserved for smoke tests and scheduled canaries.
- `--continue` and `--resume` are not added now because the existing host launch contract
  has no session-resume input.

## Hook Contract

`.devin/hooks.v1.json` stores the lifecycle event map at the root. Feature 200 adds a
generic manifest-driven `direct-event-map` config shape to the shared deployer.

Declared integration:

- Events: `SessionStart`, `UserPromptSubmit`, `Stop`.
- Project root: `DEVIN_PROJECT_DIR`.
- Stop blocking: existing `decision-block` envelope.
- The spike verifies context output behavior and the complete live Stop payload.

## Other Surfaces

- Instructions: `AGENTS.md`.
- Skills: `.devin/skills/`; `.agents/skills/` is also supported by Devin.
- Subagents: `.devin/agents/<name>/AGENT.md`.
- Conversation export: ATIF via `--export`.
- Spec Kit manifest value: `devin`; generic version-aware flag selection remains Proposal
  198 ownership.

The installed CLI's legacy `.windsurf/rules/` output is not adopted. Specrew targets the
current documented `AGENTS.md` and `.devin/` contracts.
