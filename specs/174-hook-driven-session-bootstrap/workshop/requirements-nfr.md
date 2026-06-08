# Requirements NFR Intake Notes

```text
Priority order
1. Compatibility: specrew start remains supported
2. Idempotency: launcher + hook does not double-bootstrap
3. Reliability: direct launch works across hook-bound hosts
4. Scope control: B1/B3 unchanged; B4/Antigravity deferred
```

Delegated intake decision: medium-depth NFR workshop is required because the
feature is a posture and reliability change more than a new user command.
