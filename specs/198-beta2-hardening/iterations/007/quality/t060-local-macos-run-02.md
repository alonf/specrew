# T060 Local-macOS Codex Smoke — Correction Run 02

**Schema**: v1

**Evidence source**: local-machine execution returned by the maintainer

**Platform**: macOS 15.5 x64, Intel Mac with 8 GB RAM

**Commit**: `b1ae8b47aece4e0f4a017dc1e8896708fc2c8700`

**Canonical reviewed-state digest**: `7dcc6b4da0bf006f24b7c8fa5ed08c56fa42704c`

**Run**: `run-t060-codex-macos-b1ae8b47-02`

**Authorization reference**: `standing-mac-grant-20260717-attempt-02`

**Harness/runtime**: `codex-cli-file-primary` / `macos-process-group-runtime`

**Provider invocations**: exactly one for this run; no hidden retry
**Result**: clean

## Provenance

The maintainer ran the package directly from native Terminal in a new clean detached worktree. The no-spend preflight reported authenticated Codex CLI `0.144.5`, ready file-primary and process-group ports, exact origin/commit, a clean tree, and `provider_invoked=false`. The live run then terminalized after 210898 ms with verified containment and termination. The independently rerun package validator exited `0` and reported `package_valid=true`, `smoke_clean=true`, and no errors.

The immutable returned ZIP remains on the maintainer-controlled Mac at `/Users/alon/t060-macos-run-t060-codex-macos-b1ae8b47-02.zip`. Its reported SHA-256 is:

```text
9e359c121ffae46bb24ed8761749a11492a7d58adad4591f43a3e703d6d09351
```

Because the Mac is an older 8 GB Intel machine reached through a slow web clipboard, this repository record preserves the exact digest-bound terminal result and independent validation output returned by the maintainer rather than requiring another transfer or provider run. The ZIP remains the immutable source package; this file is its human-returned evidence record.

## Independent package-validation output

```json
{
  "schema_version": "1.0",
  "package_valid": true,
  "smoke_clean": true,
  "evidence_source": "local-machine",
  "head_commit": "b1ae8b47aece4e0f4a017dc1e8896708fc2c8700",
  "target_digest": "7dcc6b4da0bf006f24b7c8fa5ed08c56fa42704c",
  "campaign_id": "cmp-198-beta2-hardening-i007",
  "run_id": "run-t060-codex-macos-b1ae8b47-02",
  "verdict": "pass",
  "finding_count": 0,
  "errors": []
}
```

## Authoritative result returned from `result.json`

```json
{"campaign_id":"cmp-198-beta2-hardening-i007","can_approve_current":true,"completion":"complete","containment":"verified","currentness":"current","duration_ms":210898,"ended_at":"2026-07-17T11:57:44.1632150+00:00","failure_reason":null,"findings":[],"harness_id":"codex-cli-file-primary","run_id":"run-t060-codex-macos-b1ae8b47-02","runtime_outcome":"completed","schema_version":"1.0","started_at":"2026-07-17T11:54:26.7047550+00:00","summary":"Reviewed the frozen target, including the T060 macOS evidence validator and campaign design-context changes. No grounded code-review findings identified.","target_digest":"7dcc6b4da0bf006f24b7c8fa5ed08c56fa42704c","termination_verified":true,"validation":"valid","verdict":"pass"}
```

The shell reported `Invoke exit: 0; validation exit: 0`. Run 01 remains immutable partial evidence; this correction run closes its two findings without modifying or promoting the earlier result.
