# Review Scope: Feature 205, Iteration 002, Round 2

**Iteration**: 002, problem-space completeness (Amendment A1)
**Round 1**: run `run-20261114-192351085-49d20b6b` on `3ddcd185`, three minor findings
**Written**: 2026-11-14, before the round, and committed in the reviewed tree

Round 1's scope is unchanged: [review-scope-round-1.md](review-scope-round-1.md). It covers the contract, the counts,
the known limit of the evidence, and what is not a defect of this iteration. This round reviews the fixes for round 1's
three findings, all in `tests/unit/workshop-length-budget.tests.ps1` (DRIFT-018). No lens file, skill or template
changed since round 1.

## The fixes

1. **Finding 1, SC-009 fact by fact** (`598d0836`).
   - `$script:ProductDomainFacts` holds the contract: each fact's Light form, its receiving lenses, and the operators
     default.
   - `Test-ProductDomainFacts` checks each fact by its key:
     - shown at Light as the contract says, and a question at Standard and Deep;
     - the default where one is fixed;
     - each receiving lens holds a hand-forward line citing product-domain that carries "not stated";
     - product-domain has nine must-answer points at Light.
   - The length count and this check share one depth rule (`Get-ItemDepthKind`).
   - Self-tests run on a copy of the real catalog, including the swap round 1 described.
2. **Finding 3, a lens consumer must receive the answer** (`22c0a583`). A `lens: <id>` consumer needs an answer key,
   and the target must hold a hand-forward line for that source and key. A hand-forward passed on to a later lens is
   held to the same rule.
3. **Finding 2, exempt questions by identity** (`398e9520`). `$script:UnsuffixedBaseline` lists each exempt question by
   a hash of its normalized text, with a label.
   - 68 of the 69 are identical to `d4c11236`.
   - product-domain area 4 is recorded at its current text, by the reviewer session's ruling: T019 appended a pointer
     sentence, and the question is unchanged.
   - The failure names the question and the two ways out.

Each fix follows its red commit (`8347d9d5`, `3a13eaa4`, `335de732`), whose message gives the failing count.

## Where to attack first

- **Fact contract against the spec.** Does `$script:ProductDomainFacts` match FR-023 and FR-024 (each fact's Light
  form, its receivers, the operators default)? Can a change to `product-domain.md` or a receiving lens still break
  SC-009 and pass?
- **Self-tests prove what their names say.** Are the mutations specific enough that each failing assertion is caused
  by the shape it names?
- **Exempt list can be re-derived.** Can it be re-derived from `d4c11236` as the comment says? Is the area 4
  exemption limited to that one question?
- **New checks can't fail falsely.** Can the new consumer rule reject a valid hand-forward chain, or the identity check
  reject a shipped question?
