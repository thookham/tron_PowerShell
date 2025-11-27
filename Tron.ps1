# Tron.ps1
# Main entry point for Tron PowerShell

param (
    [switch]$Autorun,
    [switch]$DryRun,
    [switch]$Verbose,
    [switch]$SkipDebloat,
    [switch]$SkipAntivirusScans,
    [switch]$SkipCustomScripts,
    [switch]$SkipDefrag
)

# --- Initialization ---
$ErrorActionPreference = "Continue"
$ScriptPath = $PSScriptRoot
$ResourcesPath = Join-Path $ScriptPath "Resources"
$ModulesPath = Join-Path $ScriptPath "Modules"

# Import Modules
Import-Module (Join-Path $ModulesPath "Tron.Core.psm1") -Force
Import-Module (Join-Path $ModulesPath "Tron.Stages.psm1") -Force

# Load Config
$Config = Get-TronConfig

# Override Config with Flags
if ($DryRun) { $Config.DryRun = $true }
if ($Verbose) { $Config.Verbose = $true }
if ($SkipDebloat) { $Config.SkipDebloat = $true }
if ($SkipAntivirusScans) { $Config.SkipAntivirusScans = $true }
if ($SkipCustomScripts) { $Config.SkipCustomScripts = $true }
if ($SkipDefrag) { $Config.SkipDefrag = $true }

# Setup Logging
$LogFile = Join-Path $Config.LogPath ("tron_" + (Get-Date -Format "yyyy-MM-dd_HH-mm-ss") + ".log")
if (-not (Test-Path $Config.LogPath)) { New-Item -ItemType Directory -Path $Config.LogPath -Force | Out-Null }
Start-Transcript -Path $LogFile -Append

Write-TronLog "Tron PowerShell v1.0.0" "INFO"
Write-TronLog "Log File: $LogFile" "INFO"

# --- OS & Environment Checks ---
$OSVersion = [Environment]::OSVersion.Version
Write-TronLog "OS Version: $OSVersion" "INFO"

if ($OSVersion.Major -lt 6 -or ($OSVersion.Major -eq 6 -and $OSVersion.Minor -lt 1)) {
    Write-TronLog "Unsupported OS. Windows 7 SP1 or higher is required." "ERROR"
    Stop-Transcript
    exit 1
}

$PSVersion = $PSVersionTable.PSVersion
Write-TronLog "PowerShell Version: $PSVersion" "INFO"

if ($PSVersion.Major -lt 5 -or ($PSVersion.Major -eq 5 -and $PSVersion.Minor -lt 1)) {
    Write-TronLog "Unsupported PowerShell Version. 5.1 or higher is required." "ERROR"
    Stop-Transcript
    exit 1
}

# --- Privilege Check ---
if (Test-IsAdmin) {
    Write-TronLog "Running as Administrator." "SUCCESS"
    $Global:TronMode = "Full"
}
else {
    Write-TronLog "Not running as Administrator." "WARNING"
    # Attempt Elevation
    # Note: In a real scenario, we might want to prompt the user before elevating.
    # For now, we'll try to elevate, and if it fails, fall back to Limited Mode.
    
    # Check if we should try to elevate (could be a flag)
    # If we are already in a recursive call (not easily detected without a flag), we might loop.
    # But Invoke-Elevation starts a new process and exits this one.
    
    # For this implementation, we will assume if the user didn't start as Admin, 
    # and we are here, we should try to elevate ONCE. 
    # But since we can't easily track "tried once" without arguments, 
    # we will default to Limited Mode if not Admin, unless the user explicitly asks for elevation (future feature).
    # OR we can just warn and proceed in Limited Mode.
    
    Write-TronLog "Running in LIMITED MODE. Some features will be skipped." "WARNING"
    $Global:TronMode = "Limited"
}

# --- Tool Fetching ---
if (-not $Config.DryRun) {
    Invoke-FetchTools -ResourcesPath $ResourcesPath
}

# --- Execution ---
if ($Config.DryRun) {
    Write-TronLog "DRY RUN ENABLED. No changes will be made." "WARNING"
}

Invoke-Stage0-Prep -ResourcesPath $ResourcesPath
Invoke-Stage1-TempClean
Invoke-Stage2-Debloat -SkipDebloat $Config.SkipDebloat
Invoke-Stage3-Disinfect -ResourcesPath $ResourcesPath -SkipAntivirusScans $Config.SkipAntivirusScans
Invoke-Stage4-Repair
Invoke-Stage5-Patch
Invoke-Stage6-Optimize -SkipDefrag $Config.SkipDefrag
Invoke-Stage7-WrapUp
Invoke-Stage8-Custom -ResourcesPath $ResourcesPath -SkipCustomScripts $Config.SkipCustomScripts

Write-TronLog "Tron Run Complete." "SUCCESS"
Stop-Transcript
