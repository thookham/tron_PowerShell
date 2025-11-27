| NAME       | Tron PowerShell, an automated PC cleanup script                                                        |
| :--------- | :------------------------------------------------------------------------------------------ |
| AUTHOR     | Antigravity |
| BACKGROUND | A native PowerShell port of the legendary Tron script. |

# 🚀 POWERED BY POWERSHELL

> [!NOTE]
> This is a **complete rewrite** of Tron in native PowerShell. It is designed to be faster, more modular, and easier to maintain than the original legacy batch script.
> **Edits powered by Google Gemini Antigravity.**

This PowerShell version includes several key improvements:

-   **⚡ Native Performance**: Leverages the full power of the .NET framework for faster execution and better resource management.
-   **🧩 Modular Design**: Code is organized into distinct modules (`Core`, `Stages`), making it easier to read, debug, and extend.
-   **🛡️ Enhanced Safety**: Better error handling and "Dry Run" capabilities allow you to test the script without making changes.
-   **🧪 Sandbox Mode**: Includes a `Debug-Tron.ps1` script to safely test logic in a local sandbox environment.
-   **🔒 Privacy Focused**: Repository has been scrubbed of personal metadata and git history anonymized for privacy.

---

# 📖 CONTENTS

1.  [Usage Summary](#-use)
2.  [Command-Line Use](#-command-line-use)
3.  [Requirements](#-requirements)
4.  [Project Structure](#-project-structure)
5.  [Debugging & Development](#-debugging--development)
6.  [Full Description of Stages](#-full-description-of-stages)

---

# 🛠️ USE

0.  **FIRST THINGS FIRST**: **REBOOT THE COMPUTER BEFORE RUNNING TRON.** This is to allow any pending updates to finish.

1.  **Download/Clone**: Get the repository to your local machine.

2.  **Open PowerShell**: Right-click the Start button and select **PowerShell (Admin)** or **Terminal (Admin)**.

3.  **Run the Script**:
    ```powershell
    .\Tron.ps1
    ```

4.  **Wait**: The script will proceed through the stages automatically.

    > [!WARNING]
    > **DO NOT CANCEL THE SCRIPT** once it has started Stage 2 (De-bloat) or Stage 3 (Disinfect), as this may leave the system in an inconsistent state.

5.  **Reboot**: Reboot the system once the script completes.

---

# 💻 COMMAND-LINE USE

Command-line use is fully supported. All switches are optional.

```powershell
.\Tron.ps1 [-Autorun] [-DryRun] [-Verbose] [-SkipDebloat] [-SkipAntivirusScans] [-SkipCustomScripts] [-SkipDefrag]
```

| Switch | Description |
| :--- | :--- |
| `-Autorun` | Run automatically without prompts (implies acceptance of all defaults). |
| `-DryRun` | **Safe Mode**. Run through the script logic without actually executing any jobs or making changes. |
| `-Verbose` | Show detailed output for debugging purposes. |
| `-SkipDebloat` | Skip **Stage 2: De-bloat** (OEM bloatware removal). |
| `-SkipAntivirusScans` | Skip **Stage 3: Disinfect** (Malwarebytes, AdwCleaner, etc.). |
| `-SkipCustomScripts` | Skip **Stage 8: Custom Scripts**. |
| `-SkipDefrag` | Skip **Stage 6: Optimize** (Defrag). |

---

# 📋 REQUIREMENTS

-   **OS**: Windows 7 (SP1), 8, 8.1, 10, 11.
-   **PowerShell**: Version 5.1 or higher (Pre-installed on Windows 10/11).
-   **Privileges**: **Administrator rights** are highly recommended.
    -   *Limited Mode*: If run without Admin rights, Tron will skip privileged tasks (DISM, SFC, App removal) but still perform user-level cleanup.

---

# 📂 PROJECT STRUCTURE

The project has been reorganized for modularity and ease of contribution:

-   `Tron.ps1`: **Main Entry Point**. Orchestrates the execution flow.
-   `Modules/`: Contains the logic for the script.
    -   `Tron.Core.psm1`: Core functions (Logging, Configuration, State management).
    -   `Tron.Stages.psm1`: Specific logic for each execution stage (Prep, TempClean, De-bloat, etc.).
-   `Resources/`: External tools and assets (e.g., `rkill`, `AdwCleaner`).
-   `Config/`: Configuration files.
    -   `defaults.json`: Default settings and preferences.

---

# 🐞 DEBUGGING & DEVELOPMENT

To test the script logic without affecting your actual system, use the `Debug-Tron.ps1` script.

**How it works:**
1.  Creates a local `Sandbox` folder in the project root.
2.  Populates it with mock files and directories.
3.  Redirects `Tron.ps1` to operate *only* within this Sandbox.

```powershell
.\Debug-Tron.ps1
```

This is perfect for testing new features or verifying that file cleanup logic works as expected.

---

# 📜 FULL DESCRIPTION OF STAGES

Here is a breakdown of what each stage does in the PowerShell version:

## 🟢 STAGE 0: Prep
-   **System Restore**: Attempts to create a system restore point.
-   **Rkill**: Runs Rkill to terminate known malware processes.
-   **Process Killer**: Terminates interfering userland processes.
-   **SMART Check**: Checks hard drive health.

## 🧹 STAGE 1: TempClean
-   **Temp Files**: Cleans Windows temp folders, browser caches, and other temporary locations.
-   **Event Logs**: Backs up and clears Windows Event Logs.
-   **Windows Update Cache**: Clears old Windows Update files to free space.

## 🗑️ STAGE 2: De-bloat
-   **OEM Bloatware**: Removes common pre-installed bloatware based on a curated list.
-   **Metro Apps**: Removes unused Windows Store (Metro) apps.

## 🦠 STAGE 3: Disinfect
-   **Malwarebytes**: Installs and runs Malwarebytes Anti-Malware.
-   **AdwCleaner**: Runs Malwarebytes AdwCleaner to remove adware and PUPs.
-   **KVRT**: Runs Kaspersky Virus Removal Tool.

## 🛠️ STAGE 4: Repair
-   **DISM**: Checks and repairs the Windows Image Store.
-   **SFC**: Runs System File Checker to repair corrupted system files.
-   **Telemetry**: Disables Windows telemetry and tracking features.
-   **Network**: Resets network stack (Winsock, DNS cache).

## 🩹 STAGE 5: Patch
-   **Windows Updates**: Triggers Windows Update to find and install missing patches.
-   **7-Zip**: Installs or updates 7-Zip.

## 🚀 STAGE 6: Optimize
-   **Defrag**: Defragments mechanical drives (skips SSDs).
-   **Page File**: Resets page file settings to Windows defaults.

## 🏁 STAGE 7: Wrap-up
-   **Report**: Generates a summary report of actions taken.
-   **Cleanup**: Removes temporary tools and files used by Tron.

## 🔧 STAGE 8: Custom Scripts
-   **User Scripts**: Executes any custom `.bat` or `.ps1` scripts placed in the `Resources\Stage_8_Custom_Scripts` folder.
