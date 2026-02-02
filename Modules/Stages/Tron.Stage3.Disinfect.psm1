# Tron.Stage3.Disinfect.psm1
# Stage 3: Disinfect

function Invoke-Stage3 {
    Write-TronLog "Stage 3: Disinfect begin..."

    $ResourcesPath = "$PSScriptRoot\..\..\Resources"
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

Export-ModuleMember -Function Invoke-Stage3
