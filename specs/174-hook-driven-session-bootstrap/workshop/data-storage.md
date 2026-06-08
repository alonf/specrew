# Data Storage Intake Notes

```text
start-context.json / active-sessions.yml
        |
        v
Session Anchor --validates--> Project-local active feature
        |
        +--invalid if merged/closed/non-portable absolute path

SessionEnd -> Handover Record -> SessionStart reads if fresh and valid
```

Delegated intake decision: medium-depth data workshop is required for session
anchor validity, handover freshness, and path-portability behavior.
