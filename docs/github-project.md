# Specrew GitHub Project Board

## Overview

Specrew uses GitHub Projects V2 for tracking development tasks and iterations.

**Project URL**: [https://github.com/users/alonf/projects/10](https://github.com/users/alonf/projects/10)

## Board Layout

The project uses GitHub Projects V2 default layout:

- **Status field**: Todo, In Progress, Done
- **Standard views**: Board view, Table view, Roadmap view
- **No custom columns**: Following Squad's documented default board layout

## Usage

### Linking Issues

Issues from the `alonf/specrew` repository can be linked to the project:

1. Manually: Add the issue to the project from the issue sidebar
2. Automation: Use GitHub Actions workflows to auto-link issues

### Iteration Planning

During iteration planning:

1. Tasks from `specs/001-specrew-product/iterations/NNN/plan.md` can be converted to GitHub issues
2. Issues are added to the project board
3. Status is tracked through the Status field

### Squad Integration

Per spec clarification (2026-04-17):

- Squad's built-in GitHub Projects V2 workflow is used
- Manual board management is acceptable
- No Spec Kit-side project-management extension required

## References

- Spec: `specs/001-specrew-product/spec.md` (Clarifications: GitHub Projects V2 board)
- Iteration 0 Plan: `specs/001-specrew-product/iterations/000/plan.md` (T-023)
