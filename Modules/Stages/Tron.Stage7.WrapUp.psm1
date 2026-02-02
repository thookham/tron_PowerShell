# Tron.Stage7.WrapUp.psm1
# Stage 7: Wrap-up

function Invoke-Stage7 {
    Write-TronLog "Stage 7: Wrap-up begin..."

    $ResourcesPath = "$PSScriptRoot\..\..\Resources"
    $StagePath = "$ResourcesPath\stage_7_wrap-up"
    $RawLogs = $Global:TronState.Config.RawLogsPath

    # 1. Reset Power Settings
    if ($Global:TronState.Config.PreservePowerScheme) {
        Write-TronLog "Preserving power scheme per config."
    }
    else {
        Write-TronLog "Resetting Windows power settings to defaults..."
        if (-not $Global:TronState.Config.DryRun) {
            Start-Process "powercfg.exe" -ArgumentList "-restoredefaultschemes" -Wait -WindowStyle Hidden
        }
    }

    # 2. Collect Logs
    Write-TronLog "Saving misc logs to $RawLogs..."
    if (-not $Global:TronState.Config.DryRun) {
        # AdwCleaner
        if (Test-Path "$env:SystemDrive\AdwCleaner\Logs") {
            Copy-Item "$env:SystemDrive\AdwCleaner\Logs\*.txt" "$RawLogs\" -Force -ErrorAction SilentlyContinue
            Remove-Item "$env:SystemDrive\AdwCleaner" -Recurse -Force -ErrorAction SilentlyContinue
        }
        # MBAM
        $MbamLogs = "$env:ProgramData\Malwarebytes\Malwarebytes Anti-Malware\logs"
        if (Test-Path $MbamLogs) {
            Copy-Item "$MbamLogs\*.xml" "$RawLogs\" -Force -ErrorAction SilentlyContinue
        }
    }

    # 3. Remove Malwarebytes (if not preserved)
    if ($Global:TronState.Config.PreserveMalwarebytes) {
        Write-TronLog "Preserving Malwarebytes per config."
    }
    else {
        Write-TronLog "Uninstalling Malwarebytes..."
        if (-not $Global:TronState.Config.DryRun) {
            $UninsMbam = "$env:ProgramFiles\Malwarebytes\Anti-Malware\unins000.exe"
            if (-not (Test-Path $UninsMbam)) {
                $UninsMbam = "${env:ProgramFiles(x86)}\Malwarebytes\Anti-Malware\unins000.exe"
            }
            if (Test-Path $UninsMbam) {
                Start-Process -FilePath $UninsMbam -ArgumentList "/VERYSILENT /SUPPRESSMSGBOXES /NORESTART" -Wait -WindowStyle Hidden
            }
        }
    }

    # 4. Calculate Saved Disk Space
    try {
        $Drive = Get-PSDrive -Name $env:SystemDrive.Substring(0, 1)
        $FreeSpaceAfter = $Drive.Free / 1GB
        $Global:TronState.FreeSpaceAfter = $FreeSpaceAfter
        
        if ($Global:TronState.FreeSpaceBefore) {
            $Saved = $FreeSpaceAfter - $Global:TronState.FreeSpaceBefore
            Write-TronLog "Disk space reclaimed: $([math]::Round($Saved, 2)) GB"
        }
    }
    catch {
        Write-TronLog "Failed to calculate disk space." "WARN"
    }

    Write-TronLog "Stage 7: Wrap-up complete."
}

Export-ModuleMember -Function Invoke-Stage7
