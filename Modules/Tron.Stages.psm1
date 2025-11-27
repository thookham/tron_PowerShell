# Tron.Stages.psm1
# Stage logic for Tron PowerShell

function Invoke-Stage0-Prep {
    param([string]$ResourcesPath)
    Write-TronLog "=== Stage 0: Prep ===" "INFO"
    
    if ($Global:TronMode -eq "Limited") {
        Write-TronLog "Skipping Restore Point creation (Limited Mode)." "WARNING"
    }
    else {
        Write-TronLog "Creating System Restore Point..." "INFO"
        try {
            Checkpoint-Computer -Description "Tron Prep" -RestorePointType "MODIFY_SETTINGS" -ErrorAction Stop
            Write-TronLog "Restore Point created." "SUCCESS"
        }
        catch {
            Write-TronLog "Failed to create Restore Point: $_" "ERROR"
        }
    }
    
    # TODO: Add Rkill, TDSSKiller logic here
}

function Invoke-Stage1-TempClean {
    Write-TronLog "=== Stage 1: TempClean ===" "INFO"
    
    Write-TronLog "Cleaning Recycle Bin..." "INFO"
    try {
        Clear-RecycleBin -Force -ErrorAction SilentlyContinue
        Write-TronLog "Recycle Bin cleaned." "SUCCESS"
    }
    catch {
        Write-TronLog "Failed to clean Recycle Bin: $_" "WARNING"
    }
    
    Write-TronLog "Cleaning Temp folders..." "INFO"
    $Paths = Get-TronPaths
    $TempFolders = @($Paths.Temp, $Paths.WindowsTemp)
    foreach ($Folder in $TempFolders) {
        if (Test-Path $Folder) {
            Get-ChildItem -Path $Folder -Recurse -Force -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}

function Invoke-Stage2-Debloat {
    param([bool]$SkipDebloat)
    Write-TronLog "=== Stage 2: De-bloat ===" "INFO"
    
    if ($SkipDebloat) {
        Write-TronLog "Skipping De-bloat as requested." "INFO"
        return
    }
    
    if ($Global:TronMode -eq "Limited") {
        Write-TronLog "Skipping Appx removal (Limited Mode)." "WARNING"
        return
    }

    # Example Bloatware List (Should be externalized to a file)
    $Bloatware = @("Microsoft.3DBuilder", "Microsoft.BingNews")
    
    foreach ($App in $Bloatware) {
        Write-TronLog "Removing $App..." "INFO"
        Get-AppxPackage -Name $App -ErrorAction SilentlyContinue | Remove-AppxPackage -ErrorAction SilentlyContinue
    }
}

function Invoke-Stage3-Disinfect {
    param(
        [string]$ResourcesPath,
        [bool]$SkipAntivirusScans
    )
    Write-TronLog "=== Stage 3: Disinfect ===" "INFO"
    
    if ($SkipAntivirusScans) {
        Write-TronLog "Skipping Antivirus Scans as requested." "INFO"
        return
    }
    
    # MBAM, AdwCleaner, KVRT execution logic would go here
    # Using Start-Process -Wait
}

function Invoke-Stage4-Repair {
    Write-TronLog "=== Stage 4: Repair ===" "INFO"
    
    if ($Global:TronMode -eq "Limited") {
        Write-TronLog "Skipping DISM and SFC (Limited Mode)." "WARNING"
        return
    }
    
    Write-TronLog "Running DISM Image Cleanup..." "INFO"
    Start-Process -FilePath "dism.exe" -ArgumentList "/Online /Cleanup-Image /RestoreHealth" -Wait -NoNewWindow
    
    Write-TronLog "Running SFC Scan..." "INFO"
    Start-Process -FilePath "sfc.exe" -ArgumentList "/scannow" -Wait -NoNewWindow
}

function Invoke-Stage5-Patch {
    Write-TronLog "=== Stage 5: Patch ===" "INFO"
    # Update 7-Zip, Windows Updates
}

function Invoke-Stage6-Optimize {
    param([bool]$SkipDefrag)
    Write-TronLog "=== Stage 6: Optimize ===" "INFO"
    
    if ($SkipDefrag) {
        Write-TronLog "Skipping Defrag as requested." "INFO"
        return
    }
    
    if ($Global:TronMode -eq "Limited") {
        Write-TronLog "Skipping Optimization (Limited Mode)." "WARNING"
        return
    }

    Write-TronLog "Optimizing Storage..." "INFO"
    Optimize-Volume -DriveLetter C -ReTrim -Verbose
}

function Invoke-Stage7-WrapUp {
    Write-TronLog "=== Stage 7: Wrap-up ===" "INFO"
    # Email reports, log collection
}

function Invoke-Stage8-Custom {
    param(
        [string]$ResourcesPath,
        [bool]$SkipCustomScripts
    )
    Write-TronLog "=== Stage 8: Custom Scripts ===" "INFO"
    
    if ($SkipCustomScripts) {
        Write-TronLog "Skipping Custom Scripts as requested." "INFO"
        return
    }
    
    $CustomScriptsPath = Join-Path $ResourcesPath "Stage8_Custom"
    if (Test-Path $CustomScriptsPath) {
        $Scripts = Get-ChildItem -Path $CustomScriptsPath -Include *.ps1, *.bat -Recurse
        foreach ($Script in $Scripts) {
            Write-TronLog "Executing $($Script.Name)..." "INFO"
            if ($Script.Extension -eq ".ps1") {
                & $Script.FullName
            }
            elseif ($Script.Extension -eq ".bat") {
                Start-Process -FilePath $Script.FullName -Wait
            }
        }
    }
}

Export-ModuleMember -Function Invoke-Stage0-Prep, Invoke-Stage1-TempClean, Invoke-Stage2-Debloat, Invoke-Stage3-Disinfect, Invoke-Stage4-Repair, Invoke-Stage5-Patch, Invoke-Stage6-Optimize, Invoke-Stage7-WrapUp, Invoke-Stage8-Custom
