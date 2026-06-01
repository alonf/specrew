# Review Diagrams: Iteration 001 — Session Mode Configuration & File Classification

**Schema**: v1
**Diagram Format**: mermaid

> **Review-evidence integrity note:** the scaffolder's Form-vs-Meaning warning (19 tasks vs 20 files) is a verified false positive — all work is committed (HEAD `4141a892` == origin). The auto-omitted placeholder diagrams have been replaced with substantive ones below.

## Structure Diagram (Iteration-1 modules)

```mermaid
graph TD
  CLI["specrew.ps1 (dispatch switch)"] -->|config case| CFG["specrew-config.ps1"]
  CFG --> SC["internal/session-config.ps1<br/>Get/Set-SessionMode"]
  SC --> ATOMIC["Write-SpecrewFileAtomic<br/>(temp + Move-Item -Force)"]
  SC --> CONFIG[".specrew/config.yml<br/>session_mode"]
  INIT["specrew-init.ps1"] --> SCAF["scaffold-governance.ps1<br/>(both mirrors)"]
  SCAF --> CONFIG
  INIT --> FC["internal/file-classification.ps1<br/>Get-FileClassification /<br/>Update-GitignoreForSession /<br/>Remove-TrackedPerSessionFiles"]
  FC --> GI[".gitignore"]
  FC --> IDX["git index (rm --cached)"]
```

## Flow: `specrew config set session_mode multi` (FR-001/002)

```mermaid
sequenceDiagram
  participant User
  participant Dispatch as specrew.ps1
  participant Cmd as specrew-config.ps1
  participant Helper as session-config.ps1
  participant Config as .specrew/config.yml
  User->>Dispatch: specrew config set session_mode multi
  Dispatch->>Dispatch: Assert-ProjectSetup + slash-compat guard
  Dispatch->>Cmd: route (set, session_mode, multi)
  Cmd->>Helper: Set-SessionMode(multi)
  alt valid (single|multi)
    Helper->>Config: atomic write (temp + Move-Item -Force)
    Helper-->>Cmd: 'multi'
    Cmd-->>User: "session_mode set to 'multi'." (exit 0)
  else invalid value
    Helper-->>Cmd: throw
    Cmd-->>User: ERROR + usage (exit 1, no mutation)
  end
```

## Flow: `specrew init` per-session file classification (FR-005/006)

```mermaid
sequenceDiagram
  participant Init as specrew-init.ps1
  participant Scaffold as scaffold-governance.ps1
  participant FC as file-classification.ps1
  participant GI as .gitignore
  participant Git as git index
  Init->>Scaffold: scaffold governance
  Scaffold->>Scaffold: write config.yml (session_mode: single, FR-003)
  Init->>FC: Update-GitignoreForSession (FR-005)
  FC->>GI: merge missing per-session patterns (idempotent, preserve existing)
  Init->>FC: Remove-TrackedPerSessionFiles (FR-006)
  FC->>Git: git rm --cached <tracked per-session paths>
  Note over FC,Git: working-tree copies kept; no-op outside a git repo
```
