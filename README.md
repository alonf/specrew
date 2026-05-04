# Specrew — Spec-Governed AI Crew Operating Model

Specrew is a spec-governed operating model for AI crews that combines [Spec Kit](https://github.com/microsoft/copilot-specify) as the specification/governance layer with [Squad](https://github.com/microsoft/copilot-squad) as the persistent multi-agent runtime layer.

## Status

**Current Phase**: MVP Closeout (Iteration 1a complete, Iteration 1b in progress)  
**Branch**: `001-specrew-product`  
**Version**: Pre-MVP Development

## What is Specrew?

Specrew ensures AI agent teams build what was specified by:

- Making the **spec** the authoritative source of truth
- Providing **structured iteration delivery** with planning, execution, review/demo, and retrospective ceremonies
- Detecting and surfacing **drift** when implementation diverges from specification
- Enabling **traceability** from requirements to tasks to implementation
- Supporting **governance** through roles, capacity planning, and retrospectives

## Architecture

Specrew integrates with Spec Kit and Squad using their native extension surfaces:

1. **Spec Kit Extension** (`extensions/specrew-speckit/`) — Governance artifacts, templates, validation scripts, and Squad-native template sources
2. **Squad Integration** — Skills deployed to `.copilot/skills/specrew-*/`, ceremonies registered in `.squad/ceremonies.md`, directives merged into agent charters, and a coordinator prompt overlay that forces Squad to route formal work through the Spec-Kit + Specrew artifact lifecycle

Specrew v1 uses **Squad-native surfaces** rather than a packaged plugin. The `specrew init` command deploys Squad templates from `extensions/specrew-speckit/squad-templates/` to the appropriate Squad runtime locations.

The repository also includes a governance validator that enforces the iteration lifecycle contract against Markdown artifacts:

```powershell
pwsh -File .\extensions\specrew-speckit\scripts\validate-governance.ps1 -ProjectPath .
```

This validator is intended to fail invalid iteration transitions such as entering review without a drift log or marking an iteration complete without a retrospective artifact.

## Repository Structure

```text
extensions/
  └─ specrew-speckit/      # Spec Kit extension
      ├─ hooks/            # Spec Kit lifecycle hooks
      ├─ templates/        # Governance artifact templates
      ├─ scripts/          # Validation and scaffolding scripts
      └─ squad-templates/  # Squad-native template sources
          ├─ skills/       # Skill templates (deployed to .copilot/skills/specrew-*/)
          ├─ ceremonies/   # Ceremony templates (appended to .squad/ceremonies.md)
          └─ directives/   # Directive templates (merged into agent charters)
specs/                     # Feature specifications and iteration plans
tests/                     # Test suites
evaluation/                # Evaluation harness and scorers
docs/                      # Documentation
.github/                   # GitHub workflows and templates
```

## Getting Started

Specrew is currently under active development.

Practical docs for current workflows:

- `docs/getting-started.md` (greenfield + brownfield bootstrap)
- `docs/user-guide.md` (planning, execution, review/demo, retro, drift handling)

`specrew init` installs a deterministic baseline Squad crew — Spec Steward, Planner, Implementer, Reviewer, and Retro Facilitator. Add any extra domain-specific members afterward using Specrew's team management commands:

```powershell
# Add a new domain-specific member
pwsh -File C:\Dev\Specrew\scripts\specrew.ps1 team add security-analyst `
  --role "Security Analyst" `
  --charter "Review code for security vulnerabilities, ensure secure coding practices."

# List all team members
pwsh -File C:\Dev\Specrew\scripts\specrew.ps1 team list

# Update a member's charter
pwsh -File C:\Dev\Specrew\scripts\specrew.ps1 team update security-analyst `
  --charter "Updated charter text..."

# Remove a domain-specific member
pwsh -File C:\Dev\Specrew\scripts\specrew.ps1 team remove security-analyst
```

Replace `C:\Dev\Specrew` with the actual path where you cloned the Specrew repository.

After bootstrap, the canonical downstream entrypoint is:

```powershell
pwsh -File C:\Dev\Specrew\scripts\specrew.ps1 start "Build a REST API for user management"
```

`specrew start` prepares the Squad handoff, launches Copilot CLI when available, and tells Squad to run the full Spec Kit lifecycle (`specify`, `clarify` when needed, `plan`, `tasks`, `implement`) with the human developer mainly answering only unresolved questions. You can pass a short plain-language feature request, or run `specrew start` with no arguments and let Squad inspect current progress, continue in-flight work, or ask what feature/fix to take next. To reduce Copilot CLI blocking on approval prompts, Specrew launches from the target project directory and defaults to `--allow-all`; use `--prompt-approvals` if you want Copilot to pause for interactive approvals. Copilot may still ask you to trust the project directory on first launch.

### Optional: Adding Specrew to PATH

For convenience, you can add the Specrew scripts directory to your PATH to use short commands like `specrew team list` instead of typing the full path each time.

**Current Session Only** (temporary, lost when shell closes):
```powershell
$env:PATH = "$env:PATH;C:\Dev\Specrew\scripts"
```

**Persistent** (all future sessions):
```powershell
$currentPath = [Environment]::GetEnvironmentVariable("PATH", "User")
$pathEntries = $currentPath -split ";"
if ($pathEntries -notcontains "C:\Dev\Specrew\scripts") {
    [Environment]::SetEnvironmentVariable("PATH", "$currentPath;C:\Dev\Specrew\scripts", "User")
    Write-Host "Added Specrew scripts to user PATH. Restart your shell to apply." -ForegroundColor Green
}
```

After adding to PATH persistently, restart your PowerShell session, then use the short form:
```powershell
specrew start
specrew start "Build a REST API for user management"
specrew team list
specrew team add my-specialist --role "Role" --charter "Charter text"
```

The commands atomically create all required Squad artifacts (team.md entry, charter.md, history.md) while protecting baseline roles.

**GitHub Project Board**: [Specrew Project](https://github.com/users/alonf/projects/10)  
**Board sync**: `.github/workflows/specrew-project-sync.yml` mirrors iteration artifacts to issues and board status. The workflow is operational and syncs automatically on push to iteration artifacts.

Iteration 1a core MVP work is complete; Iteration 1b closeout is focused on documentation and validation follow-through.

## Development

This project uses:

- **Spec Kit** >= 0.8.4 for specification governance
- **Squad** >= 0.9.1 for multi-agent orchestration
- Markdown, YAML, and PowerShell for extension assets

## License

TBD

## Contributing

Contribution guidelines will be established post-MVP.
