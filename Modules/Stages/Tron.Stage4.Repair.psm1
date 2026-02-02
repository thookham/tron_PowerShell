# Tron.Stage4.Repair.psm1
# Stage 4: Repair

function Invoke-Stage4 {
    Write-TronLog "Stage 4: Repair begin..."

    $ResourcesPath = "$PSScriptRoot\..\..\Resources"
    $StagePath = "$ResourcesPath\stage_4_repair"
    $RawLogs = $Global:TronState.Config.RawLogsPath

    # 1. MSI Installer Cleanup
    Write-TronLog "Cleaning up orphaned MSI cache files..."
    if (-not $Global:TronState.Config.DryRun) {
        $MsiZap = "$StagePath\msi_cleanup\msizap.exe"
        if (Test-Path $MsiZap) {
            Start-Process -FilePath $MsiZap -ArgumentList "G!" -Wait -WindowStyle Hidden
        }
    }

    # 2. DISM Check & Repair (Win8+)
    if ([Environment]::OSVersion.Version.Major -ge 6 -and [Environment]::OSVersion.Version.Minor -ge 2) {
        if (-not $Global:TronState.Config.SkipDismCleanup) {
            Write-TronLog "Launch job 'DISM Windows image check'..."
            if (-not $Global:TronState.Config.DryRun) {
                $DismLog = "$RawLogs\dism_check.log"
                # Using native CheckHealth first if available, or ScanHealth
                $Process = Start-Process -FilePath "dism.exe" -ArgumentList "/Online /NoRestart /Cleanup-Image /ScanHealth /Logpath:`"$DismLog`"" -Wait -PassThru -WindowStyle Hidden
                
                # Check exit code
                if ($Process.ExitCode -ne 0) {
                    Write-TronLog "DISM: Image corruption detected. Attempting repair..." "WARN"
                    $DismRepairLog = "$RawLogs\dism_repair.log"
                    Start-Process -FilePath "dism.exe" -ArgumentList "/Online /NoRestart /Cleanup-Image /RestoreHealth /Logpath:`"$DismRepairLog`"" -Wait -WindowStyle Hidden
                }
                else {
                    Write-TronLog "DISM: No image corruption detected."
                }
            }
        }
    }

    # 3. SFC Scan
    Write-TronLog "Launch job 'System File Checker'..."
    if (-not $Global:TronState.Config.DryRun) {
        # SFC is tricky to capture output from Start-Process properly without redirects, keeping simple for now
        Start-Process -FilePath "$env:SystemRoot\System32\sfc.exe" -ArgumentList "/scannow" -Wait -WindowStyle Hidden
    }

    # 4. chkdsk (Enhanced detection)
    Write-TronLog "Launch job 'chkdsk'..."
    if (-not $Global:TronState.Config.DryRun) {
        $Process = Start-Process -FilePath "$env:SystemRoot\System32\chkdsk.exe" -ArgumentList "$env:SystemDrive" -Wait -PassThru -WindowStyle Hidden
        if ($Process.ExitCode -ne 0) {
            Write-TronLog "Errors found on $env:SystemDrive. Scheduling full chkdsk at next reboot." "WARN"
            # Use fsutil to set dirty bit
            Start-Process -FilePath "fsutil.exe" -ArgumentList "dirty set $env:SystemDrive" -Wait -WindowStyle Hidden
        }
        else {
            Write-TronLog "No errors found on $env:SystemDrive."
        }
    }

    # 5. Telemetry Removal (Refactored to call external module if needed, or inline)
    if (-not $Global:TronState.Config.SkipTelemetry) {
        # Assuming Invoke-TelemetryCleanup is in Tron.Telemetry.psm1
        # Calling it here assumes the module is loaded.
        if (Get-Command Invoke-TelemetryCleanup -ErrorAction SilentlyContinue) {
            Invoke-TelemetryCleanup -StagePath $StagePath
        } else {
            Write-TronLog "Invoke-TelemetryCleanup not found. Skipping." "WARN"
        }
    }
    
    # 6. Disable NVIDIA Telemetry (Native Task Scheduler)
    Write-TronLog "Launch job 'Disable NVIDIA telemetry'..."
    if (-not $Global:TronState.Config.DryRun) {
        $Tasks = @(
            "NvTmMon_*", "NvTmRep_*", "NvTmRepOnLogon_*", "NvProfileUpdaterOnLogon_*", "NvProfileUpdaterDaily_*"
        )
        # Using wildcard matching for robustness
        $AllTasks = Get-ScheduledTask -TaskPath "\" -ErrorAction SilentlyContinue
        foreach ($Pattern in $Tasks) {
            $Matches = $AllTasks | Where-Object { $_.TaskName -like $Pattern }
            foreach ($Match in $Matches) {
                 Unregister-ScheduledTask -TaskName $Match.TaskName -Confirm:$false -ErrorAction SilentlyContinue
                 Write-TronLog "Disabled NVIDIA Task: $($Match.TaskName)" "DEBUG"
            }
        }
    }

    # 7. Network Repair
    Write-TronLog "Launch job 'Network repair'..."
    if (-not $Global:TronState.Config.DryRun) {
        Start-Process "ipconfig" -ArgumentList "/flushdns" -Wait -WindowStyle Hidden
        Start-Process "netsh" -ArgumentList "interface ip delete arpcache" -Wait -WindowStyle Hidden
        Start-Process "netsh" -ArgumentList "winsock reset catalog" -Wait -WindowStyle Hidden
    }

    # 8. Repair File Extensions
    # Assuming Invoke-FileExtensionRepair is a helper function - keeping placeholder call
    # $ExtensionPath = "$StagePath\repair_file_extensions"
    # Invoke-FileExtensionRepair -ResourcePath $ExtensionPath

    Write-TronLog "Stage 4: Repair complete."
}

Export-ModuleMember -Function Invoke-Stage4
