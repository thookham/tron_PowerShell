# Tron.Telemetry.psm1
# Handles telemetry disabling and file extension repair (Stage 4)

function Invoke-TelemetryCleanup {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$StagePath
    )
    
    Write-TronLog "Starting Telemetry Cleanup..."
    
    # 1. Scheduled Tasks
    Write-TronLog "Removing telemetry-related scheduled tasks..."
    $TelemetryTasks = @(
        "\Microsoft\Windows\Application Experience\Microsoft Compatibility Appraiser",
        "\Microsoft\Windows\Application Experience\ProgramDataUpdater",
        "\Microsoft\Windows\Autochk\Proxy",
        "\Microsoft\Windows\Customer Experience Improvement Program\Consolidator",
        "\Microsoft\Windows\Customer Experience Improvement Program\KernelCeipTask",
        "\Microsoft\Windows\Customer Experience Improvement Program\UsbCeip",
        "\Microsoft\Windows\DiskDiagnostic\Microsoft-Windows-DiskDiagnosticDataCollector",
        "\Microsoft\Windows\PI\Sqm-Tasks",
        "\Microsoft\Windows\Power Efficiency Diagnostics\AnalyzeSystem",
        "\Microsoft\Windows\Windows Error Reporting\QueueReporting",
        "\Microsoft\Windows\application experience\aitagent",
        "\Microsoft\Windows\maintenance\winsat",
        "\Microsoft\Windows\media center\activateWindowssearch",
        "\Microsoft\Windows\media center\configureinternettimeservice",
        "\Microsoft\Windows\media center\dispatchrecoverytasks",
        "\Microsoft\Windows\media center\ehdrminit",
        "\Microsoft\Windows\media center\installplayready",
        "\Microsoft\Windows\media center\mcupdate",
        "\Microsoft\Windows\media center\mediacenterrecoverytask",
        "\Microsoft\Windows\media center\objectstorerecoverytask",
        "\Microsoft\Windows\media center\ocuractivate",
        "\Microsoft\Windows\media center\ocurdiscovery",
        "\Microsoft\Windows\media center\pbdadiscovery",
        "\Microsoft\Windows\media center\pbdadiscoveryw1",
        "\Microsoft\Windows\media center\pbdadiscoveryw2",
        "\Microsoft\Windows\media center\pvrrecoverytask",
        "\Microsoft\Windows\media center\pvrscheduletask",
        "\Microsoft\Windows\media center\registersearch",
        "\Microsoft\Windows\media center\reindexsearchroot",
        "\Microsoft\Windows\media center\sqlliterecoverytask",
        "\Microsoft\Windows\media center\updaterecordpath"
    )

    foreach ($Task in $TelemetryTasks) {
        if (-not $Global:TronState.Config.DryRun) {
            Unregister-ScheduledTask -TaskName $Task -Confirm:$false -ErrorAction SilentlyContinue
        }
    }

    # 2. Services
    Write-TronLog "Removing bad services..."
    # Services to Disable
    $DisableServices = @(
        "Diagtrack",
        "remoteregistry",
        "dmwappushservice",
        "Wecsvc"
    )
    
    # Services to Demand Start
    $DemandServices = @(
        "XblAuthManager",
        "XblGameSave",
        "XboxNetApiSvc",
        "XboxGipSvc",
        "xbgm"
    )

    # Services to Delete (RetailDemo)
    $DeleteServices = @("RetailDemo")

    foreach ($Service in $DisableServices) {
        if (-not $Global:TronState.Config.DryRun) {
            Stop-Service -Name $Service -Force -ErrorAction SilentlyContinue
            Set-Service -Name $Service -StartupType Disabled -ErrorAction SilentlyContinue
        }
    }

    foreach ($Service in $DemandServices) {
        if (-not $Global:TronState.Config.DryRun) {
            Stop-Service -Name $Service -Force -ErrorAction SilentlyContinue
            Set-Service -Name $Service -StartupType Manual -ErrorAction SilentlyContinue
        }
    }

    foreach ($Service in $DeleteServices) {
        if (-not $Global:TronState.Config.DryRun) {
            Stop-Service -Name $Service -Force -ErrorAction SilentlyContinue
            # There is no native Remove-Service in older PS, using sc.exe
            Start-Process "sc.exe" -ArgumentList "delete $Service" -Wait -WindowStyle Hidden
        }
    }

    # 3. Registry Entries
    Write-TronLog "Toggling official MS telemetry registry entries..."
    
    $RegistrySettings = @(
        @{ Path = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"; Name = "SilentInstalledAppsEnabled"; Value = 0; Type = "DWord" },
        @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection"; Name = "AllowTelemetry"; Value = 0; Type = "DWord" },
        @{ Path = "HKLM:\SOFTWARE\Wow6432Node\Policies\Microsoft\Windows\DataCollection"; Name = "AllowTelemetry"; Value = 0; Type = "DWord" },
        @{ Path = "HKLM:\SYSTEM\CurrentControlSet\Control\WMI\AutoLogger\AutoLogger-Diagtrack-Listener"; Name = "Start"; Value = 0; Type = "DWord" },
        @{ Path = "HKLM:\SYSTEM\CurrentControlSet\Control\WMI\Autologger\Diagtrack-Listener"; Name = "Start"; Value = 0; Type = "DWord" },
        @{ Path = "HKLM:\software\microsoft\wcmsvc\wifinetworkmanager"; Name = "wifisensecredshared"; Value = 0; Type = "DWord" },
        @{ Path = "HKLM:\software\microsoft\wcmsvc\wifinetworkmanager"; Name = "wifisenseopen"; Value = 0; Type = "DWord" },
        @{ Path = "HKLM:\software\microsoft\windows defender\spynet"; Name = "spynetreporting"; Value = 0; Type = "DWord" },
        @{ Path = "HKLM:\software\microsoft\windows defender\spynet"; Name = "submitsamplesconsent"; Value = 0; Type = "DWord" },
        @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search"; Name = "AllowCortana"; Value = 0; Type = "DWord" },
        @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search"; Name = "AllowCortanaAboveLock"; Value = 0; Type = "DWord" },
        @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search"; Name = "AllowSearchToUseLocation"; Value = 0; Type = "DWord" },
        @{ Path = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search"; Name = "BingSearchEnabled"; Value = 0; Type = "DWord" },
        @{ Path = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search"; Name = "BingSearchEnabled"; Value = 0; Type = "DWord" },
        @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent"; Name = "DisableWindowsConsumerFeatures"; Value = 1; Type = "DWord" }
    )

    foreach ($Reg in $RegistrySettings) {
        if (-not $Global:TronState.Config.DryRun) {
            if (-not (Test-Path $Reg.Path)) {
                New-Item -Path $Reg.Path -Force -ErrorAction SilentlyContinue | Out-Null
            }
            Set-ItemProperty -Path $Reg.Path -Name $Reg.Name -Value $Reg.Value -Type $Reg.Type -ErrorAction SilentlyContinue
        }
    }

    # 4. Immunizations (Spybot, O&O)
    Write-TronLog "Applying immunizations (Spybot Anti-Beacon & O&O ShutUp10)..."
    if (-not $Global:TronState.Config.DryRun) {
        $TelemetryDir = "$StagePath\disable_windows_telemetry"
        
        # Spybot Anti-Beacon
        $Spybot = Get-ChildItem "$TelemetryDir\Spybot Anti-Beacon*.exe" | Select-Object -First 1
        if ($Spybot) {
            Write-TronLog "Running Spybot Anti-Beacon..."
            Start-Process -FilePath $Spybot.FullName -ArgumentList "/apply /silent" -Wait -WindowStyle Hidden
        }

        # O&O ShutUp10
        $OOShutUp = "$TelemetryDir\OOShutUp10.exe"
        $OOCfg = "$TelemetryDir\ooshutup10_tron_settings.cfg"
        if (Test-Path $OOShutUp) {
            Write-TronLog "Running O&O ShutUp10..."
            Start-Process -FilePath $OOShutUp -ArgumentList "`"$OOCfg`" /quiet" -Wait -WindowStyle Hidden
        }
    }

    # 5. Route Blocking
    Write-TronLog "Null-routing bad hosts... (Skipped in this version)"
    
    Write-TronLog "Telemetry Cleanup complete."
}

function Invoke-FileExtensionRepair {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ResourcePath
    )
    
    Write-TronLog "Starting File Extension Repair..."
    
    if (Test-Path $ResourcePath) {
        $RegFiles = Get-ChildItem -Path $ResourcePath -Filter "*.reg"
        foreach ($File in $RegFiles) {
            Write-TronLog "Importing: $($File.Name)"
            if (-not $Global:TronState.Config.DryRun) {
                Start-Process "reg.exe" -ArgumentList "import `"$($File.FullName)`"" -Wait -WindowStyle Hidden
            }
        }
    }
    else {
        Write-TronLog "Resource path not found: $ResourcePath" "WARN"
    }

    Write-TronLog "File Extension Repair complete."
}

Export-ModuleMember -Function Invoke-TelemetryCleanup, Invoke-FileExtensionRepair
