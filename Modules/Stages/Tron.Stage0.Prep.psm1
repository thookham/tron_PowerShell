# Tron.Stage0.Prep.psm1
# Stage 0: Prep

function Invoke-Stage0 {
    Write-TronLog "Stage 0: Prep begin..."

    $ResourcesPath = "$PSScriptRoot\..\..\Resources"
    $StagePath = "$ResourcesPath\stage_0_prep" # Using legacy folder name for compatibility

    # 1. Stop Themes Service
    Write-TronLog "Temporarily stopping Themes service..."
    if (-not $Global:TronState.Config.DryRun) {
        Stop-Service -Name "Themes" -Force -ErrorAction SilentlyContinue
    }

    # 2. Kill HelpPane.exe
    Stop-Process -Name "HelpPane" -Force -ErrorAction SilentlyContinue

    # 3. Create Restore Point
    Write-TronLog "Creating pre-run Restore Point..."
    if (-not $Global:TronState.Config.DryRun) {
        try {
            # Enable System Restore (Win7+)
            Enable-ComputerRestore -Drive "$env:SystemDrive" -ErrorAction SilentlyContinue | Out-Null
            
            # Create Checkpoint
            Checkpoint-Computer -Description "TRON v$($Global:TronState.Config.Version): Pre-run checkpoint" -RestorePointType MODIFY_SETTINGS -ErrorAction Stop | Out-Null
            Write-TronLog "Restore point created successfully."
        }
        catch {
            Write-TronLog "Failed to create restore point: $_" "WARN"
        }
    }

    # 4. Rkill - Native Check
    Write-TronLog "Launch job 'rkill'..."
    if (-not $Global:TronState.Config.DryRun) {
        # Rkill is a specialized tool. While native process analysis is possible, Rkill's heuristics are preferred here.
        # Keeping wrapper for now but ensuring path handling is robust.
        $RkillPath = "$StagePath\rkill\solitaire.exe"
        if (Test-Path $RkillPath) {
            Start-Process -FilePath $RkillPath -ArgumentList "-s -l `"$env:TEMP\tron_rkill.log`" -w `"$StagePath\rkill\rkill_process_whitelist.txt`"" -Wait -WindowStyle Hidden
            if (Test-Path "$env:TEMP\tron_rkill.log") {
                Get-Content "$env:TEMP\tron_rkill.log" | Out-File -Append $Global:TronState.LogFile
                Remove-Item "$env:TEMP\tron_rkill.log" -ErrorAction SilentlyContinue
            }
        }
        else {
            Write-TronLog "Rkill not found at $RkillPath" "WARN"
        }
    }

    # 5. TDSS Killer
    Write-TronLog "Launch job 'TDSS Killer'..."
    if (-not $Global:TronState.Config.DryRun) {
        $TDSSPath = "$StagePath\tdss_killer\TDSSKiller.exe"
        if (Test-Path $TDSSPath) {
            Start-Process -FilePath $TDSSPath -ArgumentList "-l `"$env:TEMP\tdsskiller.log`" -silent -tdlfs -dcexact -accepteula -accepteulaksn" -Wait -WindowStyle Hidden
            if (Test-Path "$env:TEMP\tdsskiller.log") {
                Get-Content "$env:TEMP\tdsskiller.log" | Out-File -Append $Global:TronState.LogFile
                Remove-Item "$env:TEMP\tdsskiller.log" -ErrorAction SilentlyContinue
            }
        }
        else {
            Write-TronLog "TDSSKiller not found at $TDSSPath" "WARN"
        }
    }

    # 6. Backup Registry (ERUNT) -> Native Registry Backup
    Write-TronLog "Launch job 'Back up registry'..."
    if (-not $Global:TronState.Config.DryRun) {
        $BackupPath = "$($Global:TronState.Config.BackupPath)\registry_backup"
        Write-TronLog "Backing up registry to $BackupPath (Native Method)..."
        
        New-Item -ItemType Directory -Path $BackupPath -Force | Out-Null
        
        # Native reg export is safer/cleaner than relying on ERUNT for modern OS
        $Keys = @{
            "HKLM_SOFTWARE" = "HKLM\Software"
            "HKLM_SYSTEM"   = "HKLM\System"
            "HKCU"          = "HKCU"
        }
        
        foreach ($KeyName in $Keys.Keys) {
            $File = "$BackupPath\$KeyName.reg"
            try {
                reg export $Keys[$KeyName] $File /y
            } catch {
                Write-TronLog "Failed to backup $KeyName: $_" "WARN"
            }
        }
    }

    Write-TronLog "Stage 0: Prep complete."
}

Export-ModuleMember -Function Invoke-Stage0
