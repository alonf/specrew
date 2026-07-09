# The Self-Leak Firewall

**Since**: F-198 (0.40.0-beta2) · **Owner surfaces**: everything Specrew
deploys into consumer projects · **Mechanism**:
`scripts/internal/lint-self-leak.ps1` + the versioned deny-list at
`extensions/specrew-speckit/data/self-leak-deny-list.json`

## The problem class

Everything Specrew deploys to consumers is authored inside the
self-hosted Specrew repo, by contributors and agents marinated in
Specrew's own lifecycle. Without a firewall, self-facts fossilize into
methodology and ship as if universal — a release SDLC taught to projects
with no publish target, dev-tree names conflating a consumer project's
identity, self-host CI deployed broken-by-construction.

## The parameterization rule (author-time, binding)

Deployed teaching states the **abstract rule** plus a **resolution
point** filled from the consumer project's governance or config at render
time — never Specrew's own instantiation as the example-that-reads-as-
mandate.

- Wrong: "push → PR → beta tag → publish to the gallery → stable
  promotion."
- Right: "release steps are instantiated from the project's recorded
  release model; projects without a publish target get branch-ready
  evidence as their complete final status."

If a deployed sentence names a concrete registry, forge slug, dev path,
maintainer, or self feature/decision identifier, either it resolves from
the consumer project at render time, or it does not ship.

## The lint (deterministic enforcement)

The CI lane runs `lint-self-leak.ps1` over **exactly what ships**: the
module manifest's FileList filtered to the consumer-deployed prefixes
(`templates/`, `squad-templates/`, `extensions/specrew-speckit/`). The
deny-list is versioned data (`schema_version`; entries carry
pattern/class/reason/source/added across seven classes: release-model,
dev-path, feature-id, maintainer-id, registry, repo-ref, decision-ref).
Every field-found leak adds one entry — prevention and detection read the
same shipped file, so they cannot disagree about what a leak is.

Exit codes are contract: `0` clean, `1` unannotated findings, `2`
unreadable rule surface (fails loud — a broken rule file can never
produce a silent green).

## The annotation escape (sanctioned self-references)

Some self-references are correct: the `specrew-update` skill genuinely
updates Specrew from its own registry; provenance comments cite the
feature that shaped a behavior; the lens catalog credits its source.
Sanction them where they stand, with the reason recorded:

```text
.md              <!-- specrew-self-ok: <reason> -->
.ps1/.psd1/.yml  # specrew-self-ok: <reason>
```

Same line or the line immediately above the hit. **A token with no
reason text is treated as unannotated** — the reason is the audit trail.
Tracked-debt annotations name the task/requirement that removes them
(e.g. the release-model resolver), so the debt is self-documenting and
its cleanup is scheduled, never silent.

## Runtime and consumer-side arms

- The prompt-builder fixture test renders every built prompt surface
  against a project named anything-but-Specrew and asserts zero deny-list
  hits (catches interpolation leaks static lint cannot see).
- The same shipped deny-list runs consumer-side: as an advisory check in
  the methodology gateway and in `specrew update`'s heal surface —
  flag-only for user-authored files, auto-rewrite only for Specrew-owned
  deployed files whose content hash matches a shipped version.
- One deployed refocus line inoculates agents against identity
  conflation: the project under governance is the consumer's project;
  Specrew is the tool, never the subject.

## What this is not

A deny-list cannot catch semantic leaks phrased without keywords (a
workflow that assumes PR-based flow without naming a forge). The fixture
rendering and field reports remain the backstop; every field-found leak
becomes a one-line list addition.
