# Tron.Stages.psm1
# Stage logic for Tron PowerShell

function Invoke-Stage0 {
    Write-TronLog "Stage 0: Prep begin..."

    $ResourcesPath = "$PSScriptRoot\..\Resources"
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

    # 4. Rkill
    Write-TronLog "Launch job 'rkill'..."
    if (-not $Global:TronState.Config.DryRun) {
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

    # 6. Backup Registry (ERUNT)
    Write-TronLog "Launch job 'Back up registry'..."
    if (-not $Global:TronState.Config.DryRun) {
        $EruntPath = "$StagePath\backup_registry\erunt.exe"
        if (Test-Path $EruntPath) {
            Start-Process -FilePath $EruntPath -ArgumentList "`"$($Global:TronState.Config.BackupPath)\registry_backup`" /noconfirmdelete /noprogresswindow" -Wait -WindowStyle Hidden
            # ERUNT returns immediately sometimes, giving it a moment
            Start-Sleep -Seconds 5
        }
        else {
            Write-TronLog "ERUNT not found at $EruntPath" "WARN"
        }
    }

    Write-TronLog "Stage 0: Prep complete."
}

function Invoke-Stage1 {
    Write-TronLog "Stage 1: TempClean begin..."

    $ResourcesPath = "$PSScriptRoot\..\Resources"
    $StagePath = "$ResourcesPath\stage_1_tempclean"

    # 1. Clear CryptNet SSL certificate cache
    Write-TronLog "Launch job 'Clear CryptNet SSL certificate cache'..."
    if (-not $Global:TronState.Config.DryRun) {
        certutil -URLcache * delete | Out-Null
    }

    # 2. Clean Internet Explorer
    Write-TronLog "Launch job 'Clean Internet Explorer'..."
    if (-not $Global:TronState.Config.DryRun) {
        Start-Process -FilePath "rundll32.exe" -ArgumentList "inetcpl.cpl,ClearMyTracksByProcess 4351" -Wait
    }

    # 3. TempFileCleanup
    Write-TronLog "Launch job 'TempFileCleanup'..."
    if (-not $Global:TronState.Config.DryRun) {
        $TFCPath = "$StagePath\tempfilecleanup\TempFileCleanup.bat"
        if (Test-Path $TFCPath) {
            Start-Process -FilePath "cmd.exe" -ArgumentList "/c `"$TFCPath`"" -Wait -WindowStyle Hidden
        }
    }

    # 4. CCleaner
    Write-TronLog "Launch job 'CCleaner'..."
    if (-not $Global:TronState.Config.DryRun) {
        # Handle SkipCookieCleanup
        if ($Global:TronState.Config.SkipCookieCleanup) {
            Write-TronLog "Preserving cookies per config."
            Rename-Item "$StagePath\ccleaner\ccleaner.ini" "ccleaner.ini.default" -ErrorAction SilentlyContinue
            Rename-Item "$StagePath\ccleaner\ccleaner_skip_cookie_cleanup.ini" "ccleaner.ini" -ErrorAction SilentlyContinue
        }

        $CCleanerExe = if ([Environment]::Is64BitOperatingSystem) { "ccleaner64.exe" } else { "ccleaner.exe" }
        $CCleanerPath = "$StagePath\ccleaner\$CCleanerExe"

        if (Test-Path $CCleanerPath) {
            Start-Process -FilePath $CCleanerPath -ArgumentList "/auto" -WindowStyle Hidden
            Start-Sleep -Seconds 120 # Give it time
            Stop-Process -Name "ccleaner*" -Force -ErrorAction SilentlyContinue
        }

        # Restore config
        if ($Global:TronState.Config.SkipCookieCleanup) {
            Rename-Item "$StagePath\ccleaner\ccleaner.ini" "ccleaner_skip_cookie_cleanup.ini" -ErrorAction SilentlyContinue
            Rename-Item "$StagePath\ccleaner\ccleaner.ini.default" "ccleaner.ini" -ErrorAction SilentlyContinue
        }
    }

    # 5. Clear Windows Event Logs
    Write-TronLog "Launch job 'Clear Windows Event Logs'..."
    if (-not $Global:TronState.Config.DryRun) {
        Get-WinEvent -ListLog * -Force -ErrorAction SilentlyContinue | ForEach-Object {
            Wevtutil.exe cl $_.LogName
        }
    }

    # 6. Clear Windows Update Cache
    Write-TronLog "Launch job 'Clear Windows Update Cache'..."
    if (-not $Global:TronState.Config.DryRun) {
        Stop-Service -Name "wuauserv" -Force -ErrorAction SilentlyContinue
        Remove-Item "$env:SystemRoot\SoftwareDistribution\Download\*" -Recurse -Force -ErrorAction SilentlyContinue
        Start-Service -Name "wuauserv" -ErrorAction SilentlyContinue
    }

    # 7. Windows Disk Cleanup
    Write-TronLog "Launch job 'Windows Disk Cleanup'..."
    if (-not $Global:TronState.Config.DryRun) {
        # Set Registry Flags (Simplified for brevity, ideally loop through keys)
        $VolCache = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches"
        Get-ChildItem $VolCache | ForEach-Object {
            Set-ItemProperty -Path $_.PSPath -Name "StateFlags0100" -Value 2 -Type DWord -ErrorAction SilentlyContinue
        }
        
        Start-Process -FilePath "cleanmgr.exe" -ArgumentList "/sagerun:100" -Wait -WindowStyle Hidden
    }

    Write-TronLog "Stage 1: TempClean complete."
}

function Invoke-Stage2 {
    Write-TronLog "Stage 2: De-bloat begin..."

    $ResourcesPath = "$PSScriptRoot\..\Resources"
    $StagePath = "$ResourcesPath\stage_2_de-bloat"
    $OemPath = "$StagePath\oem"
    $RawLogs = $Global:TronState.Config.RawLogsPath

    # Helper to clean PendingFileRenameOperations
    function Clear-PendingFileRename {
        $Key = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager"
        if (Get-ItemProperty -Path $Key -Name "PendingFileRenameOperations" -ErrorAction SilentlyContinue) {
            Write-TronLog "Clearing PendingFileRenameOperations..." "DEBUG"
            Remove-ItemProperty -Path $Key -Name "PendingFileRenameOperations" -ErrorAction SilentlyContinue
        }
    }

    # 1. Enable MSIServer (Safe Mode)
    if ($Global:TronState.Config.SafeMode) {
        Write-TronLog "Enabling MSIServer for Safe Mode..."
        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\SafeBoot\$env:SAFEBOOT_OPTION\MSIServer" -Name "(default)" -Value "Service" -Type String -ErrorAction SilentlyContinue
        Start-Service "MSIServer" -ErrorAction SilentlyContinue
    }

    # 2. Remove Bloat by GUID (Phase 1 & 2)
    $GuidLists = @("$OemPath\programs_to_target_by_GUID.txt", "$OemPath\toolbars_BHOs_to_target_by_GUID.txt")
    $GuidDumpFile = Get-ChildItem "$RawLogs\GUID_dump_*.txt" | Sort-Object LastWriteTime -Descending | Select-Object -First 1

    if ($GuidDumpFile -and (-not $Global:TronState.Config.DryRun)) {
        $SystemGuids = Get-Content $GuidDumpFile.FullName
        foreach ($ListFile in $GuidLists) {
            if (Test-Path $ListFile) {
                $TargetGuids = Get-Content $ListFile | Where-Object { $_ -match "^\{" }
                foreach ($Guid in $TargetGuids) {
                    if ($SystemGuids -contains $Guid) {
                        Write-TronLog "Removing Bloatware GUID: $Guid"
                        Start-Process "msiexec.exe" -ArgumentList "/qn /norestart /x $Guid" -Wait
                        Clear-PendingFileRename
                    }
                }
            }
        }
    }

    # 3. Remove Bloat by Name (Phase 3)
    Write-TronLog "Attempt junkware removal: Phase 3 (wildcard by name)..."
    if (-not $Global:TronState.Config.DryRun) {
        $NameListFile = "$OemPath\programs_to_target_by_name.txt"
        if (Test-Path $NameListFile) {
            $Names = Get-Content $NameListFile | Where-Object { $_ -notmatch "^::" -and $_ -notmatch "^set" -and $_.Trim().Length -gt 0 }
            foreach ($Name in $Names) {
                Write-TronLog "Checking for: $Name" "DEBUG"
                try {
                    $App = Get-WmiObject -Class Win32_Product -Filter "Name like '$Name'" -ErrorAction SilentlyContinue
                    if ($App) {
                        Write-TronLog "Removing: $($App.Name)"
                        $App.Uninstall() | Out-Null
                        Clear-PendingFileRename
                    }
                }
                catch {}
            }
        }
    }

    # 4. Metro Apps (Win8+)
    if ([Environment]::OSVersion.Version.Major -ge 6 -and [Environment]::OSVersion.Version.Minor -ge 2) {
        if (-not $Global:TronState.Config.PreserveMetroApps -and -not $Global:TronState.Config.DryRun) {
            Write-TronLog "Removing OEM Metro Apps..."
            if ([Environment]::OSVersion.Version.Major -eq 10) {
                # Win10
                $MetroScripts = @("metro_3rd_party_modern_apps_to_target_by_name.ps1", "metro_Microsoft_modern_apps_to_target_by_name.ps1")
                foreach ($Script in $MetroScripts) {
                    $ScriptPath = "$StagePath\metro\$Script"
                    if (Test-Path $ScriptPath) {
                        Start-Process "powershell.exe" -ArgumentList "-ExecutionPolicy Bypass -File `"$ScriptPath`"" -Wait -WindowStyle Hidden
                    }
                }
            }
            else {
                # Win8/8.1
                Get-AppxProvisionedPackage -Online | Remove-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue
                Get-AppxPackage -AllUsers | Remove-AppxPackage -ErrorAction SilentlyContinue
            }
        }
    }

    # 5. OneDrive Removal (Win10)
    if ([Environment]::OSVersion.Version.Major -eq 10 -and -not $Global:TronState.Config.DryRun) {
        # Simplified check - assuming default location for now
        $OneDrivePath = "$env:USERPROFILE\OneDrive"
        if (Test-Path $OneDrivePath) {
            $Items = Get-ChildItem $OneDrivePath -Force | Where-Object { $_.Name -ne "desktop.ini" }
            if ($Items.Count -eq 0) {
                Write-TronLog "Removing OneDrive..."
                Stop-Process -Name "OneDrive" -Force -ErrorAction SilentlyContinue
                Start-Process "$env:SystemRoot\System32\OneDriveSetup.exe" -ArgumentList "/uninstall" -Wait -WindowStyle Hidden
                Remove-Item "$env:LocalAppData\Microsoft\OneDrive" -Recurse -Force -ErrorAction SilentlyContinue
            }
            else {
                Write-TronLog "OneDrive folder not empty, skipping removal."
            }
        }
    }

    # 6. Telemetry / Tips
    if (-not $Global:TronState.Config.DryRun) {
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent" -Name "DisableSoftLanding" -Value 1 -Type DWord -ErrorAction SilentlyContinue
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent" -Name "DisableWindowsConsumerFeatures" -Value 1 -Type DWord -ErrorAction SilentlyContinue
    }

    Write-TronLog "Stage 2: De-bloat complete."
}

function Invoke-Stage3 {
    Write-TronLog "Stage 3: Disinfect begin..."

    $ResourcesPath = "$PSScriptRoot\..\Resources"
    $StagePath = "$ResourcesPath\stage_3_disinfect"
    $RawLogs = $Global:TronState.Config.RawLogsPath
    $MbamInstalledByTron = $false

    # 1. Malwarebytes Anti-Malware (MBAM)
    $MbamPath = "$env:ProgramFiles\Malwarebytes\Anti-Malware\mbam.exe"
    if (-not (Test-Path $MbamPath)) {
        $MbamPath = "${env:ProgramFiles(x86)}\Malwarebytes\Anti-Malware\mbam.exe"
    }

    if (Test-Path $MbamPath) {
        Write-TronLog "Existing MBAM installation detected. Skipping installation."
    }
    elseif ($Global:TronState.Config.SkipMbam) {
        Write-TronLog "Skipping MBAM installation per config."
    }
    else {
        Write-TronLog "Installing Malwarebytes Anti-Malware..."
        if (-not $Global:TronState.Config.DryRun) {
            $MbamSetup = Get-ChildItem "$StagePath\mbam\mb3-setup*.exe" | Select-Object -First 1
            if ($MbamSetup) {
                Start-Process -FilePath $MbamSetup.FullName -ArgumentList "/SP- /VERYSILENT /NORESTART /SUPPRESSMSGBOXES /NOCANCEL /NOICON" -Wait
                $MbamInstalledByTron = $true
                
                # Kill auto-start processes
                Stop-Service -Name "mbamservice" -Force -ErrorAction SilentlyContinue
                Stop-Process -Name "mbamtray" -Force -ErrorAction SilentlyContinue

                # Remove shortcuts
                Remove-Item "$env:USERPROFILE\Desktop\Malwarebytes.lnk" -ErrorAction SilentlyContinue
                Remove-Item "$env:PUBLIC\Desktop\Malwarebytes.lnk" -ErrorAction SilentlyContinue

                # Copy Config
                Copy-Item "$StagePath\mbam\*.json" "$env:ProgramData\Malwarebytes\MBAMService\config\" -Force -ErrorAction SilentlyContinue

                # Install Rules
                Write-TronLog "Loading bundled definitions package..."
                Start-Process -FilePath "$StagePath\mbam\mbam2-rules.exe" -ArgumentList "/sp- /verysilent /suppressmsgboxes /log=`"$RawLogs\mbam_rules_install.log`" /norestart" -Wait
            }
        }
    }

    # Launch MBAM
    if (-not $Global:TronState.Config.DryRun) {
        if (Test-Path $MbamPath) {
            Write-TronLog "Launching MBAM, click 'scan' in the MBAM window."
            Start-Process -FilePath $MbamPath
        }
    }

    # 2. AdwCleaner
    if ($Global:TronState.Config.SkipAdwCleaner) {
        # Assuming config has this, or default false
        Write-TronLog "Skipping AdwCleaner scan per config."
    }
    else {
        Write-TronLog "Launch job 'Malwarebytes AdwCleaner'..."
        if (-not $Global:TronState.Config.DryRun) {
            Start-Process -FilePath "$StagePath\malwarebytes_adwcleaner\adwcleaner.exe" -ArgumentList "/eula /clean /noreboot /path `"$RawLogs`"" -Wait
            Start-Process -FilePath "$StagePath\malwarebytes_adwcleaner\adwcleaner.exe" -ArgumentList "/uninstall" -Wait
        }
    }

    # 3. Kaspersky Virus Removal Tool (KVRT)
    if ($Global:TronState.Config.SkipKvrt) {
        # Assuming config has this
        Write-TronLog "Skipping KVRT scan per config."
    }
    else {
        Write-TronLog "Launch job 'Kaspersky Virus Removal Tool'..."
        if (-not $Global:TronState.Config.DryRun) {
            Start-Process -FilePath "$StagePath\kaspersky_virus_removal_tool\KVRT.exe" -ArgumentList "-d `"$RawLogs`" -accepteula -adinsilent -silent -processlevel 2 -dontencrypt" -Wait
            Remove-Item "$RawLogs\Legal notices" -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    # Cleanup
    Write-TronLog "Cleaning up..."
    if ($MbamInstalledByTron -and (-not $Global:TronState.Config.DryRun)) {
        Write-TronLog "Uninstalling Malwarebytes..."
        $UninsMbam = "$env:ProgramFiles\Malwarebytes\Anti-Malware\unins000.exe"
        if (Test-Path $UninsMbam) {
            Start-Process -FilePath $UninsMbam -ArgumentList "/VERYSILENT /SUPPRESSMSGBOXES /NORESTART" -Wait
        }
    }

    # Delete tools
    if (-not $Global:TronState.Config.DryRun) {
        Remove-Item "$StagePath\malwarebytes_adwcleaner\adwcleaner.exe" -ErrorAction SilentlyContinue
        Remove-Item "$StagePath\kaspersky_virus_removal_tool\KVRT.exe" -ErrorAction SilentlyContinue
        Remove-Item "$StagePath\mbam\mbam-setup.exe" -ErrorAction SilentlyContinue
    }

    Write-TronLog "Stage 3: Disinfect complete."
}

function Invoke-Stage4 {
    Write-TronLog "Stage 4: Repair begin..."

    $ResourcesPath = "$PSScriptRoot\..\Resources"
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
                $Process = Start-Process -FilePath "dism.exe" -ArgumentList "/Online /NoRestart /Cleanup-Image /ScanHealth /Logpath:`"$DismLog`"" -Wait -PassThru -WindowStyle Hidden
                
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
        Start-Process -FilePath "$env:SystemRoot\System32\sfc.exe" -ArgumentList "/scannow" -Wait -WindowStyle Hidden
    }

    # 4. chkdsk
    Write-TronLog "Launch job 'chkdsk'..."
    if (-not $Global:TronState.Config.DryRun) {
        $Process = Start-Process -FilePath "$env:SystemRoot\System32\chkdsk.exe" -ArgumentList "$env:SystemDrive" -Wait -PassThru -WindowStyle Hidden
        if ($Process.ExitCode -ne 0) {
            Write-TronLog "Errors found on $env:SystemDrive. Scheduling full chkdsk at next reboot." "WARN"
            Start-Process -FilePath "fsutil.exe" -ArgumentList "dirty set $env:SystemDrive" -Wait -WindowStyle Hidden
        }
        else {
            Write-TronLog "No errors found on $env:SystemDrive."
        }
    }

    # 5. Telemetry Removal
    if (-not $Global:TronState.Config.SkipTelemetry) {
        Write-TronLog "Launch job 'Kill Microsoft telemetry'..."
        if (-not $Global:TronState.Config.DryRun) {
            # Win10
            if ([Environment]::OSVersion.Version.Major -eq 10) {
                $TelemScript = "$StagePath\disable_windows_telemetry\purge_windows_10_telemetry.bat"
                if (Test-Path $TelemScript) {
                    Start-Process -FilePath "cmd.exe" -ArgumentList "/c `"$TelemScript`"" -Wait -WindowStyle Hidden
                }
            }
            # Win7/8
            elseif ([Environment]::OSVersion.Version.Major -eq 6) {
                $TelemScript = "$StagePath\disable_windows_telemetry\purge_windows_7-8-81_telemetry.bat"
                if (Test-Path $TelemScript) {
                    Start-Process -FilePath "cmd.exe" -ArgumentList "/c `"$TelemScript`"" -Wait -WindowStyle Hidden
                }
            }
        }
    }

    # 6. Disable NVIDIA Telemetry
    Write-TronLog "Launch job 'Disable NVIDIA telemetry'..."
    if (-not $Global:TronState.Config.DryRun) {
        $Tasks = @(
            "\NvTmMon_{B2FE1952-0186-46C3-BAEC-A80AA35AC5B8}",
            "\NvTmRep_{B2FE1952-0186-46C3-BAEC-A80AA35AC5B8}",
            "\NvTmRepOnLogon_{B2FE1952-0186-46C3-BAEC-A80AA35AC5B8}",
            "\NvProfileUpdaterOnLogon_{B2FE1952-0186-46C3-BAEC-A80AA35AC5B8}",
            "\NvProfileUpdaterDaily_{B2FE1952-0186-46C3-BAEC-A80AA35AC5B8}",
            "\NvTmRepCR1_{B2FE1952-0186-46C3-BAEC-A80AA35AC5B8}",
            "\NvTmRepCR2_{B2FE1952-0186-46C3-BAEC-A80AA35AC5B8}",
            "\NvTmRepCR3_{B2FE1952-0186-46C3-BAEC-A80AA35AC5B8}"
        )
        foreach ($Task in $Tasks) {
            Unregister-ScheduledTask -TaskName $Task -Confirm:$false -ErrorAction SilentlyContinue
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
    Write-TronLog "Launch job 'Repair file extensions'..."
    if (-not $Global:TronState.Config.DryRun) {
        $ExtScript = "$StagePath\repair_file_extensions\repair_file_extensions.bat"
        if (Test-Path $ExtScript) {
            Start-Process -FilePath "cmd.exe" -ArgumentList "/c `"$ExtScript`"" -Wait -WindowStyle Hidden
        }
    }

    Write-TronLog "Stage 4: Repair complete."
}

function Invoke-Stage5 {
    Write-TronLog "Stage 5: Patch begin..."

    $ResourcesPath = "$PSScriptRoot\..\Resources"
    $StagePath = "$ResourcesPath\stage_5_patch"

    # 1. Enable MSIServer (Safe Mode)
    if ($Global:TronState.Config.SafeMode) {
        Write-TronLog "Enabling MSIServer for Safe Mode..."
        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\SafeBoot\$env:SAFEBOOT_OPTION\MSIServer" -Name "(default)" -Value "Service" -Type String -ErrorAction SilentlyContinue
        Start-Service "MSIServer" -ErrorAction SilentlyContinue
    }

    if ($Global:TronState.Config.SkipAppPatches) {
        Write-TronLog "Skipping application patches per config."
    }
    else {
        # 2. Update 7-Zip
        $7ZipInstalled = (Test-Path "$env:ProgramFiles\7-Zip") -or (Test-Path "${env:ProgramFiles(x86)}\7-Zip")
        if ($7ZipInstalled) {
            Write-TronLog "7-Zip detected, updating..."
            if (-not $Global:TronState.Config.DryRun) {
                # Calling the original installer script for simplicity as it handles msi logic well
                # Or I could implement it. Let's call the script if it exists.
                $7ZipScript = "$StagePath\7-Zip\7-Zip Installer.bat"
                if (Test-Path $7ZipScript) {
                    Start-Process -FilePath "cmd.exe" -ArgumentList "/c `"$7ZipScript`"" -Wait -WindowStyle Hidden
                }
            }
        }
    }

    # 3. Update Windows Defender
    $DefenderPath = "$env:ProgramFiles\Windows Defender\mpcmdrun.exe"
    if (Test-Path $DefenderPath) {
        Write-TronLog "Updating Windows Defender..."
        if (-not $Global:TronState.Config.DryRun) {
            Start-Process -FilePath $DefenderPath -ArgumentList "-SignatureUpdate" -Wait -WindowStyle Hidden
        }
    }

    # 4. Windows Updates
    if ($Global:TronState.Config.SkipWindowsUpdates) {
        Write-TronLog "Skipping Windows Updates per config."
    }
    else {
        Write-TronLog "Launch job 'Install Windows updates'..."
        
        # Check WSUS Offline
        $WsusScript = "$StagePath\wsus_offline\client\Update.cmd"
        if ((Test-Path $WsusScript) -and (-not $Global:TronState.Config.SkipWsusOffline)) {
            Write-TronLog "WSUS Offline updates detected. Using bundled update package..."
            if (-not $Global:TronState.Config.DryRun) {
                Start-Process -FilePath "cmd.exe" -ArgumentList "/c `"$WsusScript`"" -Wait -WindowStyle Hidden
            }
        }
        else {
            Write-TronLog "Using regular online update method..."
            if (-not $Global:TronState.Config.DryRun) {
                Set-Service -Name "wuauserv" -StartupType Automatic -ErrorAction SilentlyContinue
                Start-Service -Name "wuauserv" -ErrorAction SilentlyContinue
                Start-Process -FilePath "wuauclt.exe" -ArgumentList "/detectnow /updatenow" -WindowStyle Hidden
            }
        }
    }

    # 5. DISM Base Reset
    if (-not $Global:TronState.Config.SkipDismCleanup) {
        Write-TronLog "Launch job 'DISM base reset'..."
        if (-not $Global:TronState.Config.DryRun) {
            if ([Environment]::OSVersion.Version.Major -ge 6) {
                $Args = "/online /Cleanup-Image /StartComponentCleanup"
                if ([Environment]::OSVersion.Version.Minor -ge 1) {
                    # Win7/2008R2+
                    $Args += " /ResetBase"
                }
                Start-Process -FilePath "dism.exe" -ArgumentList $Args -Wait -WindowStyle Hidden
            }
        }
    }

    Write-TronLog "Stage 5: Patch complete."
}

function Invoke-Stage6 {
    Write-TronLog "Stage 6: Optimize begin..."

    $ResourcesPath = "$PSScriptRoot\..\Resources"
    $StagePath = "$ResourcesPath\stage_6_optimize"

    # 1. Reset Pagefile
    if ($Global:TronState.Config.SkipPagefileReset) {
        Write-TronLog "Skipping page file reset per config."
    }
    else {
        Write-TronLog "Resetting page file settings to Windows defaults..."
        if (-not $Global:TronState.Config.DryRun) {
            $ComputerSystem = Get-WmiObject Win32_ComputerSystem -ErrorAction SilentlyContinue
            if ($ComputerSystem) {
                $ComputerSystem.AutomaticManagedPagefile = $true
                $ComputerSystem.Put() | Out-Null
            }
        }
    }

    # 2. NGEN .NET Compilation
    Write-TronLog "Launch job 'ngen .NET compilation'..."
    if (-not $Global:TronState.Config.DryRun) {
        $NgenPaths = @(
            "$env:WINDIR\Microsoft.NET\Framework\v4.0.30319\ngen.exe",
            "$env:WINDIR\Microsoft.NET\Framework64\v4.0.30319\ngen.exe"
        )
        foreach ($Ngen in $NgenPaths) {
            if (Test-Path $Ngen) {
                Start-Process -FilePath $Ngen -ArgumentList "executeQueuedItems" -Wait -WindowStyle Hidden
            }
        }
    }

    # 3. Defrag
    # Detect SSD/VM
    $SkipDefrag = $Global:TronState.Config.SkipDefrag
    
    if (-not $SkipDefrag) {
        # Check for SSD
        try {
            $Disks = Get-PhysicalDisk | Where-Object { $_.MediaType -eq "SSD" }
            if ($Disks) {
                Write-TronLog "Solid State hard drive detected. Skipping defrag."
                $SkipDefrag = $true
            }
        }
        catch {
            # Fallback for older OS or if Get-PhysicalDisk fails
        }
    }

    if (-not $SkipDefrag) {
        # Check for VM (Basic check)
        $Model = (Get-WmiObject Win32_ComputerSystem).Model
        if ($Model -match "Virtual|VMware|KVM|Xen") {
            Write-TronLog "Virtual Machine detected. Skipping defrag."
            $SkipDefrag = $true
        }
    }

    if ($SkipDefrag) {
        Write-TronLog "Skipping defrag."
    }
    else {
        Write-TronLog "Launch job 'Defrag $env:SystemDrive'..."
        if (-not $Global:TronState.Config.DryRun) {
            $Defraggler = "$StagePath\defrag\defraggler.exe"
            if (Test-Path $Defraggler) {
                Start-Process -FilePath $Defraggler -ArgumentList "$env:SystemDrive /MinPercent 7" -Wait -WindowStyle Hidden
            }
        }
    }

    Write-TronLog "Stage 6: Optimize complete."
}

function Invoke-Stage7 {
    Write-TronLog "Stage 7: Wrap-up begin..."

    $ResourcesPath = "$PSScriptRoot\..\Resources"
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

function Invoke-Stage8 {
    Write-TronLog "Stage 8: Custom Scripts begin..."

    $ResourcesPath = "$PSScriptRoot\..\Resources"
    $StagePath = "$ResourcesPath\stage_8_custom_scripts"

    if ($Global:TronState.Config.SkipCustomScripts) {
        Write-TronLog "Skipping custom scripts per config."
    }
    else {
        if (Test-Path $StagePath) {
            $Scripts = Get-ChildItem -Path $StagePath -Include "*.bat", "*.ps1" -Recurse
            if ($Scripts) {
                Write-TronLog "Custom scripts detected, executing now..."
                foreach ($Script in $Scripts) {
                    Write-TronLog "Executing $($Script.Name)..."
                    if (-not $Global:TronState.Config.DryRun) {
                        if ($Script.Extension -eq ".bat") {
                            Start-Process -FilePath "cmd.exe" -ArgumentList "/c `"$($Script.FullName)`"" -Wait -WindowStyle Hidden
                        }
                        elseif ($Script.Extension -eq ".ps1") {
                            Start-Process -FilePath "powershell.exe" -ArgumentList "-ExecutionPolicy Bypass -File `"$($Script.FullName)`"" -Wait -WindowStyle Hidden
                        }
                    }
                    Write-TronLog "$($Script.Name) done."
                }
            }
            else {
                Write-TronLog "No custom scripts found."
            }
        }
    }

    Write-TronLog "Stage 8: Custom Scripts complete."
}

Export-ModuleMember -Function Invoke-Stage*
