# Product & Problem Domain - Feature 185

Structured record: see `spec.md` Product-Domain Summary and `product-domain.yml`.

- **Users**: downstream Specrew users on every host, especially hookless/non-Claude (Antigravity, Copilot, Cursor), plus maintainers validating cross-host parity.
- **Pain**: a host self-authorizes past a human-judgment boundary (#2884) because it receives a Claude-only instruction it cannot act on AND nothing mechanically blocks the next-phase write.
- **MVP**: harness-free cleaning + host-neutral gate-stop fallback + per-host capability + degraded-mode halt + parity/gate-detection tests + cross-host dogfood.
- **North star**: enforce-or-halt - no host silently self-advances.

Confirmation: human-confirmed (lens-question).