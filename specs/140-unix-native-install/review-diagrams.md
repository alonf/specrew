# Review Diagrams: Unix-Native Install & Command Surface

**Feature**: 140-unix-native-install
**Phase**: pre-implementation (planning artifact for reviewer)

## Component diagram

```mermaid
flowchart LR
  Registry[Specrew.psd1 AliasesToExport + root specrew] --> Generator[generate-shell-wrappers.ps1\nsource of truth]
  Generator --> Bin[bin/ committed wrappers]
  Generator -. CI regenerate + diff .-> Bin
  Bin --> FileList[Specrew.psd1 FileList]
  Bin --> Installer[specrew install-shell-wrappers]
  Installer --> UserBin[~/.local/bin]
  Bootstrap[install.sh] --> Module[Install-Module Specrew]
  Module --> Installer
  UserBin --> Wrapper[bin wrapper on PATH]
  Wrapper --> Pwsh[pwsh -File scripts/specrew*.ps1]
  Registry -. parity cascade .-> FileList
  Registry -. parity cascade .-> Docs[docs examples]
```

## Sequence: end-user bootstrap then native command

```mermaid
sequenceDiagram
  participant User
  participant Bootstrap as install.sh
  participant Pwsh as pwsh
  participant Installer as install-shell-wrappers
  participant Wrapper as ~/.local/bin/specrew
  User->>Bootstrap: curl ... | sh
  Bootstrap->>Bootstrap: verify pwsh present (else abort + hint)
  Bootstrap->>Pwsh: Install-Module Specrew
  Bootstrap->>Installer: specrew install-shell-wrappers
  Installer->>Wrapper: copy committed bin/ wrappers (warn if not on PATH)
  User->>Wrapper: specrew version
  Wrapper->>Wrapper: resolve module root (follow symlinks); verify pwsh
  Wrapper->>Pwsh: exec pwsh -File scripts/specrew.ps1 version "$@"
  Pwsh-->>User: version output (exit 0)
```

## Sequence: pwsh missing (failure path)

```mermaid
sequenceDiagram
  participant User
  participant Wrapper as ~/.local/bin/specrew
  User->>Wrapper: specrew version
  Wrapper->>Wrapper: command -v pwsh  (not found)
  Wrapper-->>User: "PowerShell Core (pwsh) is required" + install hint, exit non-zero
```
