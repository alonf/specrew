# Drift Log: Iteration 001

**Schema**: v1

<!--
  Markdown authoring note (Specrew lifecycle convention):

  When you add new drift events to this file, watch for MD032 (blanks-around-lists).
  A sentence ending with a colon, immediately followed by a bullet list, is the most
  common violation. Always put a BLANK LINE between the colon line and the list:

      BAD:                              GOOD:
      Resolution steps:                 Resolution steps:
      - Step one                        <— blank line here
      - Step two                        - Step one
                                        - Step two

  The F-033 pre-boundary markdownlint gate runs markdownlint-cli --fix on .md
  changes before every boundary-sync write, so most violations auto-fix — but the
  blank line you write in the first place avoids the cleanup churn.
-->

## Summary

**Total drift events**: 1
**Resolution rate**: 100% (1/1 resolved)
**Specification drift**: 1 planning-artifact correction (installer copy → symlink), resolved

## Events

### D-001 - Installer mechanism: copy -> symlink (resolved)

- **Detected**: T007 implementation (2026-06-02).
- **Drift**: `data-model.md` + `contracts/unix-native-install.md` described the installer as *copying* wrappers into the bin dir; the implementation uses a **symlink**.
- **Why**: FR-003 requires the wrapper to resolve the module root when invoked through a symlink from `~/.local/bin`. A copied wrapper resolves `module_root` to `~` (wrong); a symlink lets the symlink-resolution loop find the module's real `bin/`. Symlink is the only mechanism consistent with FR-003.
- **Resolution**: implementation-aligned (kept symlink — the correct design); corrected `data-model.md` + `contracts/unix-native-install.md` to say "symlinked". No spec FR change (FR-006 already allowed "copy or symlink"; FR-003 mandates symlink for module-root resolution).

### Resolution Strategies (Unused)

The following resolution strategies remain available if drift is detected later in execution:

- **spec-updated**: Update the spec to reflect implementation choice
- **implementation-reverted**: Revert implementation to match spec
- **deferred**: Mark drift as deferred to next iteration
- **human-decision**: Escalate to Alon for resolution

### Notes

- This artifact was scaffolded before review starts so drift can be logged immediately when detected.
- Replace the zero-drift summary with real counts when the first drift event is recorded.
