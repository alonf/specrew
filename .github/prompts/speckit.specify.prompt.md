---
agent: speckit.specify
---

# Persona-Driven Substantive Intake

**Feature 049 Iteration 003**: Before generating the specification, invoke the persona-driven intake engine:

```powershell
pwsh -File extensions/specrew-speckit/scripts/intake/Invoke-SpecifyIntake.ps1 -UserInput "<feature description>"
```

The engine applies 4 sequential **internal persona lenses** (Product Manager, UX/UI Specialist, Architect, AI Researcher / Project Manager) covering 12 categories from each perspective. These lenses are Specrew internals — not identities the user holds. Question depth is driven by the current user's **Crew Interaction Profile** (decision-area settings: Product Strategy, UX/UI Design, Software Architecture, AI Delivery Planning) resolved from `~/.specrew/user-profile.yml` (`$env:USERPROFILE\.specrew\user-profile.yml` on Windows). `/speckit.specify` is the only surface that **hard-applies** the profile; everywhere else it is soft session guidance only.

**Fallback guidance**: If uncertain about any requirement, choose "Other" or "I don't know, you decide" to trigger auto-decisions with transparency.

Use intake results to inform spec.md generation.
