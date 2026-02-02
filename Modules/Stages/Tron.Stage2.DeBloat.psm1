# Tron.Stage2.DeBloat.psm1
# Stage 2: De-bloat

function Invoke-Stage2 {
    Write-TronLog "Stage 2: De-bloat begin..."

    $ResourcesPath = "$PSScriptRoot\..\..\Resources"
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

    # 2. Remove Bloat by GUID
    # Native implementation of searching MSI products by GUID
    if (-not $Global:TronState.Config.DryRun) {
        $GuidLists = @("$OemPath\programs_to_target_by_GUID.txt", "$OemPath\toolbars_BHOs_to_target_by_GUID.txt")
        
        # Build target GUID list
        $TargetGuids = New-Object System.Collections.Generic.HashSet[string]
        foreach ($ListFile in $GuidLists) {
            if (Test-Path $ListFile) {
                Get-Content $ListFile | Where-Object { $_ -match "^\{" } | ForEach-Object { $TargetGuids.Add($_) | Out-Null }
            }
        }

        if ($TargetGuids.Count -gt 0) {
            Write-TronLog "Scanning installed products against $($TargetGuids.Count) target GUIDs..." "DEBUG"
            $InstalledProducts = Get-WmiObject -Class Win32_Product | Select-Object -Property IdentifyingNumber, Name

            foreach ($Product in $InstalledProducts) {
                if ($TargetGuids.Contains($Product.IdentifyingNumber)) {
                    Write-TronLog "Removing Bloatware: $($Product.Name) ($($Product.IdentifyingNumber))"
                    $Product.Uninstall() | Out-Null
                    Clear-PendingFileRename
                }
            }
        }
    }

    # 3. Remove Bloat by Name (Wildcard)
    Write-TronLog "Attempt junkware removal: Phase 3 (wildcard by name)..."
    if (-not $Global:TronState.Config.DryRun) {
        $NameListFile = "$OemPath\programs_to_target_by_name.txt"
        if (Test-Path $NameListFile) {
            $Names = Get-Content $NameListFile | Where-Object { $_ -notmatch "^::" -and $_ -notmatch "^set" -and $_.Trim().Length -gt 0 }
            foreach ($Name in $Names) {
                Write-TronLog "Checking for: $Name" "DEBUG"
                try {
                    $Apps = Get-WmiObject -Class Win32_Product -Filter "Name like '$Name'" -ErrorAction SilentlyContinue
                    foreach ($App in $Apps) {
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
                # Win10 - Use native PS1 scripts if available, or implement logic directly?
                # For now, invoking the existing scripts is safer as they contain curated lists.
                $MetroScripts = @("metro_3rd_party_modern_apps_to_target_by_name.ps1", "metro_Microsoft_modern_apps_to_target_by_name.ps1")
                foreach ($Script in $MetroScripts) {
                    $ScriptPath = "$StagePath\metro\$Script"
                    if (Test-Path $ScriptPath) {
                        Start-Process "powershell.exe" -ArgumentList "-ExecutionPolicy Bypass -File `"$ScriptPath`"" -Wait -WindowStyle Hidden
                    }
                }
            }
            else {
                # Win8/8.1 Native
                Get-AppxProvisionedPackage -Online | Remove-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue
                Get-AppxPackage -AllUsers | Remove-AppxPackage -ErrorAction SilentlyContinue
            }
        }
    }

    # 5. OneDrive Removal (Win10)
    if ([Environment]::OSVersion.Version.Major -eq 10 -and -not $Global:TronState.Config.DryRun) {
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

Export-ModuleMember -Function Invoke-Stage2
