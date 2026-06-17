# Product-Domain Delta: Iteration 002

**Depth**: light  
**Context scope**: feature_delta  
**Confirmation**: human-confirmed / lens-question

Iteration 002 is a narrow follow-up to F-184 iteration 001. The product problem
is not missing refocus behavior; it is that AI host agents are not focused on
the Specrew process, especially the workshop. In multiple manual tests the host
agent did raw Spec Kit work instead of the governed Specrew workshop, and it
took too much prompt time and effort for the host to discover the correct next
step.

## Known Inputs

- `AGENTS.md`/equivalent persistent instructions are not deployed on the
  hook-only path today; this is not merely a `specrew start`-only behavior.
- `AGENTS.md` alone is not enough across all supported hosts: Claude needs
  `CLAUDE.md`, and Copilot needs `.github/copilot-instructions.md`.
- The host needs a prominent guard: drive Specrew through the design-workshop
  skill and boundary slash-commands; do not run raw `specify.exe workflow`.
- The bootstrap should lead with the immediate lifecycle action before slower
  context.
- Opus 4.6 must be checked for faster time-to-workshop.
- Gemini Flash must be checked for following the workshop and not shelling out
  to raw Spec Kit. If it still cannot, the weak-model caveat stays explicit.

## MVP

1. Deploy the host-manifest `InstructionsFile` during `specrew init` for every
   supported host.
2. Refresh/heal the managed section through `specrew update` and `specrew start`
   without making start the only deployment path.
3. Merge a Specrew-owned section without clobbering user content.
4. Put the coordinator and anti-raw-workflow guard in persistent instructions
   and bootstrap.
5. Source content from a packaged static Specrew coordinator template/fragment.
6. Keep shared implementation host-neutral.
7. Validate with real-host Antigravity Opus and Flash runs.

## Non-Goals

- No feature-closeout or release work.
- No broad host instruction rewrite beyond this manifest-driven path.
- No full Antigravity parity claim before iteration 002 evidence lands.
