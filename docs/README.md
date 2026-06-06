# Specrew Documentation

This directory contains the main user-facing documentation for Specrew.

## Documentation Structure

- `getting-started.md` - practical bootstrap and quickstart guidance for greenfield and brownfield repos
- `user-guide.md` - lifecycle guide for planning, execution, review, retrospective, and drift handling
- `methodology\` - the methodology contract: lifecycle discipline, review instructions, proposal discipline, and the [Design Workshop methodology](methodology/design-workshop-methodology.md) (the lens-driven human-agent design conversation at intake and the design-analysis stop)
- `github-project.md` - Specrew self-development board and project operating model
- `operations\psgallery-release-credentials.md` - maintainer-facing release-credential runbook (PSGallery API-key rotation now; certificate guidance can co-locate later)

## Recommended Reading Order

1. Start with `getting-started.md` if you are bootstrapping or adopting Specrew in a repo.
2. Use `user-guide.md` for day-to-day downstream lifecycle work after bootstrap.
3. Read `methodology/design-workshop-methodology.md` before your first substantive feature — it explains the design conversation Specrew runs with you at intake and before planning.
4. Use `github-project.md` only when working on Specrew's own project-management flow.

## Planned Additions

- `architecture.md` - technical architecture and design decisions
- `api-reference.md` - extension surfaces and integration points
- `extension-authoring.md` - building extensions on top of Specrew
