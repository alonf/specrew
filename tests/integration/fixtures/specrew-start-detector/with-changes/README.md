# Test Fixtures: Session-Loaded File Changes

This directory contains test fixtures for scenarios where session-loaded files have changed between runs.

## Scenarios

- **agent-change**: Committed change to `.github/agents/squad.agent.md`
- **charter-change**: Committed change to `.squad/agents/*/charter.md`
- **copilot-instructions-change**: Committed change to `.github/copilot-instructions.md`
- **extension-template-change**: Committed change to `extensions/specrew-speckit/squad-templates/coordinator/*`
- **mixed-changes**: Multiple session-loaded files changed in one commit

## Usage

Tests should:

1. Initialize a git repository
2. Create initial bootstrap state with session-loaded files
3. Commit baseline
4. Run specrew-start (creates `.specrew/last-start-prompt.md` with baseline hash)
5. Modify session-loaded file(s) and commit
6. Run specrew-start again
7. Verify pause-and-confirm directive is injected with file list
