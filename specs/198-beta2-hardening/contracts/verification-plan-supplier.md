# Verification-Plan Supplier Contract

**Feature**: 198-beta2-hardening
**Iteration**: 008
**Status**: planned
**Consumes**: existing `verification-plan.schema.json`, T018 validator/runner/evidence recorder
**Produces**: canonical selected plan at `.specrew/verification-plan.json`

## Purpose

Select a minimal, auditable, framework-neutral verification plan for a downstream project and feed the existing
T018 execution seam. The supplier selects complete commands; it does not execute them, infer a framework from
file extensions, or create a second result contract.

## Inputs and Precedence

Sources are evaluated in this fixed order:

1. **Explicit project configuration** — authoritative when present. Invalid explicit configuration fails closed
   and does not fall through.
2. **Reliable project-owned metadata** — only named, versioned detectors for CI/build/package metadata with an
   unambiguous command declaration.
3. **Explicit quality profile** — a user-selected profile mapped by stable profile identity.
4. **Active provider configuration** — considered only when that provider is active and the catalog row is
   explicitly provider-gated.
5. **No trustworthy source** — return `verification-not-configured` with an actionable setup path.

File-extension inference and an implicit Specrew/Pester default are prohibited.

## Output

Successful selection produces one schema-valid plan containing:

- a stable `plan_id` and unique stable `command_id` values;
- complete `executable` plus string-array `arguments` values;
- repository-relative safe working/result paths;
- engine-bounded timeouts;
- provenance object whose `kind` and `source` identify the selected input;
- named environment references only, never secret values.

The output is byte-stable for identical normalized inputs. Selection records the winning source and the skipped
higher-precedence source states without copying secrets.

## Materialization and Ownership

- Init/update/setup may materialize a generated plan at `.specrew/verification-plan.json`.
- A user-authored explicit plan is project-owned and is never overwritten.
- A generated plan may be refreshed only when its recorded content hash still matches the last generated value.
  A modified generated plan warns and remains untouched.
- Selection and materialization occur in the origin repository's normal authorized setup workflow. Review itself
  reads only from its frozen external target and never mutates the origin.

## Production Execution and Evidence Join

1. The campaign freezes the external Git target and computes the reviewed-state digest.
2. The campaign loads and validates the selected plan from that frozen target.
3. Missing or invalid selection terminates before provider invocation as actionable
   `verification-not-configured` or `verification-plan-invalid`.
4. The existing T018 runner executes valid commands in declared order and records every attempt.
5. Evidence is eligible for review injection only when both its reviewed-state digest and `command_id` match the
   selected plan. Duplicate, missing, unjoinable, or digest-mismatched evidence fails closed.
6. Command failure, timeout, missing required result, or invalid result stays visible and prevents approval; it is
   never translated into missing evidence or a clean result.

## Closed Failure Reasons

- `verification-not-configured`
- `verification-plan-invalid`
- `verification-command-failed`
- `verification-command-timeout`
- `verification-result-missing`
- `verification-result-invalid`
- `verification-evidence-unjoinable`
- `verification-evidence-digest-mismatch`

Implementations may attach safe detail but may not convert these failures into approval.

## Required Paired Tests

| Allow direction | Refuse direction |
| --- | --- |
| Valid explicit plan wins | Invalid explicit plan does not fall through |
| Named project metadata selects | Extension-only bait does not select |
| Explicit quality profile selects | Unselected profile is ignored |
| Active provider row selects | Inactive provider row is ignored |
| Safe repository-relative paths pass | Rooted, escaping, or link-escaping paths fail before execution |
| Unique commands execute in order | Duplicate command identity fails with zero command side effects |
| Exact digest and command IDs join | Stale, duplicate, missing, or unjoinable evidence is refused |
| Hash-matching generated plan refreshes | User-modified plan is preserved with warning |

## Non-Goals

- A plug-in discovery framework or general command DSL.
- Framework detection from filenames or language extensions.
- Provider-specific execution inside the supplier.
- Mutation of the reviewed origin by the campaign.
- Generic non-code gate/artifact review adapters.
