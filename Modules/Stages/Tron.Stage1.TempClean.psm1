# Tron.Stage1.TempClean.psm1
# Stage 1: TempClean

function Invoke-Stage1 {
    Write-TronLog "Stage 1: TempClean begin..."

    $ResourcesPath = "$PSScriptRoot\..\..\Resources"
    $StagePath = "$ResourcesPath\stage_1_tempclean"

    # 1. Clear CryptNet SSL certificate cache
    Write-TronLog "Launch job 'Clear CryptNet SSL certificate cache'..."
    if (-not $Global:TronState.Config.DryRun) {
        certutil -URLcache * delete | Out-Null
    }

    # 2. Clean Internet Explorer -> General Browser Cleanup
    # IE is less relevant, but we can clear native caches
    Write-TronLog "Launch job 'Clean Browser Caches'..."
    if (-not $Global:TronState.Config.DryRun) {
        Start-Process -FilePath "rundll32.exe" -ArgumentList "inetcpl.cpl,ClearMyTracksByProcess 4351" -Wait
    }

    # 3. TempFileCleanup -> Native Cleanup
    Write-TronLog "Launch job 'TempFileCleanup (Native)'..."
    if (-not $Global:TronState.Config.DryRun) {
        $TempPaths = @(
            $env:TEMP,
            "$env:WINDIR\Temp",
            "$env:LOCALAPPDATA\Temp"
        )
        
        foreach ($Path in $TempPaths) {
            if (Test-Path $Path) {
                Get-ChildItem -Path $Path -Recurse -Force -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
            }
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

Export-ModuleMember -Function Invoke-Stage1
