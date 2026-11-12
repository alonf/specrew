# Workshop record: iteration 002, problem-space completeness

**Feature**: 205-workshop-lens-order | **Iteration**: 002 | **Date**: 2026-11-13 | **Spec**: TG-003 ("Iteration 2 ...
gets its own short workshop")

## Who answered

The maintainer delegated this workshop's answers to the reviewer session (`specrewreviewer-84`). Their words, typed in
the crew session on 2026-11-13: "For iteration 002's workshop, the reviewer session answers the workshop questions on
my behalf. Record each answer as the reviewer's, given under my delegation, in the workshop record and the drift log.
Every boundary approval stays mine, typed here. If the reviewer says a question is mine, ask me."

Every answer below is the **reviewer's, given under that delegation**. The reviewer reports that the maintainer
discussed and agreed all of them with it at about 01:20 local on 2026-11-13. No answer here was typed by the maintainer
in the crew session, and no workshop receipt was logged for them (the last receipt in
`.specrew/runtime/workshop-authority.jsonl` is from 2026-11-10). Boundary approvals are not delegated.

## Input

- The problem-side gap list from iteration 001: `specs/205-workshop-lens-order/iterations/001/problem-gap-list.md`.
- The research page the maintainer asked for before the shape question (presented in the crew session on 2026-11-13):
  placement of proposals 162, 164, 175, 177, 178, 179, 195, 210 and 214; the workshop-length baseline; who reads each
  lens's answer after the workshop; and the code-implementation lens refresh, checked against official release notes
  fetched 2026-11-13.

Measured baseline (lens files at `d4c11236`): 69 decision points across the 11 lenses. The reference profile
(product-domain, the agenda, the 3 always-on lenses, code-implementation, and the security, data and integration lenses)
presents 50 decision points and needs at least 16 typed replies. Only product-domain defines Light, Standard and Deep
content.

## Purpose (the maintainer's words, relayed by the reviewer)

The workshop is the most important part of the process: a good workshop reduces later problems and provides the
foundation and most of the major decisions, so missing areas should be added, and now is the time because these files
are open anyway. It need not all fit in one iteration.

## Question 1: the shape of the fix

**Answer (reviewer, under delegation)**: option 4. Product-domain carries the cross-cutting facts and hands them
forward; the lens-specific gaps go inside their own lenses. No new lens.

- The 6 gap questions that repeat product-domain are dropped: the compliance regime and data residency
  (security-compliance), the data to carry over (data-storage), and platform constraints, the operator and the budget
  (devops-operations). Product-domain is deepened instead: at Light it must ask more than "key constraints".
- Hand-forward: a product-domain answer appears in the later lens as that lens's recommended answer, with where it came
  from. The plan says how to do that with the least new mechanism.

## Question 2: which rules apply in this iteration

**Answer (reviewer, under delegation)**:

1. **Recommended answers: yes**, for every question this iteration adds or changes. Each ships with a recommended answer
   and its reason, and one reply closes a lens by accepting all its recommendations. Each recommendation is written so
   that a bare "accept" is unambiguous.
2. **Depth: yes**, for the lenses this iteration touches. Added problem questions default to Light: shown with the
   recommended answer and accepted unless the human changes it. Depth content for untouched lenses is later work.
3. **Length: measured, not frozen.** At Light the workshop stays at today's level for the reference profile: at most 50
   decision points presented and 18 typed replies. Standard and Deep may grow. The test reports the numbers for all
   three depths, fails when Light goes over, and fails when a Standard or Deep number changes without the recorded
   number being updated in the same change.
4. **No question without a consumer: yes.** Until proposal 177 exists the consumer must be real today: a named spec.md
   section the reviewer reads, or a later lens that uses the answer as its recommended answer. "Plan Obligations" does
   not count, since nothing reads it.

### Follow-up on rule 3: how Light is counted

The crew pointed out that rule 3 as given could not be met: the reference profile already presents exactly 50 decision
points, so any added Light question would go over.

**Answer (reviewer, under delegation; not sent to the maintainer because it follows from what they agreed)**: count
three numbers at Light for the reference profile, separately.

1. **Must-answer decision points**: questions the human has to decide. Cap 50, today's number. A question shown with a
   recommendation that is accepted unless changed is not counted here.
2. **Typed replies**: cap 18, unchanged.
3. **Recommendation lines**: every line shown with a recommended answer that is accepted by default. Not capped, but
   recorded. The test fails when this number changes without the recorded number being updated in the same change, as
   for Standard and Deep.

Counting a whole block as one point was rejected because it hides how much the human has to read. Dropping existing
questions, or raising a single cap, were rejected because they are not this iteration's purpose and mix deciding with
reading. Two conditions on the recommendation blocks:

- A lens's block is shown once, as one list, closed by one reply. It does not become one prompt per line.
- Each line states the recommended answer, its reason in a few words, and where the answer goes (the spec.md section or
  the later lens), so rule 4's consumer is visible to the human.

The plan reports the three numbers for Light, Standard and Deep, before and after this iteration's changes.

### Clarification: the six product-domain facts at Light

**Answer (reviewer, under delegation; a clarification of its own earlier answer, sent before the clarify sync)**:
FR-023 ("MUST ask at every depth") and FR-028 (Light capped at today's 50 must-answer points) contradicted each other,
because product-domain is the first lens and nothing can be handed forward into it.

1. At Light the six facts are recommendation lines, not must-answer questions. Each is shown with a default the system
   states without asking: what the repository and earlier answers show, or "none stated". Examples given: compliance
   regime "none stated", data residency "no constraint stated", platform "as the repository shows", operators "the team
   that builds it", budget "not stated". The human accepts the list in one reply or changes a line.
2. At Standard and Deep, product-domain asks them as questions.
3. The length test counts them where they are shown: recommendation lines at Light, must-answer points at Standard and
   Deep. Product-domain's must-answer count at Light stays at eight. A fact folded into an existing area still counts
   as its own line.
4. A "none stated" default is still handed forward (FR-024): the later lens shows "product-domain: none stated" as its
   recommended answer.
5. FR-023 is reworded from "MUST ask", and SC-009's fixture proves the Light behaviour as well as the hand-forward.

A default that would be wrong or misleading for one of the six goes to the maintainer at the clarify packet.

## Scope of iteration 002 (reviewer, under delegation)

- The lens-specific gap questions under those rules, the product-domain deepening and the hand-forward.
- The code-implementation lens refresh as its own task: a "last checked" line per stack, version numbers only in the
  dated line and Source Notes, and nothing from the not-confirmed list.
- If the plan shows this is too much for one iteration, split it: gap questions and rules first, the rest in a further
  iteration, said at the plan boundary with the sizes.

## Proposal map (reviewer, under delegation)

Accepted as placed in the research page. None of the nine is built in iteration 002. After 205's iteration 002:
proposal 177 as its own feature, implementer side first and reviewer side after feature 203 merges; then the testing
lens (178 merged with 195); no new solution-side lens before 177. That order goes into proposal 220's status history.

## Finding for feature 203 (records only)

The reviewer's prompt calls the workshop records binding (`scripts/internal/continuous-co-review/worktree-reviewer.ps1:1139`),
but `workshop/` is not among the files it is given (`scripts/internal/continuous-co-review/review-design-context.ps1:104-133`).
Feature 205 does not touch those files; this goes to the 203 hand-over.
