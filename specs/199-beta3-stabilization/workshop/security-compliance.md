# Security-Compliance Lens Record: 199-beta3-stabilization

**Feature**: 199-beta3-stabilization
**Depth**: light
**Captured**: 2026-08-10
**Confirmation**: human-confirmed ("S1 accepted as stated" plus the symmetric-policy ruling)

## Trust-boundary diagram (agreed)

```text
                    │ TRUST BOUNDARY: the containment root
                    │ (module install dir / review authority store /
                    │  frozen verification snapshot)
   inside           │                              outside
                    │
   regular file ────┼── OK (hash-verified today)
                    │
   junction ════════╪══> C:\anywhere\else          ← path REDIRECTION.
   symlink  ════════╪══> \\attacker\share            The beta2 refusal is
                    │                                CORRECT — stays refused.
   cloud placeholder┼── same path, same identity;  ← NOT a redirection.
   (OneDrive)       │   bytes materialize on read    Today refused by the
                    │   via the CloudFilter driver   attribute-only check —
                    │                                the F1 false positive.
```

## S1 — Reparse-tag policy (accepted as stated)

- Discriminate by reparse TAG, not the ReparsePoint attribute. Allowlist exactly the
  Microsoft cloud-files tag family (IO_REPARSE_TAG_CLOUD and variants). Treatment:
  hydrate (read forces the CloudFilter driver to materialize bytes), then verify — the
  existing hash verification runs on the hydrated bytes. Trust rests on the hash of
  hydrated bytes, never the placeholder; wrong-bytes-on-hydration is caught by the same
  hash mismatch that catches any corruption.
- Junction and symlink refusal untouched (the beta2 guarantee); their denial-path
  fixtures stay green. (Lexical containment ≠ containment, DRIFT-198-I009-041 lineage.)
- Unknown/other tags (app-exec links, projected filesystems, future tags) fail closed —
  allowlist, not blocklist. No elevation required; the default CurrentUser install path
  becomes campaign-capable.
- Refusal message in the U4 shape: what happened -> what it means for your project ->
  the exact next step (e.g. reinstall to a regular folder / -Scope AllUsers).
- Evidence plan (method rule): the tag classifier is a pure shipped function pinned by
  fixtures with real tag constants; junction/symlink refusal keeps real filesystem
  fixtures; the end-to-end OneDrive hydration leg is verified manually on the recorded
  T067-class environment, with the proof line transcribed from that measurement and its
  scope stated — never drafted ahead.

## Human ruling on the open question — symmetric policy

No special-casing the authority store: the policy stays SYMMETRIC across the module
install, the authority store, and the frozen snapshot. Rationale (human): the residual
risk of a store under a sync root is sync conflicts, which apply to regular files under
sync identically. Mitigation: ONE advisory sentence in the docs recommending governed
repositories live outside synced folders — nothing more.
