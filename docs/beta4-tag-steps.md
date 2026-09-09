# Beta4 tag steps

**Written before the green run lands, so the order is fixed rather than improvised at the tag.**

Each step names what it verifies. A step that cannot state its verification is not done.

## 0. Precondition: a green dispatched run

**The last green before a tag must be a DISPATCHED workflow run, not a local sweep** (DRIFT-199-I003-083).
Record the run id and the SHA it ran on. **The tag goes on that SHA.**

If the run is red, nothing below starts. **There is no second re-run of a red census** (PRED-BETA4-008).

## 1. Rebuild from the tagged SHA and install THAT build

**The currently installed module is `356e3295`, which predates the tag candidate by several commits.** The
crew and the walk must exercise the build that will actually be published, not an earlier one - accumulated
proofs on intermediate builds are what DRIFT-199-I003-008 recorded and had to withdraw.

```powershell
# from a clean tree at the tagged SHA
pwsh -File scripts/internal/install-local-build.ps1
```

**Verify installed == tagged before anything depends on it:**

- `build-stamp.json` `commit` equals the tag SHA;
- `content_sha256` and `content_file_count` recorded;
- the installer's own byte verification passed for every packaged file.

**The gallery snapshot already exists and has been restored once** (B4F-028), so the pre-beta4 build is
recoverable if this needs backing out.

## 2. `specrew update` on every project that will be exercised

The module is one side of the handshake; the project runtime is the other, and the review engine refuses
when they disagree (B4F-027). **Build first, then update** - the reverse deploys the older module over
newer fixes.

## 3. The skill crew's eight lenses

**Hand over `docs/beta4-router-skill-crew-brief.md` first**, and run its **PRE-FLIGHT**: exactly one feature
with a controller plus the unauthored marker must exist, or the resolve refuses as ambiguous and the refusal
reaches the journal rather than the human.

**The brief's rule holds for every lens**: to confirm, `move on` and nothing else; to disagree, do not type
the correction into the lens-closing turn.

## 4. The fresh-project walk, carrying BOTH assertions

A verification path must run against a project created minutes ago by the shipped `init`, not against this
repository (DRIFT-199-I003-068).

1. **The second-feature registration.** Create a feature, take it to closure, create a SECOND feature, and
   confirm its workshop question registers - the defect beta4 fixes, which a first feature cannot exercise.
2. **Closeout-then-resume-then-validate** (PRED-BETA4-007). Close an iteration, resume the session, run the
   validator. **Prediction: red on `closed-iteration-edited`, for files the product itself rewrote.** If it
   holds it is a beta4 release-note known issue with the one-line workaround (`git checkout` the iteration's
   `state.md` and `tasks-progress.yml`); whether it becomes a beta4 fix is the maintainer's call **after**
   the walk.

## 5. Tag

On the SHA the green dispatch ran on. Nothing else.

## 6. Watch the publish to completion

**A gate that fails after the ceremony declares success needs to tell someone** - the beta3 publish sat
dead for two days (DRIFT-199-I003-022), and a second one was saved only by a dry run
(DRIFT-199-I003-026). Watch it; do not report the release as shipped from a tag push.

## 7. Verify the gallery artifact against the local build

Compare the published artifact's content hash to the local build's `content_sha256`. **Compare
`content_file_count` before comparing hashes** - a hash without its scope is not reproducible, and the first
independent verification of a stamp disagreed purely because the verifier hashed a different set.

## What is NOT in the tag, deliberately

Records live outside the tagged tree (DRIFT-199-I003-040): the release body names the branch and the exact
commit carrying them, and states that the drift log inside the tagged tree is superseded by it. **A pointer
in a published release body must be REACHABLE** - merge with merge-commit history so the named commit
survives.
