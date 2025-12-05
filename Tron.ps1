<#
.SYNOPSIS
    Tron - Automated cleaning and disinfection tool (PowerShell Edition)
.DESCRIPTION
    Tron is a script that automates a wide variety of system cleaning, disinfection, and repair tasks.
    This is the modern PowerShell rewrite of the classic batch script.
.PARAMETER DryRun
    Skip actual execution of tasks.
.PARAMETER Verbose
    Enable verbose logging.
.PARAMETER SkipDebloat
    Skip OEM bloatware removal.
#>
param (
    [switch]$DryRun,
    [switch]$Verbose,
    [switch]$Autorun,
    [switch]$SkipDebloat,
    [switch]$SkipUpdate,
    [switch]$PreserveMetroApps
)

# --- Initialization ---
$ErrorActionPreference = "Stop"
$ScriptDir = $PSScriptRoot

# Import Modules
Import-Module "$ScriptDir\Modules\Tron.Core.psm1" -Force
Import-Module "$ScriptDir\Modules\Tron.Stages.psm1" -Force

# --- Configuration & Logging ---
try {
    $Config = Get-TronConfig
    Write-TronLog "Config Type: $($Config.GetType().FullName)" "INFO"
    Write-TronLog "Config Members: $($Config | Get-Member | Out-String)" "INFO"
    
    # Override Config with Parameters
    if ($DryRun) { $Config.DryRun = $true }
    if ($Verbose) { $Config.Verbose = $true }
    if ($Autorun) { $Config.Autorun = $true }
    if ($SkipDebloat) { $Config.SkipDebloat = $true }
    if ($SkipUpdate) { $Config.SkipUpdate = $true }
    if ($PreserveMetroApps) { $Config.PreserveMetroApps = $true }

    Initialize-TronLogging -LogPath $Config.LogFile
}
catch {
    Write-Host "Critical Error during initialization: $_" -ForegroundColor Red
    exit 1
}

Write-TronLog "Tron PowerShell Edition v1.0.1 Initialized"
Write-TronLog "Command Line Args: $PSBoundParameters" "DEBUG"

# --- OS & Prerequisite Checks ---
Write-TronLog "Checking prerequisites..."

# OS Check (Windows 7 SP1+)
$OS = Get-CimInstance Win32_OperatingSystem
if ($OS.Version -lt "6.1.7601") {
    Write-TronLog "Unsupported OS. Tron requires Windows 7 SP1 or later." "ERROR"
    exit 1
}
Write-TronLog "OS Detected: $($OS.Caption) ($($OS.Version))"

# Admin Check
if (-not (Test-IsAdmin)) {
    Write-TronLog "Tron is NOT running as Administrator." "WARN"
    Write-TronLog "Attempting to run in Limited Mode (some tasks will be skipped)." "WARN"
    $Global:TronState.Mode = "Limited"
}
else {
    Write-TronLog "Running as Administrator."
    $Global:TronState.Mode = "Standard"
}

if ($Config.DryRun) {
    Write-TronLog "!!! DRY RUN MODE ENABLED - NO CHANGES WILL BE MADE !!!" "WARN"
    $Global:TronState.Mode = "DryRun"
}

# --- Execution ---
try {
    # Stage 0: Prep
    Invoke-Stage0

    # Stage 1: TempClean
    Invoke-Stage1

    # Stage 2: De-bloat
    if (-not $Config.SkipDebloat) {
        Invoke-Stage2
    }
    else {
        Write-TronLog "Skipping Stage 2 (De-bloat) per config."
    }

    # Stage 3: Disinfect
    Invoke-Stage3

    # Stage 4: Repair
    Invoke-Stage4

    # Stage 5: Patch
    if (-not $Config.SkipUpdate) {
        Invoke-Stage5
    }
    else {
        Write-TronLog "Skipping Stage 5 (Patch) per config."
    }

    # Stage 6: Optimize
    Invoke-Stage6

    # Stage 7: Wrap-up
    Invoke-Stage7

    # Stage 8: Custom Scripts
    Invoke-Stage8

}
catch {
    Write-TronLog "Fatal Error during execution: $_" "ERROR"
    Write-TronLog "Stack Trace: $($_.ScriptStackTrace)" "DEBUG"
    exit 1
}

Write-TronLog "Tron execution complete."
exit 0
