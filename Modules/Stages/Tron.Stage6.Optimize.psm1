# Tron.Stage6.Optimize.psm1
# Stage 6: Optimize

function Invoke-Stage6 {
    Write-TronLog "Stage 6: Optimize begin..."

    $ResourcesPath = "$PSScriptRoot\..\..\Resources"
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
            # Prefer native defrag over bundled defraggler if possible, but keep defraggler as option
            if (Test-Path $Defraggler) {
                Start-Process -FilePath $Defraggler -ArgumentList "$env:SystemDrive /MinPercent 7" -Wait -WindowStyle Hidden
            } else {
                 # Native fallback
                 Start-Process -FilePath "defrag.exe" -ArgumentList "$env:SystemDrive /O /U /V" -Wait -WindowStyle Hidden
            }
        }
    }

    Write-TronLog "Stage 6: Optimize complete."
}

Export-ModuleMember -Function Invoke-Stage6
