# quality-scaffold-sync

## Purpose

Keep new iteration-local evidence surfaces synchronized between the start-of-iteration scaffold and the reviewer closeout scaffold.

## When to Use

- A feature adds new files or directories under `specs/<feature>/iterations/<NNN>/`.
- The artifact must exist before later execution fills it with real evidence.
- Reviewer closeout should preserve or backfill the same surface if it was missing.

## Pattern

1. Add a missing-only scaffold helper for placeholder artifacts.
2. Gate the new surface on the plan or contract that actually requires it.
3. Create/preserve the directory surface before writing files.
4. Keep placeholder content explicit that execution has not happened yet.
5. Validate both the iteration scaffold path and the reviewer scaffold path.
