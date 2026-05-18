### 2026-05-18T17:25:25Z: Spec Steward durability decision
**By:** Spec Steward
**What:** Treat commit `a5a7996` on `022-hotfix-schema-tests` as the truthful durability anchor for the current Feature 022 combined specify+clarify artifact set. Reconcile any pending boundary commit references to that checkpoint rather than reconstructing an uncommitted specify-only boundary.
**Why:** Feature 022 artifacts existed locally without a durable checkpoint, and the user explicitly held `/speckit.plan` authorization until real git/origin durability was restored without history rewriting.
