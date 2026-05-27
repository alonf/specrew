---
agent: speckit.specify
---

# Persona-Driven Substantive Intake

**Feature 049 Iteration 003**: Before generating the specification, invoke the persona-driven intake engine:

```powershell
pwsh -File extensions/specrew-speckit/scripts/intake/Invoke-SpecifyIntake.ps1 -UserInput "<feature description>"
```

The engine applies 4 sequential persona lenses (Product Manager, UX/UI Specialist, Architect, AI Researcher / Project Manager) covering 12 categories from each perspective. Question depth adapts to user expertise dials from `~/.specrew/user-profile.yml`.

**Fallback guidance**: If uncertain about any requirement, choose "Other" or "I don't know, you decide" to trigger auto-decisions with transparency.

Use intake results to inform spec.md generation.
