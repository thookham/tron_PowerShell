# Tron.Core.psm1
# Core functions for Tron PowerShell

# Global State
$Global:TronState = @{
    Config  = $null
    LogFile = $null
    IsAdmin = $false
    Mode    = "Standard" # Standard, Limited, DryRun
}

function Write-TronLog {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Message,
        [string]$Level = "INFO" # INFO, WARN, ERROR, DEBUG
    )

    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $LogLine = "[$Timestamp] [$Level] $Message"

    # Console Output
    # Console Output
    switch ($Level) {
        "WARN" { Write-Host $LogLine -ForegroundColor Yellow; Write-Output $LogLine }
        "ERROR" { Write-Host $LogLine -ForegroundColor Red; Write-Output $LogLine }
        "DEBUG" { if ($Global:TronState.Config.Verbose) { Write-Host $LogLine -ForegroundColor Gray; Write-Output $LogLine } }
        Default { Write-Host $LogLine -ForegroundColor White; Write-Output $LogLine }
    }

    # File Output
    if ($Global:TronState.LogFile) {
        Add-Content -Path $Global:TronState.LogFile -Value $LogLine -ErrorAction SilentlyContinue
    }
}

function Get-TronConfig {
    param (
        [string]$ConfigPath = "$PSScriptRoot\..\Config\defaults.json"
    )

    if (Test-Path $ConfigPath) {
        try {
            $Global:TronState.Config = Get-Content $ConfigPath -Raw | ConvertFrom-Json
            Write-TronLog "Configuration loaded from $ConfigPath"
        }
        catch {
            Write-TronLog "Failed to load configuration: $_" "ERROR"
            throw "ConfigurationLoadFailure"
        }
    }
    else {
        Write-TronLog "Configuration file not found: $ConfigPath" "ERROR"
        throw "ConfigFileNotFound"
    }
    return $Global:TronState.Config
}

function Test-IsAdmin {
    $Identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $Principal = [Security.Principal.WindowsPrincipal]$Identity
    $IsAdmin = $Principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    
    $Global:TronState.IsAdmin = $IsAdmin
    return $IsAdmin
}

function Initialize-TronLogging {
    param (
        [string]$LogPath
    )

    if (-not $LogPath) {
        $LogPath = $Global:TronState.Config.LogFile
    }

    $LogDir = Split-Path $LogPath -Parent
    if (-not (Test-Path $LogDir)) {
        New-Item -ItemType Directory -Path $LogDir -Force | Out-Null
    }

    $Global:TronState.LogFile = $LogPath
    
    # Start Transcript for full session capture
    try {
        Start-Transcript -Path "$LogPath.transcript" -Append -Force -ErrorAction SilentlyContinue | Out-Null
    }
    catch {
        Write-Host "Warning: Could not start transcript." -ForegroundColor Yellow
    }

    Write-TronLog "Logging initialized at $LogPath"
}

Export-ModuleMember -Function Write-TronLog, Get-TronConfig, Test-IsAdmin, Initialize-TronLogging
