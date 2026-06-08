# Architecture Core Intake Notes

```text
Direct host launch
        |
        v
+----------------------+       +---------------------------+
| SessionStart hook B2 | ----> | Bootstrap provider        |
| F-171 dispatcher     |       | emits agent directive     |
+----------------------+       +---------------------------+
        |                                  |
        | valid recent anchor              | no/invalid/closed anchor
        v                                  v
Light welcome-back                 Full bootstrap menu
```

Delegated intake decision: full-depth architecture workshop is required before
planning to resolve the launcher/hook split and B2 trigger boundary.
