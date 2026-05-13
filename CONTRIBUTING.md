# Contributing to Specrew

Specrew is an alpha-stage dogfooded methodology project. The codebase is currently the only worked example of its own approach, and many design decisions are still in motion.

This guide describes what kinds of contributions are easy to accept today, what kinds need discussion first, and how to file a useful issue.

## What kinds of contributions are easy

These can land via issues without much back-and-forth:

- **Bug reports** — clear reproduction of incorrect behavior. Use the bug report template.
- **Corpus-row candidates** — recurring patterns you spotted in your own use of Specrew that look like they should be enforced by the validator. Use the corpus-row-candidate template. These feed the same retro → corpus → enforcement pipeline that internal retros feed.
- **Documentation fixes** — typos, broken links, stale wording, examples that no longer match shipped behavior.
- **Dogfooding findings** — patterns from using Specrew on your own project. Label `dogfooding-finding`. These are valuable even when they aren't immediately actionable.

## What needs discussion first

These should start in [Discussions](../../discussions) before any code changes:

- **Methodology changes** — Squad agent definitions, lifecycle boundaries, hardening-gate shape, retro structure, validator philosophy.
- **Prompt rules** — additions or modifications to the coordinator prompts or the Specrew governance template.
- **New validator rules** — including graduation of corpus rows from passive guidance to validator-enforced.
- **Spec template changes** — anything that affects `spec.md`, `plan.md`, `tasks.md`, or iteration artifact shapes.

The reason: these changes touch every project that uses Specrew. Once they're in, removing them creates churn. Surfacing them in Discussions first lets the design absorb feedback before implementation.

## External pull requests

External PRs are not currently part of the alpha operating model. The PR-at-feature-close workflow is used internally by the maintainer for Squad-driven feature delivery.

This will change as the review-boundaries stabilize. Until then, please file issues or open discussions instead.

## Filing a useful issue

- **Reproducibility wins.** A bug report with reproduction steps lands faster than a description.
- **Cross-references help.** If the issue touches an iteration artifact, a spec, or a known trap, link it.
- **Less is more.** A short, focused issue is easier to act on than a long one.
- **Use the right template.** Bug, feature request, and corpus-row-candidate templates exist for a reason. Pick the one that fits.

## Code of Conduct

By participating in this project, you agree to abide by the [Code of Conduct](CODE_OF_CONDUCT.md).

## Security

Do not open public issues for security vulnerabilities. See [SECURITY.md](SECURITY.md) for the private reporting path.
