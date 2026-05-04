# Specrew Evaluation Harness

This directory contains the evaluation harness and scorers for assessing Specrew's effectiveness.

## Evaluation Components

- **Process-quality scorer**: Evaluates artifact existence, ceremony adherence, drift detection verification (Iteration 2)
- **Outcome-quality scorer**: Evaluates requirement coverage, acceptance pass rate (Iteration 3)
- **End-to-end harness**: Full evaluation workflow (Iteration 3)

## Current Status

**Phase**: Iteration 2  
**Status**: Process-quality scorer implemented for artifact and phase adherence, with Markdown report output now available. Outcome scoring and the full end-to-end harness remain deferred.

## Available Commands

```powershell
pwsh -File .\evaluation\scorers\process-scorer.ps1 -ProjectPath . -AsJson
pwsh -File .\evaluation\scorers\process-scorer.ps1 -ProjectPath . -WriteReport
```

The scorer returns a structured result with:

- overall PASS/FAIL
- artifact-adherence findings per iteration
- phase-adherence findings per iteration
- summary counts to feed later report generation

When `-WriteReport` is used, the scorer also writes `evaluation\report.md` with:

- an overall PASS/FAIL summary
- a process-quality table for the current Iteration 2 slice
- an explicit outcome-quality placeholder marked deferred to Iteration 3
- per-iteration artifact/phase breakdown details
