# T060 Local macOS Codex Smoke

This package runs the T060 Codex smoke on a maintainer-controlled Mac. It does not use a GitHub-hosted runner or a GitHub Actions provider credential. Its evidence source is always `local-machine`; the earlier T059 hosted macOS fake-provider run remains separate deterministic proof and does not become live-provider evidence.

The setup and preflight below do not invoke a model. The `Invoke` command invokes Codex exactly once and must not be run until a human grants that one slot with an exact run ID and authorization reference. There is no hidden retry.

## 1. Install and verify prerequisites

In macOS Terminal, install the current PowerShell 7.6 LTS package documented by Microsoft. This command selects the signed 7.6.3 package for Apple Silicon or Intel:

```bash
case "$(uname -m)" in
  arm64) PS_PKG_URL='https://github.com/PowerShell/PowerShell/releases/download/v7.6.3/powershell-7.6.3-osx-arm64.pkg' ;;
  x86_64) PS_PKG_URL='https://github.com/PowerShell/PowerShell/releases/download/v7.6.3/powershell-7.6.3-osx-x64.pkg' ;;
  *) echo "Unsupported architecture: $(uname -m)" >&2; exit 1 ;;
esac
curl -fL "$PS_PKG_URL" -o /tmp/powershell-7.6.3.pkg
sudo installer -pkg /tmp/powershell-7.6.3.pkg -target /
pwsh -NoProfile -Command '$PSVersionTable.PSVersion.ToString()'
```

Install Codex CLI with OpenAI's standalone macOS/Linux installer, then verify the installed CLI:

```bash
curl -fsSL https://chatgpt.com/codex/install.sh | sh
command -v codex
codex --version
```

If `command -v codex` fails, open a new Terminal so the installer-provided PATH update is active. Authenticate interactively and verify the saved authentication without submitting a task:

```bash
codex login
codex login status
```

The smoke script persists only `authenticated`, not the account, workspace, token, or the raw status output.

Official setup sources:

- <https://learn.microsoft.com/en-us/powershell/scripting/install/install-powershell-on-macos?view=powershell-7.6>
- <https://developers.openai.com/codex/cli>

## 2. Clone the exact handoff commit

Set `PINNED_COMMIT` to the 40-character provisioning commit supplied in the T060 handoff. Do not substitute the branch tip after that handoff.

```bash
PINNED_COMMIT='<PROVISIONING_COMMIT_FROM_T060_HANDOFF>'
git clone https://github.com/alonf/specrew.git
cd specrew
git fetch origin 198-beta2-hardening
git checkout --detach "$PINNED_COMMIT"
test "$(git rev-parse HEAD)" = "$PINNED_COMMIT"
test -z "$(git status --porcelain=v1 --untracked-files=all)"
```

The script independently repeats the origin URL, exact HEAD, reviewed-state digest, and clean-tree checks. It rejects an output directory inside the clone.

## 3. Run the no-spend production preflight

Choose a new external directory. Run the command directly at a native Terminal shell prompt, not as a tool command inside an interactive Codex session: Codex's command sandbox is a different containment layer and cannot establish native process-group readiness. The command fails if the directory is nonempty.

```bash
PREFLIGHT_OUT="$HOME/t060-macos-preflight-$PINNED_COMMIT"
test ! -e "$PREFLIGHT_OUT"
pwsh -NoProfile -File ./scripts/t060-local-macos-smoke.ps1 \
  -Mode Preflight \
  -RepoRoot "$PWD" \
  -ExpectedCommit "$PINNED_COMMIT" \
  -OutputDirectory "$PREFLIGHT_OUT"
```

Expected: `preflight.json` reports `provider_invoked: false`, `evidence_source: local-machine`, Codex file-primary readiness, and `macos-process-group-runtime` readiness. This step starts only the bounded process-group capability probe.

## 4. Run exactly one authorized smoke

Do not run this section until human authorization provides or covers exact values for `RUN_ID` and `AUTHORIZATION_REF`. Then run this command once from the same native Terminal shell, not by asking Codex to execute it:

```bash
RUN_ID='<RUN_ID_FROM_EXPLICIT_SLOT_GRANT>'
AUTHORIZATION_REF='<AUTHORIZATION_REF_FROM_EXPLICIT_SLOT_GRANT>'
RUN_PACKAGE="$HOME/t060-macos-$RUN_ID"
test ! -e "$RUN_PACKAGE"
pwsh -NoProfile -File ./scripts/t060-local-macos-smoke.ps1 \
  -Mode Invoke \
  -RepoRoot "$PWD" \
  -ExpectedCommit "$PINNED_COMMIT" \
  -OutputDirectory "$RUN_PACKAGE" \
  -RunId "$RUN_ID" \
  -AuthorizationRef "$AUTHORIZATION_REF" \
  -TimeoutSeconds 600 \
  -AcknowledgeProviderInvocation
```

Do not rerun the command if it returns a finding, invalid output, timeout, launch failure, or incomplete package. Preserve the directory and return it for validation; any further attempt requires a new run ID and a new explicit slot.

Package the evidence without editing it:

```bash
ditto -c -k --sequesterRsrc --keepParent "$RUN_PACKAGE" "$RUN_PACKAGE.zip"
```

## 5. Expected evidence shape

```text
t060-macos-<run-id>/
├── manifest.json
├── preflight.json
├── result.json
├── report.md
├── progress.json
├── campaign-authority.json
└── authority/
    └── campaigns/<campaign-id>/
        ├── grants/...
        ├── reservations/...
        ├── spend/...
        └── runs/<run-id>/...
```

`manifest.json` binds the local-machine platform, exact Git commit, canonical reviewed-state digest, clean-before/after facts, Codex/runtime identities, authorization reference, one observed spend, controller mode, timeout, and SHA-256 hashes of the copied preflight/result/report/progress files. The append-only authority subtree supplies the matching grant, reservation, spend, and controller-published terminal evidence.

The external `campaign-authority.json` enabled the already-implemented campaign path for this pre-cutover T060 proof while the repository's checked-in mode was still `legacy`. It is distinct from the later persisted disabled barrier and production campaign cutover.

## 6. Validate after returning the package

Unpack the directory outside the repository, then validate it from the same pinned repository commit:

```powershell
pwsh -NoProfile -File ./scripts/validate-t060-local-macos-evidence.ps1 `
  -RepoRoot "$PWD" `
  -PackagePath '<UNPACKED_RUN_PACKAGE>' `
  -ExpectedCommit '<PROVISIONING_COMMIT_FROM_T060_HANDOFF>' `
  -ExpectedRunId '<RUN_ID_FROM_EXPLICIT_SLOT_GRANT>' `
  -ExpectedAuthorizationRef '<AUTHORIZATION_REF_FROM_EXPLICIT_SLOT_GRANT>'
```

`package_valid: true` means the closed shapes, hashes, source attribution, Git identity, result contract, copied authority evidence, grant, reservation, and exactly one spend agree. `smoke_clean: true` additionally requires a complete/pass/current/valid result, verified containment and termination, and zero findings. A valid findings result intentionally returns `package_valid: true` and `smoke_clean: false`; it remains useful evidence, but work stops for human review instead of calling the smoke clean or rerunning it.

The validator requires the clean pinned checkout as a separate input, verifies its origin and exact `HEAD`, recomputes its canonical reviewed-state digest, and compares that independent value with the manifest, preflight, result, and authority evidence. Agreement inside the returned package alone is not sufficient.
