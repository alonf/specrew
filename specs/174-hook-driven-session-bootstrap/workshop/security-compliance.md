# Security Compliance Intake Notes

```text
[Host event stdin] -> [Hook trust boundary] -> [Filesystem state]
                                           -> [Agent directive]

Controls: validate event shape, validate local project ownership, reject stale
or non-portable anchors, keep hook non-interactive, avoid secret/state leakage.
```

Delegated intake decision: medium-depth security workshop is required because
untrusted or stale filesystem state must not steer lifecycle recovery.
