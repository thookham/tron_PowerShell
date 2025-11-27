# Tron PowerShell

| NAME       | Tron PowerShell, an automated PC cleanup script                                                        |
| :--------- | :------------------------------------------------------------------------------------------ |
| AUTHOR     | Refactored by Antigravity (Original by vocatus) |
| BACKGROUND | A native PowerShell port of the legendary Tron script. |

# WARNING
**This is a complete rewrite of Tron in PowerShell.** It is currently in **BETA**. Use with caution.

# CONTENTS
1. [Usage Summary](#use)
2. [Command-Line Use](#command-line-use)
3. [Requirements](#requirements)
4. [Structure](#structure)
5. [Debugging](#debugging)

# USE

0. **REBOOT THE COMPUTER BEFORE RUNNING TRON.**

1. **Download/Clone** this repository.

2. Open **PowerShell** as Administrator.

3. Run the script:
   ```powershell
   .\Tron.ps1
   ```

4. Wait for completion.

# COMMAND-LINE USE

All switches are optional.

```powershell
.\Tron.ps1 [-Autorun] [-DryRun] [-Verbose] [-SkipDebloat] [-SkipAntivirusScans] [-SkipCustomScripts] [-SkipDefrag]
```

- `-Autorun`: Run without prompts.
- `-DryRun`: Run through the script without executing any jobs (safe mode).
- `-Verbose`: Show detailed output.
- `-SkipDebloat`: Skip Stage 2 (De-bloat).
- `-SkipAntivirusScans`: Skip Stage 3 (Disinfect).
- `-SkipCustomScripts`: Skip Stage 8 (Custom Scripts).
- `-SkipDefrag`: Skip Stage 6 (Optimize).

# REQUIREMENTS

- **OS**: Windows 7 (SP1), 8, 8.1, 10, 11.
- **PowerShell**: Version 5.1 or higher.
- **Privileges**: Administrator rights recommended.
  - *Limited Mode*: If run without Admin rights, Tron will skip privileged tasks (DISM, SFC, App removal) but still perform user-level cleanup.

# STRUCTURE

The project has been reorganized for modularity:

- `Tron.ps1`: Main entry point.
- `Modules/`: PowerShell modules.
  - `Tron.Core.psm1`: Core functions (Logging, Config, State).
  - `Tron.Stages.psm1`: Logic for each execution stage.
- `Resources/`: External tools and assets.
- `Config/`: Configuration files.
  - `defaults.json`: Default settings.

# DEBUGGING

To test the script logic without affecting your system, use the `Debug-Tron.ps1` script. This script creates a local `Sandbox` folder with mock files and redirects the script to operate on that folder.

```powershell
.\Debug-Tron.ps1
```
