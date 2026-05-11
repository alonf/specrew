# Current Architecture: 011-specrew-start-conditional-pause

**Source Iteration Ref**: 001
**Last Updated**: 2026-05-11T16:25:00+03:00

## Summary

- Latest reviewer snapshot: iterations/001/
- Current reviewer index: specs\011-specrew-start-conditional-pause\iterations\001\reviewer-index.md
- Iteration 001 adds baseline-aware change detection to `scripts\specrew-start.ps1`: it reads `baseline_commit_hash` from `.specrew/last-start-prompt.md`, diffs committed prompt-surface files between that baseline and `HEAD`, and preserves auto-continue when the detector reports no relevant changes.
- The reviewed slice does not yet inject PAUSE-AND-CONFIRM or support `-PostRestartDirective`; those user-visible behaviors remain deferred to Iteration 002.
- Security surface: not generated for this iteration (No security-focused role and no FR-048/security-scoped plan task were found.)
- Review diagrams: specs\011-specrew-start-conditional-pause\iterations\001\review-diagrams.md

## Linked Current Diagrams

- iterations\001\review-diagrams.md
