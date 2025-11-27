# Tron.Core.psm1
# Core functions for Tron PowerShell

$Global:TronStateFile = "tron_state.json"

function Write-TronLog {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Message,
        [string]$Level = "INFO"
    )

    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $FormattedMessage = "[$Timestamp] [$Level] $Message"

    # Write to console with color
    switch ($Level) {
        "INFO" { Write-Host $FormattedMessage -ForegroundColor Gray }
        "WARNING" { Write-Host $FormattedMessage -ForegroundColor Yellow }
        "ERROR" { Write-Host $FormattedMessage -ForegroundColor Red }
        "SUCCESS" { Write-Host $FormattedMessage -ForegroundColor Green }
        default { Write-Host $FormattedMessage }
    }

    # Log to file is handled by Start-Transcript in the main script, 
    # but we could add explicit file appending here if needed.
}

function Get-TronConfig {
    param (
        [string]$ConfigPath = "$PSScriptRoot\..\Config\defaults.json"
    )
    if (Test-Path $ConfigPath) {
        return Get-Content $ConfigPath | ConvertFrom-Json
    }
    else {
        Write-TronLog "Config file not found at $ConfigPath" "ERROR"
        return $null
    }
}

function Get-TronState {
    if (Test-Path $Global:TronStateFile) {
        return Get-Content $Global:TronStateFile | ConvertFrom-Json
    }
    return @{}
}

function Set-TronState {
    param (
        [hashtable]$State
    )
    $State | ConvertTo-Json | Set-Content $Global:TronStateFile
}

function Test-IsAdmin {
    $Identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $Principal = [Security.Principal.WindowsPrincipal]$Identity
    return $Principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Invoke-Elevation {
    Write-TronLog "Attempting to elevate privileges..." "INFO"
    $ProcessInfo = New-Object System.Diagnostics.ProcessStartInfo
    $ProcessInfo.FileName = "powershell.exe"
    $ProcessInfo.Arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$($MyInvocation.PSCommandPath)`""
    $ProcessInfo.Verb = "runas"
    try {
        [System.Diagnostics.Process]::Start($ProcessInfo)
        exit
    }
    catch {
        Write-TronLog "Elevation failed or cancelled by user." "WARNING"
        return $false
    }
}

function Invoke-FetchTools {
    param (
        [string]$ResourcesPath
    )
    
    Write-TronLog "Checking for required tools..." "INFO"
    
    $Tools = @(
        @{
            Name     = "Malwarebytes Anti-Malware"
            Url      = "https://downloads.malwarebytes.com/file/mb4_offline"
            DestDir  = Join-Path $ResourcesPath "Stage3_Disinfect\mbam"
            FileName = "mbam-setup.exe"
        },
        @{
            Name     = "AdwCleaner"
            Url      = "https://downloads.malwarebytes.com/file/adwcleaner"
            DestDir  = Join-Path $ResourcesPath "Stage3_Disinfect\malwarebytes_adwcleaner"
            FileName = "adwcleaner.exe"
        },
        @{
            Name     = "Kaspersky Virus Removal Tool"
            Url      = "https://devbuilds.s.kaspersky-labs.com/devbuilds/KVRT/latest/full/KVRT.exe"
            DestDir  = Join-Path $ResourcesPath "Stage3_Disinfect\kaspersky_virus_removal_tool"
            FileName = "KVRT.exe"
        }
    )

    foreach ($Tool in $Tools) {
        if (-not (Test-Path $Tool.DestDir)) {
            New-Item -ItemType Directory -Path $Tool.DestDir -Force | Out-Null
        }

        $DestPath = Join-Path $Tool.DestDir $Tool.FileName

        if (-not (Test-Path $DestPath)) {
            Write-TronLog "Downloading $($Tool.Name)..." "INFO"
            try {
                Invoke-WebRequest -Uri $Tool.Url -OutFile $DestPath -UserAgent "Tron-Downloader"
                Write-TronLog "Downloaded $($Tool.Name)." "SUCCESS"
            }
            catch {
                Write-TronLog "Failed to download $($Tool.Name). Error: $_" "ERROR"
            }
        }
        else {
            Write-TronLog "$($Tool.Name) already exists." "INFO"
        }
    }
}

Export-ModuleMember -Function Write-TronLog, Get-TronConfig, Get-TronState, Set-TronState, Test-IsAdmin, Invoke-Elevation, Invoke-FetchTools
