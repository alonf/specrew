# Architecture-Core — Feature 177 (code-implementation / software-development-rules lens)

**Depth**: full · **Confirmation**: human-confirmed / lens-question (2026-06-10)

## Macro architecture — producer → artifact → consumer

```text
   DESIGN TIME (the workshop)                         IMPLEMENT TIME
   ──────────────────────────                         ──────────────

   code-implementation lens (md)                   specrew-code-rules skill  (NEW)
    · presents grouped rules                         · loads the feature manifest
    · per-stack dilemmas                             · guides the coding agent as it writes
        │                                                     ▲
        ▼                                                     │ reads
   ┌─────────────────────────────┐  ships with              │
   │ canonical rule CATALOG       │  Specrew                 │
   │   code-rules.yml             │  (data-driven,           │
   │   49 rules + per-stack,      │   not prose-only)        │
   │   grouped + enforcement mode │                          │
   └──────────────┬──────────────┘                          │
                  │ human selects / decides (workshop)       │
                  ▼                                          │
   ┌─────────────────────────────┐    reads                 │
   │ per-feature MANIFEST         │──────────────────────────┘
   │   implementation-rules.yml   │
   │   selected rules + decisions │──►  plan.md  ──►  implement constraints
   │   + context_scope (162 hook) │      (consumes)     (Implementer follows)
   └──────────────┬──────────────┘
                  │ forward-compat (NOT built now)
                  ▼
        (future) 156 workshop-decisions.yml ──► (future) 145 conformance
```

## Division of labor — content vs selection vs delivery vs discipline (now + after Proposal 139 sub-agents)

```text
              CONTENT              SELECTION             DELIVERY            DISCIPLINE / TRIGGER
              (stable, in data)    (per-feature, dynamic)(host-portable)     (per-agent, static)

 now          code-rules.yml   →   implementation-   →   specrew-code-   ←   Implementer charter /
 (1 agent)    49 rules+per-stack   rules.yml             rules skill         coordinator prompt:
                                   (selected subset)     (ONE skill)         "consult the skill,
                                                                              follow the manifest"

 later        (same catalog)   →   (same manifest)   →   (same skill,    ←   dev SUB-AGENT system
 (139)                                                   consumed by         prompt: thin POINTER
                                                         the dev agent)      + discipline ONLY
```

**Principle**: content lives in the catalog; selection in the per-feature manifest; delivery in ONE
skill; only a pointer + discipline in the system prompt — because a system prompt cannot be
per-feature, and baking 49 rules there is static, unportable, and duplicated (lens rule 7: keep
volatile content out of stable mechanisms).

## Decisions (human-confirmed)

1. **Producer→manifest→consumer spine.**
2. **Data-driven canonical catalog** (`code-rules.yml`) with stable rule IDs — not prose-only-in-md.
3. **One guidance skill** consumed by the current agent + future Proposal-139 dev sub-agents;
   "aspects the agent won't always need" solved by manifest applicability filtering + contextual
   surfacing within the one skill, not multiple skills; system prompt carries only a pointer.
4. **Forward-compat `context_scope` hooks** (product_baseline / feature_delta / feature_standalone)
   for Proposal 162 — hooks only.
5. **Advisory/guidance posture** — lens participates in the existing specify lens-record gate; the
   rules manifest is not a new hard gate; no parallel code-quality engine (no Proposal 145).
