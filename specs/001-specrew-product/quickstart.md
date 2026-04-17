# Quickstart: Specrew

## Prerequisites

- Python 3.11+ with [uv](https://docs.astral.sh/uv/)
- Node.js 18+
- Git
- GitHub Copilot access (via Squad)

## 1. Install Specrew

```bash
# Install the Specrew CLI (installs Spec Kit and Squad if missing)
pip install specrew
```

## 2. Initialize a Project

```bash
# In your project directory
specrew init
```

This will:
- Detect/install Spec Kit (>= 0.7.3) and Squad (>= 0.9.1)
- Create `.specrew/` with governance artifacts
- Configure 5 baseline roles in your Squad team
- Report what was created

## 3. Write a Spec

Use Spec Kit's normal workflow:

```bash
# Create a feature spec
/speckit.specify "Build a REST API for user management"
```

## 4. Start an Iteration

With your spec written, start an iteration:

1. The **Planner** reads your spec requirements and generates an iteration plan
2. You review and approve the plan
3. The crew executes tasks, with drift-check running after each task
4. The **Reviewer** runs the Review/Demo ceremony with per-task verdicts
5. The **Retro Facilitator** runs the Retrospective

## 5. Check Iteration Artifacts

All artifacts are in your spec directory:

```
specs/001-your-feature/iterations/001/
├── plan.md        # Tasks with requirement links and effort
├── state.md       # Execution progress (for resume)
├── drift-log.md   # Any detected drift events
├── review.md      # Per-task verdicts
└── retro.md       # Estimation accuracy, learnings, actions
```

## 6. Resume After Interruption

If the crew stops mid-iteration:

```
# The iteration-resume skill picks up from the last completed task
# State is persisted in state.md after each task
```

## Key Concepts

- **The spec is authoritative** — agents cannot silently override it
- **Every task traces to a requirement** — no orphan work
- **Drift is caught per-task** — not just at the end
- **Five baseline roles**: Spec Steward, Planner, Implementer, Reviewer, Retro Facilitator
- **Your project, your governance** — the downstream constitution is yours to customize
