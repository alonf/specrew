# Research: Substantive Interaction Model

**Feature**: 016 Substantive Interaction Model  
**Branch**: `016-substantive-interaction-model`  
**Phase**: 0 — Research and Clarification Resolution  
**Date**: 2026-05-13  
**Status**: Complete — all planning unknowns resolved

---

## 1. Technical Surface Selection

**Decision**: Treat Feature 016 as a Specrew governance feature implemented across existing
PowerShell validator scripts, Markdown prompt/template surfaces, the `.squad/decisions.md`
ledger contract, corpus rows, and replay fixtures.

**Rationale**: The spec's implementation boundary and cross-references point directly at
`validate-governance.ps1`, coordinator prompt surfaces, `.github/agents/squad.agent.md`,
`.squad/decisions.md`, `.specrew/quality/known-traps.md`, README lifecycle guidance, and handoff
templates. This feature does not introduce a new runtime subsystem or application module; it
extends the current console-first governance layer.

**Alternatives considered**:
- Model the feature as an application/runtime feature → rejected; the approved scope is prompt,
  validator, corpus, and documentation governance.
- Treat `package.json` as the primary implementation signal → rejected; the concrete feature
  surfaces named by the spec are PowerShell and Markdown governance assets.

---

## 2. Boundary-Discipline Enforcement Strategy

**Decision**: Detect bundled boundary advances mechanically from the combination of (a) canonical
boundary commit subject-line signatures and (b) explicit authorization records in
`.squad/decisions.md`, with grandfathering preserved for pre-Feature-016 history.

**Rationale**: FR-006 and FR-007 require a fast, mechanical, subject-line-pattern-based check.
Using commit subjects plus ledger entries avoids semantic interpretation of arbitrary prose and
fits Specrew's existing validator style. This also preserves the clarified rule that one human
authorization advances at most one boundary.

**Alternatives considered**:
- Parse artifact bodies to infer lifecycle boundaries → rejected; slower, more brittle, and
  explicitly disallowed by FR-007 / NFR-003.
- Infer authorization from conversation context or "continue" alone → rejected; violates the
  clarified single-boundary-advance rule.

---

## 3. Authorization Recording Shape

**Decision**: Define a canonical authorization entry shape in `.squad/decisions.md` with these
required fields: Decision ID, Type, Boundary, Approving Human, Recorded At (ISO 8601 UTC), Commit
Reference, and Authorization Text. When one pasted user authorization covers both hardening-gate
sign-off and implementation authorization, Squad must auto-generate **two distinct entries** from
that single paste.

**Rationale**: The clarified answers explicitly require paired authorizations to be recorded as two
entries, not one combined multi-boundary record. A canonical field shape keeps the validator
mechanical and keeps boundary inspection reviewable and auditable.

**Alternatives considered**:
- Store a single combined authorization entry for adjacent boundaries → rejected; bundled
  authorization is explicitly forbidden.
- Capture summarized authorization text only → rejected; the spec requires preservation of the
  verbatim authorization phrase.

---

## 4. Handoff Substance Scope and Severity

**Decision**: Apply substantive-content checks to **Squad-authored console handoffs only**, using
fixed thresholds: strict AND (`>=3` identifiers and `>=50` words) for planning, implementation,
review, and retro; soft OR for iteration-closeout and feature-closeout. All Pillar 2 rules remain
soft warnings throughout Feature 016.

**Rationale**: This preserves the clarified answers and prevents scope creep into artifact-body
validation. The chosen thresholds remain mechanical and measurable, matching the repository's
existing preference for regex/count-based governance checks over semantic inference.

**Alternatives considered**:
- Extend substantive checks to artifact bodies in this feature → rejected; spec marks that out of
  scope and records only a passive `thin-artifact-content` corpus row for future candidacy.
- Promote Pillar 2 warnings to hard fails in Iteration 2 → rejected; the clarified answer explicitly
  keeps them soft-warning-only for all of Feature 016.

---

## 5. Bare-Path Detection and Graduation Path

