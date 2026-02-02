# Tron.Stage5.Patch.psm1
# Stage 5: Patch

function Invoke-Stage5 {
    Write-TronLog "Stage 5: Patch begin..."

    $ResourcesPath = "$PSScriptRoot\..\..\Resources"
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
        # Detecting modern 7-zip install location
        $7ZipInstalled = (Test-Path "$env:ProgramFiles\7-Zip") -or (Test-Path "${env:ProgramFiles(x86)}\7-Zip")
        if ($7ZipInstalled) {
            Write-TronLog "7-Zip detected, updating..."
            if (-not $Global:TronState.Config.DryRun) {
                # Calling the original installer script for simplicity as it handles msi logic well
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
                # Modern Windows Update Trigger via USOClient if available (Win10+)
                if (Get-Command "usoclient.exe" -ErrorAction SilentlyContinue) {
                     Start-Process -FilePath "usoclient.exe" -ArgumentList "StartScan" -WindowStyle Hidden
                } else {
                    # Legacy fallback
                    Set-Service -Name "wuauserv" -StartupType Automatic -ErrorAction SilentlyContinue
                    Start-Service -Name "wuauserv" -ErrorAction SilentlyContinue
                    Start-Process -FilePath "wuauclt.exe" -ArgumentList "/detectnow /updatenow" -WindowStyle Hidden
                }
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

Export-ModuleMember -Function Invoke-Stage5
