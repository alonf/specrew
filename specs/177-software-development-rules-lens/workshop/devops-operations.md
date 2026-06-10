# DevOps & Operations — Feature 177 (code-implementation / software-development-rules lens)

**Depth**: light · **Confirmation**: human-confirmed / lens-question (2026-06-10)

Local PowerShell module + per-host skill folders (no servers/containers).

```text
  SHIPPED WITH THE MODULE  (FileList + .specify/ mirror)
    knowledge/design-lenses/code-implementation.md            (NEW lens md)
    knowledge/design-lenses/code-rules.yml                    (NEW catalog)
    knowledge/design-lenses/implementation-rules.schema.json  (NEW schema)
    knowledge/design-lenses/index.yml                         (edited: + lens row)
    knowledge/design-lenses/applicability-map.json            (edited: + entry)
    skills/specrew-code-rules/...                             (NEW skill template)
    skills/specrew-design-workshop/...                        (edited: + code lens turn)
    charter / coordinator templates                          (edited: + skill pointer)

  DEPLOYED TO HOST DIRS BY THE ENGINE  (init/update)
    .claude/skills · .github/skills · .agents/skills  ← specrew-code-rules + design-workshop
        (multi-host parity test guards drift)

  RELEASE CHECKLIST  (the F-176 lesson — non-negotiable)
    [ ] extension.yml version bump (0.34.0 → 0.35.0)  — prepublish Docker harness checks this
    [ ] FileList: every NEW deployable file added to Specrew.psd1 (lens md, catalog, schema, skill)
    [ ] .specify/ mirror parity (extensions ↔ .specify)  — mirror-parity validator
    [ ] markdownlint the new md
    [ ] CHANGELOG entry
    [ ] beta-before-stable: v0.35.0-beta.1 → dogfood on Claude → promote stable
  Rollback = standard module version rollback. CI = Lint + Deterministic + Contract + prepublish harness.
```

## Decisions (human-confirmed)

- **Minor bump 0.34.0 → 0.35.0**, shipped `v0.35.0-beta.1` first (universal beta-before-stable), dogfood
  on Claude before promotion.
- **FileList + `extension.yml` + `.specify/` mirror are explicit plan tasks** (the F-176 omission class).
- **Real validation = the dogfood** (agent guided, no rule wall), not "files installed."
