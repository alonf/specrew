# Specrew Release Discipline

Specrew releases use a beta-before-stable SDLC for every runtime-affecting
feature. The standing rule `[[feedback-beta-publish-before-stable-2026-05-26]]`
is:

Every feature that changes runtime artifacts publishes a PSGallery prerelease
first, the human validates the installed prerelease from PSGallery, and stable
publication happens only after an explicit PASS verdict.

## Scope

This discipline applies when a feature changes any runtime, package, lifecycle,
governance, prompt, template, script, manifest, changelog, or release surface.
Examples include PowerShell scripts, Specrew module manifests, Spec Kit
extension files, host prompts, coordinator rules, validator rules, and packaged
test surfaces.

Proposal-only changes are exempt when they change no runtime artifact. A
proposal-only feature does not publish a beta and does not publish stable
because it does not change the installed package shape. If a proposal-only
feature also touches runtime docs, prompts, scripts, manifests, or changelog
entries, it is no longer proposal-only for release purposes.

## Ownership

Feature-closeout is agent-driven with human approval at each substantive step.
The agent performs push, PR, merge, tag, publish verification, and audit capture
work. The human approves actions when asked and provides the prerelease manual
test PASS or FAIL verdict.

## Steps 5-14

Steps 1-4 are the normal Specrew feature implementation, review, retro, and
iteration closeout flow. Release discipline begins after feature-closeout is
ready.

### Step 5: Push the feature branch

The agent pushes the feature branch to the upstream remote and verifies the
remote branch points at the intended feature-closeout commit.

### Step 6: Create the PR

The agent opens the pull request with `gh pr create`, includes the feature
summary and review evidence, and links the relevant Specrew artifacts.

### Step 7: Self-review and address automated PR review

The agent performs a PR self-review, monitors automated review and checks, and
addresses required findings before merge. Human approval is still required for
substantive merge readiness.

### Step 8: Merge with merge-commit history

After approval and required checks, the agent merges with merge-commit history
so the feature branch remains visible in git history.

### Step 9: Tag and push the beta

The agent tags the merge commit (or the PASS-candidate fix commit if looping after a FAIL) as `v<next-version>-beta1` (then `-beta2`, … on a FAIL loop) and pushes the tag.
For F-048, the target version is `0.27.6`, so the first beta tag is
`v0.27.6-beta1`.

### Step 10: Verify prerelease publication

The publish workflow publishes the prerelease to PSGallery. The agent verifies
that PSGallery can see the package, for example:

```powershell
Find-Module Specrew -AllowPrerelease -RequiredVersion 0.27.6-beta1
```

Workflow existence is not enough. A missing workflow result, missing package,
missing credentials, or ambiguous verification result does not count as
publication success.

### Step 11: Pause for human manual test PASS or FAIL

The agent pauses and asks the human to install and exercise the prerelease from
a clean shell:

```powershell
Install-Module Specrew -RequiredVersion 0.27.6-beta1 -AllowPrerelease -Force
```

The human exercises the feature-specific surface and the smoke commands:

```powershell
specrew start
specrew where
```

Stable publication is blocked until the human reports an explicit PASS verdict
with evidence. Anything else, including silence, unclear wording, missing
evidence, or a FAIL verdict, blocks stable promotion.

### Step 12: Loop on FAIL

If the human reports FAIL, the agent fixes the issue through a PR against
protected `main` (a bug-fix or docs-only PR per Proposal 182 — never a direct
push), merges after approval and green checks, then tags the next beta such as
`v0.27.6-beta2`, verifies prerelease publication again, and repeats from Step 9
through Step 11. The betaN loop continues until the human reports PASS.

Failed beta packages are not treated as stable release candidates. Their
evidence is retained in the release audit trail.

### Step 13: Tag and publish stable after PASS

After explicit human PASS, the agent tags the commit that produced the passing
beta as `v<next-version>` stable, pushes the tag, waits for stable publication,
and verifies PSGallery visibility, for example:

```powershell
Find-Module Specrew -RequiredVersion 0.27.6
```

Stable publication is complete only when the stable package is verified.

### Step 14: Stop before new feature work

After stable verification and release audit capture, the agent stops before
starting any new feature work. A new feature begins only after a separate human
request or lifecycle start.

## Release Audit Trail

Every runtime-affecting release records a per-feature release audit artifact
after stable publication. The artifact records merge SHA, PR number, beta tags,
package verification, human PASS or FAIL evidence, stable tag, stable package
verification, audit mode, and completion status.

Locked-main or protected main repositories use a trailing one-file PR for the
release audit artifact. That PR contains only the per-feature release narrative
and structured release record so the audit trail can be reviewed without
direct-pushing to main.

Unlocked repositories may opt in to direct-main audit capture:

```yaml
release_audit_direct_to_main: true
```

The opt-in flag changes only where the audit artifact is committed. It does not
weaken the evidence requirements: beta verification, explicit human PASS, stable
tag, and stable package verification are still required before an audit can be
complete.

## Failure Rules

- Missing PSGallery credentials are not success.
- Missing GitHub workflow results are not success.
- Missing PR state or merge SHA is not success.
- Missing prerelease package verification is not success.
- Missing stable package verification is not success.
- Missing or ambiguous human verdict is not success.
- Explicit FAIL blocks stable publication and starts the betaN loop.
