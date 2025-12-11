<#
.SYNOPSIS
    Wrapper script for Tron Remote Execution.
.EXAMPLE
    .\Remote-Tron.ps1 -Targets "Server01,Server02"
#>
param(
    [string[]]$Targets = @("localhost"),
    [switch]$DryRun
)

# Import Module
$modulePath = Join-Path $PSScriptRoot "Modules\Tron.Remote\Tron.Remote.psm1"
if (Test-Path $modulePath) {
    Import-Module $modulePath -Force
} else {
    Write-Error "Module not found at $modulePath"
    exit 1
}

Write-Host "=== Tron Remote Execution Launcher ===" -ForegroundColor Magenta

Invoke-TronRemote -ComputerName $Targets -DryRun:$DryRun

if (-not $DryRun) {
    Write-Host "`nJobs started. Use Get-Job to view details." -ForegroundColor Gray
    Get-TronRemoteStatus | Format-Table -AutoSize
}
