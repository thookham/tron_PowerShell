# Tron.Stage8.CustomScripts.psm1
# Stage 8: Custom Scripts

function Invoke-Stage8 {
    Write-TronLog "Stage 8: Custom Scripts begin..."

    $ResourcesPath = "$PSScriptRoot\..\..\Resources"
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
                        try {
                            if ($Script.Extension -eq ".bat") {
                                Start-Process -FilePath "cmd.exe" -ArgumentList "/c `"$($Script.FullName)`"" -Wait -WindowStyle Hidden
                            }
                            elseif ($Script.Extension -eq ".ps1") {
                                Start-Process -FilePath "powershell.exe" -ArgumentList "-ExecutionPolicy Bypass -File `"$($Script.FullName)`"" -Wait -WindowStyle Hidden
                            }
                        }
                        catch {
                             Write-TronLog "Error executing custom script $($Script.Name): $_" "ERROR"
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

Export-ModuleMember -Function Invoke-Stage8
