# Quickstart: Full Antigravity Refocus Validation

This quickstart is for review and release validation, not ordinary user setup.

## Local Automated Checks

```powershell
pwsh -NoProfile -File tests/bootstrap/HostEventAdapter.Tests.ps1
pwsh -NoProfile -File tests/bootstrap/SessionStateAccessor.Tests.ps1
pwsh -NoProfile -File tests/bootstrap/ClassificationEngine.Tests.ps1
pwsh -NoProfile -File tests/bootstrap/SessionBootstrapManager.Tests.ps1
pwsh -NoProfile -File tests/integration/refocus-dispatcher.tests.ps1
pwsh -NoProfile -File tests/integration/refocus-deploy.tests.ps1
pwsh -NoProfile -File tests/integration/specrew-hooks-command.tests.ps1
```

## Real-Host Antigravity Checks

Run from a scratch Specrew project after deploying hooks:

```powershell
specrew hooks install --host antigravity
agy
```

Required manual evidence:

- `PreInvocation` fires and receives stable `conversationId`.
- B3 injects once on real lifecycle boundary crossing.
- B3 does not inject on ordinary non-boundary turns.
- current Antigravity marker does not emit concurrency advisory.
- real competing marker still emits concurrency advisory.
- `Stop` writes handover.
- `agy --conversation <id>` resumes with the same state identity.

## Documentation Checks

Review these user-facing surfaces:

- `README.md`
- `docs/getting-started.md`
- `docs/user-guide.md`
- `docs/api-reference.md`
- `docs/troubleshooting.md`

They must include:

- `agy`
- hook install/remove
- `/permissions`
- `enableTerminalSandbox`
- `specrew start --host antigravity` recovery
- evidence-gated support labels

## Release Checks

Before stable:

- beta tag and publish happened first
- beta install validation passed
- legacy existing-config upgrade path passed
- no full/verified/stable Antigravity claim was made before evidence existed