**Decision**: Implement `bare-path-in-boundary-handoff` as a parameterized-severity rule with the
same detector in both iterations: **Iteration 1 emits
`soft-warning.bare-path-in-boundary-handoff`; Iteration 2 flips the same rule to
`validation-fail.bare-path-in-boundary-handoff`** only after exemption-list integration tests prove
bounded false positives.

**Rationale**: This exactly preserves the clarified Iteration 1 soft-warning / Iteration 2 hard-fail
promotion path and avoids a rewrite between iterations. The exemption set must cover fenced code,
inline code, shell-command arguments, log output, JSON/YAML literals, regex syntax, file-glob
arguments, existing URLs, and project-specific approved extensions recorded in
`.specrew/config.yml`.

**Alternatives considered**:
- Implement separate Iteration 1 and Iteration 2 rules → rejected; the approved rollout requires a
  config flip, not a new detector.
- Promote to hard fail immediately in Iteration 1 → rejected; violates the approved rollout and
  increases false-positive risk before proof exists.

---

## 6. Validator Scope Boundary

**Decision**: Keep all new interaction-model rules scoped to Squad-authored artifacts and handoffs;
do not parse conversation transcripts or raw user-typed text.

**Rationale**: This is an explicit clarified answer and aligns with Specrew's existing governance
model, which validates authored artifacts and assembled user-facing output rather than scraping the
entire chat transcript. It also constrains false positives and keeps the validator mechanical.

**Alternatives considered**:
- Inspect full transcripts for user/agent dialogue patterns → rejected; out of scope and not
  mechanically reliable.
- Inspect all Markdown indiscriminately → rejected; Feature 016 governs boundary handoffs and
  authorization records, not arbitrary repository prose.

---

## 7. Proof Strategy and Artifact Split

**Decision**: Keep the implementation plan aligned to the approved two-iteration split, while
allowing the resumed Iteration 002 plan to absorb tightly-coupled carryovers discovered during
Iteration 001 review/retro:

- **Iteration 1 (~13 SP)**: coordinator prompt updates, authorization-recording shape, paired-entry
  handling, `validation-fail.bundled-boundary-advance`, initial soft-warning shape of
  `bare-path-in-boundary-handoff`, and four soft-validator rules.
- **Iteration 2 (originally ~9 SP, now planned at 17.0 SP after explicit carryover triage)**:
  violating/compliant fixtures, the required Feature 016 corpus rows plus selected
  feature-local passive-guidance graduation rows, README lifecycle update, validator-scope and
  post-commit verification documentation, per-feature handoff-template update, historical
  cross-references, FR-008 post-commit Commit Reference synchronization follow-through, canonical
  seconds-precision ledger authoring, and the bare-path severity flip from soft warning to hard fail
  by configuration only.

**Rationale**: This preserves the feature's bounded two-iteration rollout while also making the
resumed planning truthfully reflect the accepted carryovers instead of pretending they disappeared.
The graduation risk still stays isolated until the false-positive proof exists, and the carryovers
remain limited to the same validator/doc/template/ledger surfaces rather than expanding the feature
into unrelated work.

**Alternatives considered**:
- Collapse everything into one iteration → rejected; exceeds the approved capacity and removes the
  staged soft-warning/hard-fail safety path.
- Move README/template/corpus work into Iteration 1 → rejected; the approved split places those in
  Iteration 2.

---

## 8. Contract Artifact Shape

**Decision**: Produce two planning-time contracts:

1. `contracts/boundary-authorization-and-handoff.md` — user-facing boundary-stop and
   authorization-recording contract
2. `contracts/interaction-model-validator-contract.md` — validator IDs, scopes, severities,
   exemptions, and output guarantees

**Rationale**: Feature 016 exposes two distinct interfaces: the human-facing stop/authorization
surface and the machine-facing validator surface. Splitting them keeps each contract narrow and
matches Specrew's existing practice of publishing focused governance contracts rather than one large
undifferentiated document.

**Alternatives considered**:
- Single umbrella contract only → rejected; too broad for validator consumers and handoff authors.
- Separate contract for each individual rule → rejected; unnecessary fragmentation for this feature.

---

## 9. Repo-Specific Quality and Verification Approach

