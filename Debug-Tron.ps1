# Debug-Tron.ps1
# Runs Tron in a local "Sandbox" environment for debugging

$ErrorActionPreference = "Stop"
$ScriptPath = $PSScriptRoot
$SandboxPath = Join-Path $ScriptPath "Sandbox"

# 1. Setup Sandbox
Write-Host "Setting up Sandbox at $SandboxPath..." -ForegroundColor Cyan
if (Test-Path $SandboxPath) {
    Remove-Item $SandboxPath -Recurse -Force
}
New-Item -ItemType Directory -Path $SandboxPath | Out-Null

# Create Mock Temp Folders
$MockTemp = Join-Path $SandboxPath "Temp"
$MockWinTemp = Join-Path $SandboxPath "Windows\Temp"
New-Item -ItemType Directory -Path $MockTemp -Force | Out-Null
New-Item -ItemType Directory -Path $MockWinTemp -Force | Out-Null

# Create Dummy Files to Clean
New-Item -ItemType File -Path (Join-Path $MockTemp "garbage.tmp") -Value "Delete me" | Out-Null
New-Item -ItemType File -Path (Join-Path $MockWinTemp "system_garbage.tmp") -Value "Delete me too" | Out-Null

# 2. Import Modules (to access Set-TronPaths)
Import-Module (Join-Path $ScriptPath "Modules\Tron.Core.psm1") -Force
Import-Module (Join-Path $ScriptPath "Modules\Tron.Stages.psm1") -Force

# 3. Redirect Paths
$env:TEMP = $MockTemp
$env:TMP = $MockTemp
# Note: Cannot easily mock C:\Windows or SystemRoot without breaking .NET calls, 
# so stages touching SystemRoot should be skipped or mocked via function overrides if needed.
Write-Host "Sandboxed TEMP to $MockTemp" -ForegroundColor Cyan

# 4. Run Tron Logic
# We can't just call .\Tron.ps1 because it starts a new process/scope and re-imports modules, resetting paths.
# So we will dot-source the logic or call the stages directly here for debugging.
# OR we modify Tron.ps1 to accept a -TestPaths parameter.
# For now, let's replicate the Tron.ps1 flow here but using the loaded modules.

Write-Host "Starting Debug Run..." -ForegroundColor Green

# Init
$Config = Get-TronConfig
$Config.Verbose = $true
$Config.DryRun = $false # We want to actually delete the mock files

# Run Stage 1 (TempClean)
Invoke-Stage1

# Verify
if (Test-Path (Join-Path $MockTemp "garbage.tmp")) {
    Write-Host "FAILED: garbage.tmp was not deleted." -ForegroundColor Red
}
else {
    Write-Host "SUCCESS: garbage.tmp was deleted." -ForegroundColor Green
}

if (Test-Path (Join-Path $MockWinTemp "system_garbage.tmp")) {
    Write-Host "FAILED: system_garbage.tmp was not deleted." -ForegroundColor Red
}
else {
    Write-Host "SUCCESS: system_garbage.tmp was deleted." -ForegroundColor Green
}

Write-Host "Debug Run Complete." -ForegroundColor Cyan
