# phase2-approval-helper-validation

## Purpose

Add shared governance parsing helpers without coupling later validator work to ad hoc Markdown or approval parsing.

## When to Use

- A Phase 2 governance slice adds helpers for `hardening-gate.md`, routing evidence, or approval references.
- The helper layer should be validated before policy-enforcement work lands.
- You need one proof path that distinguishes approved deferrals from still-blocking unresolved concerns.

## Pattern

1. Centralize Markdown metadata/table parsing in the shared governance helper rather than re-implementing it inside each caller.
2. Add approval-reference resolution that can map canonical `.squad\decisions.md` entries back to human approval evidence.
3. Parse routing evidence into structured requested/effective class fields so later enforcement can stay policy-focused.
4. Validate the helper layer with an integration scenario that includes both a human-approved deferral and a separate blocking `tbd` concern.
5. Keep lifecycle bookkeeping truthful: mark only the helper task complete and advance the next ready task window without implying later enforcement work already landed.
