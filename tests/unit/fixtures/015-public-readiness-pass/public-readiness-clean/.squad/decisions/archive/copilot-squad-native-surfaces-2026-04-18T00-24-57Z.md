### 2026-04-18T00:24:57Z: Squad packaging strategy selected
**By:** Alon Fliess (via Copilot)
**What:** Specrew v1 will use Squad native surfaces: `.copilot/skills/` for skills and `.squad/` runtime surfaces for ceremonies/directives, rather than a packaged `extensions/specrew-squad/` plugin layout.
**Why:** Iteration 0 spike results showed Squad's local plugin architecture is marketplace-only and does not support the planned bundled `extensions/specrew-squad/` structure.
