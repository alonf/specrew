---
description: "Route the specify entry through the Specrew design workshop before producing a spec"
---

# Run the Specrew Design Workshop Before Specifying

You are producing a feature specification on a **Specrew-governed project**. Specrew does NOT generate the spec from informed defaults — the spec must be **lens-informed**, produced WITH the human through the design workshop. Before you write any spec content, do this:

## Required

1. **Invoke the `specrew-design-workshop` skill** and work the applicable design lenses WITH the human — product-domain first, then architecture-core, component-design, data-storage, integration-api, observability-resilience, devops-operations, requirements-nfr, ui-ux, and code-implementation as applicable. Work **one lens at a time**: present each lens, get the human's decide / delegate / skip, and record the confirmation. Never fabricate a lens agreement — the SC-026 provenance gate validates that each lens record reflects a real human answer.
2. Only **after** the workshop is complete and the lens records exist do you write `spec.md`, informed by the confirmed lens decisions (lens-informed, not lens-decorated).
3. Then **stop at the specify boundary** and render the human re-entry packet for the verdict. Do not free-run into clarify.

## Failure behavior

If you are about to generate the spec from informed defaults **without** having run the workshop with the human, STOP — that is raw Spec Kit behavior, and this project is Specrew-governed. The `specrew-design-workshop` skill is the Specrew specify **entry**; the `speckit.specify` generation is the spec-**writer** that runs only **after** the workshop. Invoke the workshop and work the lenses with the human first.
