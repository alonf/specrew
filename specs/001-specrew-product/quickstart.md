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
- Detect/install Spec Kit (>= 0.8.4) and Squad (>= 0.9.1)
- Create `.specrew/` with governance artifacts
- Configure 5 baseline roles in your Squad team
- Report what was created

## 3. Start a Feature Run

Use Specrew's guided entrypoint:

```bash
# Start Squad in guided intake/resume mode
specrew start

# Optional shorthand: start a new feature from a plain-language request
specrew start "Build a REST API for user management"
```

This should:

- Hand off to Squad as the active coordinator
- Have Squad drive the Spec Kit lifecycle: `specify`, `clarify` when needed, `plan`, `tasks`, `implement`
- Ask you only the questions Squad cannot safely resolve from repo context and existing artifacts
- Continue through implementation once the spec/design is clear enough
- Launch Copilot from the project root and default to non-blocking approvals unless you explicitly opt into prompt-based approvals

## 4. Let Squad Drive the Lifecycle

With `specrew start`, the intended lifecycle is:

1. The **Spec Steward / Squad** continues any in-progress feature when one already exists, or gathers the next feature/fix intake when none is active
2. Squad runs clarification only when needed, answering what it can itself
3. The **Planner** produces the implementation plan and task set
4. The **Implementer** executes the work
5. The **Reviewer** runs the Review/Demo ceremony with per-task verdicts
6. The **Retro Facilitator** runs the Retrospective

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

## 6. Start the Next Feature

When you want another feature, run `specrew start` again. You can provide the next plain-language request immediately or let Squad gather it interactively. The same Spec Kit lifecycle begins again for the new feature or fix.

## 7. Resume After Interruption

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
