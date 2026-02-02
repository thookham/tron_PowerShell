# Tron (PowerShell Edition)

A modern, modular PowerShell implementation of the classic TronScript system cleanup tool.

## Features
- **Native PowerShell**: Uses proper `Cmdlets` instead of wrapping legacy binaries where possible.
- **Modular Design**: Broken into `Modules/Stages/` for easier maintenance and contribution.
- **Robustness**: Improved error handling and logging using `Try-Catch` blocks.

## Usage
Run as Administrator:

```powershell
.\tron.ps1
```

*(Version 1.1.0)*

### Parameters
| Flag | Description |
|------|-------------|
| `-DryRun` | Simulate execution without making changes. |
| `-SkipDebloat` | Skip removal of OEM bloatware. |
| `-SkipUpdate` | Skip Windows and App updates. |
| `-Verbose` | Show detailed debug logging. |

## Structure
- `tron.ps1`: Main entry point.
- `Modules/Tron.Core.psm1`: Logging and Config logic.
- `Modules/Stages/`: Individual stage logic (e.g., `Tron.Stage2.DeBloat.psm1`).
