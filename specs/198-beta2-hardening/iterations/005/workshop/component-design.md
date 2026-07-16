# Component-design reassessment

**Status**: complete
**Iteration**: 005

## Confirmed decomposition method

Retain the state-machine core with ports and adapters. Review policy remains stable while Git, operating systems, target types, and five reviewer CLIs vary. The names below are logical responsibility boundaries, not a requirement for one class or file per component.

## Confirmed component map

```text
Interface / consumers
+---------------+       +---------------------+
| ReviewCommand |       | RetroEvidenceReader |
+-------+-------+       +----------+----------+
        |                          |
        v                          v
Application
+---------------------------+    +----------------------+
| ReviewCampaignCoordinator |--->| ReviewRunCoordinator |
+---------------------------+    +----------+-----------+
                                           |
                                   +-------+--------+
                                   | ResultIngestor |
                                   +-------+--------+
                                           |
                                           v
Core
+----------------------+  +-----------------------+
| ReviewCampaignPolicy |  | ReviewRunStateMachine |
+----------------------+  +-----------------------+
+------------------------+ +----------------------+
| ResultAcceptancePolicy | | FindingLineagePolicy |
+------------------------+ +----------------------+
                 ^ application depends inward
                 |
Ports
+--------------------+ +-----------------+ +----------------+
| CampaignRepository | | RunRepository   | | ClaimRepository|
+--------------------+ +-----------------+ +----------------+
+------------------+ +----------------+ +-----------------+ +---------+
| ReviewTargetPort | | HarnessPort    | | RuntimePort     | |ClockPort|
+------------------+ +----------------+ +-----------------+ +---------+
          ^                  ^                  ^                ^
          |                  |                  |                |
Infrastructure adapters
+----------------+  +---------------------+  +-----------------------+
| JsonReviewStore|  | GitWorktreeTarget   |  | ReviewerHostCatalog   |
+----------------+  +---------------------+  +-----------+-----------+
                                                        |
                    +------------+----------+------------+-----------+
                    |            |          |            |           |
                 Claude        Codex     Copilot       Cursor   Antigravity
                 Adapter       Adapter    Adapter       Adapter    Adapter

+-------------------------+  +----------------------+  +------------------------+
| WindowsJobObjectRuntime |  | LinuxCgroupRuntime   |  | MacProcessGroupRuntime |
+-------------------------+  +----------------------+  +------------------------+
                                              +-------------+
                                              | SystemClock |
                                              +-------------+

Test-only proof
+-----------------------------+  +----------------------------+
| NonCodeTargetContractFixture|  | ReviewerExecutableFixture  |
+-----------------------------+  +----------------------------+
```

## Named responsibilities

### Interface and consumers

- `ReviewCommand` — starts, monitors, and reports campaigns and runs through the CLI.
- `RetroEvidenceReader` — exposes deduplicated validated findings and provenance to retrospective generation without parsing Markdown.

### Application

- `ReviewCampaignCoordinator` — manages target lineage, human-granted allowance, reservations, and permitted reruns.
- `ReviewRunCoordinator` — sequences one snapshot, claim, invocation, termination, ingestion, and publication workflow.
- `ResultIngestor` — validates candidate schema and identity, imports partial or complete findings, and publishes the terminal machine result and Markdown report.

### Core

- `ReviewCampaignPolicy` — decides whether another run is permitted from grants, reservations, and spend.
- `ReviewRunStateMachine` — defines legal lifecycle states and transitions for exactly one invocation.
- `ResultAcceptancePolicy` — determines completeness, verdict applicability, snapshot movement, and whether a result may approve the current target.
- `FindingLineagePolicy` — links likely matching findings across partial, complete, moved-snapshot, and rerun results.

### Port contracts

- `CampaignRepository` — sole logical mutation path for campaign allowance and selection facts.
- `RunRepository` — sole logical mutation path for run lifecycle, result, validation, and classification facts.
- `ClaimRepository` — atomically acquires and retires immutable lineage-claim generations.
- `ReviewTargetPort` — freezes and identifies code, gate, or artifact targets without making the core code-specific.
- `HarnessPort` — translates a common review invocation to a supported reviewer and returns candidate output.
- `RuntimePort` — launches, monitors, times out, and terminates the complete external process tree.
- `ClockPort` — supplies production-observed time and deterministic test time with explicit provenance.

### Infrastructure adapters

- `JsonReviewStore` — implements the three repository contracts using unique immutable JSON facts and atomic creation.
- `GitWorktreeTarget` — creates the external frozen worktree and computes currentness identity.
- `ReviewerHostCatalog` — remains the single harness-data seam for executable, launch profile, contract support, and runtime defaults.
- `ClaudeAdapter` — implements native Claude Code invocation and output capture.
- `CodexAdapter` — implements native Codex CLI invocation and output capture.
- `CopilotAdapter` — implements native GitHub Copilot CLI invocation and output capture.
- `CursorAdapter` — implements native Cursor Agent invocation and output capture.
- `AntigravityAdapter` — implements native Antigravity invocation and output capture.
- `WindowsJobObjectRuntime` — enforces Windows process-tree lifecycle control.
- `LinuxCgroupRuntime` — enforces Linux process-tree lifecycle control.
- `MacProcessGroupRuntime` — enforces macOS-native process-tree lifecycle control through a conformance-proven process-group mechanism.
- `SystemClock` — records UTC timestamps and monotonic durations as directly observed production evidence.

### Test-only proof

- `NonCodeTargetContractFixture` — proves the target port is not secretly code-review-specific.
- `ReviewerExecutableFixture` — deterministically exercises every adapter's timeout, malformed-result, identity, and termination behavior without AI cost.

## Agreed flows

Successful review:

```text
ReviewCommand
 -> ReviewCampaignCoordinator reserves allowance
 -> ReviewRunCoordinator freezes target and acquires claim
 -> selected HarnessAdapter builds native invocation
 -> RuntimeAdapter supervises reviewer
 -> ResultIngestor validates and publishes result
 -> ResultAcceptancePolicy classifies applicability
 -> claim released and CLI reports outcome
 -> RetroEvidenceReader later exposes finding lineage
```

Timeout and rerun:

```text
RuntimeAdapter reaches deadline
 -> kills and verifies process tree
 -> ResultIngestor captures valid partial findings
 -> publishes incomplete timed-out result
 -> ReviewRunCoordinator releases claim
 -> ReviewCampaignCoordinator schedules a separately authorized rerun
```

## Human agreement

The maintainer reviewed and accepted the complete rendered component map, named responsibilities, dependency direction, successful-review flow, and timeout/rerun flow without requested renames, merges, splits, or reassignments.

During the requirements/NFR pass, the declared macOS product support exposed an omitted runtime responsibility. The maintainer confirmed adding `MacProcessGroupRuntime` alongside the Windows and Linux runtime adapters, with observable complete-tree termination as its requirement and the exact native mechanism subject to conformance proof.
