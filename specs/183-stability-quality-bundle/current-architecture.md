# Current Architecture: 183-stability-quality-bundle

**Source Iteration Ref**: 001
**Last Updated**: 2026-06-16T19:20:00+03:00

## Summary

- Current review packet: file:///C:/Dev/183-stability-quality-bundle/specs/183-stability-quality-bundle/iterations/001/
- Reviewer index: file:///C:/Dev/183-stability-quality-bundle/specs/183-stability-quality-bundle/iterations/001/reviewer-index.md
- Structured review: file:///C:/Dev/183-stability-quality-bundle/specs/183-stability-quality-bundle/iterations/001/review-145.md
- Review diagrams: file:///C:/Dev/183-stability-quality-bundle/specs/183-stability-quality-bundle/iterations/001/review-diagrams.md

## Architecture Snapshot

F-183 now has two accepted runtime tracks. The first keeps SessionStart
governance visible under cap pressure, provider failure, and missing session IDs.
The second adds bounded Antigravity hook support and moves hook-capable host
binding data into `RefocusHookBindings` in each host manifest.

Shared deploy/status code consumes manifest data instead of host-name-specific
registration branches. Antigravity remains bounded to project `.agents/hooks.json`,
verified `PreInvocation` bootstrap injection, verified `Stop` handover decision
behavior, and fallback guidance through `specrew start --host antigravity`.
