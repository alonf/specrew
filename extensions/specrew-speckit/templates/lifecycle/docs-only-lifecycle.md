# Docs-Only Lifecycle (template)

**Work kind**: `docs-only` · **Lifecycle weight**: lightweight · **Produces a release**: no

Use this for README, docs, proposals, methodology wording, examples, or release notes with **no
runtime change**. It completes through a PR without a release. If your change touches runtime source
or workflows, it is **not** docs-only — reclassify to `software-feature` / `devops`, or split the PR.

Declare it: `.specrew/work-kind.yml` → `work_kind: docs-only` (branch prefix `docs/` gives the default).

## Required evidence (the lightweight set)

- [ ] **Intent** — one or two lines: what is changing and why.
- [ ] **Audience** — who reads this (end users, contributors, maintainers, operators).
- [ ] **Changed docs** — the list of doc files touched (all within the docs-only allowed scope:
      `**/*.md`, `docs/**`, `proposals/**`, `CHANGELOG.md`, …).
- [ ] **Markdown / link checks** — `markdownlint` clean; internal links resolve.
- [ ] **Review** — at least the project's `review_gate` human approval(s); comments resolved.
- [ ] **Docs-closeout** — a one-paragraph closeout note; **no release, no tag, no publish**.

## Flow

```text
intent + audience -> edit docs -> markdownlint + link check -> PR -> review -> docs-closeout -> merge
```

## Notes

- Repository-global / generated files (`CHANGELOG.md`, proposal `INDEX.md`, `.squad/**`, `.specrew/**`)
  are allow-listed and do not count as a scope violation.
- A post-merge docs fix is itself a **new** docs-only PR — never a reopen of a merged feature.
