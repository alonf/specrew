# Requirements NFR Lens

## Decision

Full Antigravity refocus support is accepted only when measurable real-host,
state, safety, config-preservation, release, and documentation criteria are
met. No full parity claim is allowed before the real `agy` evidence exists.

## Quality Attribute Priorities

```text
Quality driver                  Measurable acceptance signal
------------------------------  ------------------------------------------
Host parity                     agy proves bootstrap, B3, Stop, resume
State correctness               no global unknown; same conversationId state
B3 correctness                  injects only on real boundary change
Non-blocking behavior           hook/provider failures never block agy
User hook safety                deploy/remove preserves non-Specrew hooks
Release integrity               beta before stable; no parity claim before proof
Docs completeness               README/getting-started/host docs include agy
Permission clarity              Antigravity disable/permissions docs included
```

## Binding NFRs

- **NFR-1 parity proof**: Full Antigravity support is not accepted until real
  `agy` evidence proves bootstrap, B3 refocus, Stop handover, exit/re-entry, and
  stable `conversationId`.
- **NFR-2 state identity**: Antigravity must never use global `unknown`;
  fallback must be per-launch only if the host omits identity.
- **NFR-3 B3 precision**: B3 must inject only on real lifecycle boundary
  changes, not ordinary turns or self-marker noise.
- **NFR-4 safety**: Hook failures must fail open and produce bounded
  warnings/evidence.
- **NFR-5 config preservation**: Deploy/remove must preserve user hooks in
  `.agents/hooks.json`.
- **NFR-6 release discipline**: Beta is required before stable; stable is
  blocked until legacy upgrade and release validation pass.
- **NFR-7 docs parity**: Antigravity must be documented at the same level as
  other hosts, including `agy`, hook install/remove, `/permissions`, and
  `enableTerminalSandbox`.

## Acceptance Evidence

- Real-host `agy` transcript/log evidence for bootstrap injection.
- Real-host `agy` transcript/log evidence for B3 boundary-cross injection.
- Real-host `agy` Stop evidence for handover.
- Real-host `agy --conversation <id>` evidence for exit/re-entry and stable
  `conversationId`.
- Automated tests proving no global `unknown`, no private Antigravity state
  shape, config preservation, fail-open behavior, and no `PostToolUse`
  `injectSteps` emission.
- Documentation review showing Antigravity appears in README/getting-started
  and host-specific guidance at the same level as other hosts.
- Release record showing beta-before-stable and legacy upgrade validation.

## Non-Driving NFRs

- No new cloud hosting or service SLO applies; this is a local host integration.
- No new secret storage model applies; Antigravity authentication remains owned
  by Antigravity.
- No broad UI redesign applies beyond documentation/host matrix wording.

## Confirmation

The human agreed that these NFRs are the acceptance baseline for full
Antigravity refocus parity.
