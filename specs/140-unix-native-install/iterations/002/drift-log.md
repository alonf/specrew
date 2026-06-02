# Drift Log: Iteration 002

**Schema**: v1

## Drift Events

- Total drift events: 0
- Resolved via spec update: 0
- Resolved via revert: 0
- Deferred: 0
- Escalated to human decision: 0

## Notes

- No spec/plan drift: the implementation delivered exactly the planned T010–T017 scope (`install.sh`
  Ubuntu/Debian auto-install + os-release detection + ratified tty/elevation + Ubuntu CI runtime proof +
  parity-cascade + security lens).
- Informational (not drift): the Iteration-1 generator's default `RepoRoot` uses a `..\..` `Join-Path`;
  flagged as a possible Linux-portability risk, but the parity-cascade CI job (run 26812981387) confirmed
  PowerShell's path cmdlets normalize `\` on Linux — no change needed.
- Informational (not drift): Git-Bash-on-Windows could not prove FR-003 (symlink) / FR-004 (pwsh-missing)
  due to MINGW limitations; both pass on real Ubuntu CI — platform-not-proxy honored, no code change.