**Decision**: Use replay-path PowerShell integration scripts, unit warning-schema tests, manual
fresh-context handoff review, and grandfathering checks as the Feature 016 verification stack.

**Rationale**: Existing Specrew features validate governance changes through PowerShell-based replay
and fixture tests. Feature 016's acceptance criteria also depend on user-visible output, so manual
fresh-context review remains a necessary complement to mechanical validator tests.

**Alternatives considered**:
- Pure unit-test-only proof → rejected; insufficient for handoff/user-visible acceptance criteria.
- Manual review only → rejected; insufficient for regression-proof validator rule delivery.

---

## 10. Iteration 002 Carryover Scope Triage

**Decision**: Resume Iteration 002 as a **17.0 / 20 story_points** slice that keeps the original
FR-020 through FR-024 + FR-016 graduation work, but also absorbs the tightly-coupled carryovers from
Iteration 001: FR-008 post-commit Commit Reference synchronization, a canonical seconds-precision
ledger format, formal post-commit verification steps, a stale-reference scan mandate, and selected
feature-local passive-guidance graduation rows.

**Rationale**: The accepted Iteration 001 review and retro proved that treating these items as
"future someday" cleanup would hide live governance lessons inside a nominally closed iteration. The
user explicitly asked for truthful carryover evaluation, and the combined slice still stays below the
constitutional 20 SP ceiling and inside the requested 15-19 SP planning target.

**Alternatives considered**:
- Preserve the original ~9 SP Iteration 002 plan unchanged → rejected; would falsely imply the
  carryovers do not materially affect Feature 016 readiness.
- Pull in every retro idea, including unrelated or weakly grounded items → rejected; would blur
  feature authority and exceed the bounded planning target.

---

## 11. Timestamp Precision Strategy

**Decision**: Use **UTC seconds precision** as the canonical `Recorded At` format for Feature 016
authorization entries and documentation updates in Iteration 002, and defer general parser support
for fractional-second timestamps.

**Rationale**: Seconds precision solves the real interoperability problem surfaced by the
carryover without widening parser behavior or adding a new acceptance surface that the feature does
not need. It is also cheaper to prove, easier to document in contracts and templates, and keeps the
decisions-ledger contract mechanically inspectable.

**Alternatives considered**:
- Add broad fractional-second parser support now → rejected; valid future work, but unnecessary for
  the bounded Feature 016 follow-through slice.
- Leave timestamp precision implicit → rejected; this would preserve the ambiguity that produced the
  carryover in the first place.

---

## 12. Post-Commit Verification Scope

**Decision**: Formalize post-commit verification as a documented workflow requirement in the README,
validator documentation, quickstart guidance, and per-feature handoff template: after each boundary
commit, synchronize Commit Reference fields, run the stale-reference scan, and verify the exact
committed tree before claiming readiness.

**Rationale**: Iteration 001 surfaced a real pre-commit vs post-commit catch-22: evidence claimed on
one tree was not always reproducible on the final committed tree, and stale `pending` or stale
artifact references weakened the decisions ledger and handoffs. Formalizing the protocol in the
governed docs/template surfaces lets Iteration 002 close the gap without prematurely committing to a
new standalone validator family.

**Alternatives considered**:
- Add a separate stale-reference / post-commit validator family immediately → rejected; possible
  future step, but not required to make the bounded follow-through slice truthful.
- Leave verification as reviewer folklore → rejected; insufficiently inspectable for a governance
  product.

---

## Research Conclusion

Feature 016 planning is fully resolved. The approved design keeps the feature inside existing
Specrew governance surfaces, preserves the clarified single-boundary authorization and paired-entry
recording rules, keeps Pillar 2 soft-warning-only, and stages the bare-path rule exactly as
authorized: Iteration 1 soft warning, Iteration 2 hard fail via configuration flip after bounded
false-positive proof. The resumed Iteration 002 slice now also records the truth about the accepted
carryovers: post-commit authorization hygiene, seconds-precision ledger canon, verification protocol
formalization, stale-reference scan discipline, and selected passive-guidance graduation all belong
to the bounded follow-through plan, while parser broadening and unrelated retro ideas stay deferred.
