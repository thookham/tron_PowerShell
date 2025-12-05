$ScriptDir = Split-Path $PSScriptRoot -Parent

# Stub dependency
function Write-TronLog { param($Message, $Type) }
function Get-TronConfig { return @{ DryRun = $false } } # Stub config
$Global:TronState = @{ Config = @{ DryRun = $false } }

Import-Module "$ScriptDir\Modules\Tron.Telemetry.psm1" -Force

Describe "Tron.Telemetry Module" {
    
    It "Should export Invoke-TelemetryCleanup" {
        Get-Command Invoke-TelemetryCleanup -ErrorAction SilentlyContinue | Should -Not BeNullOrEmpty
    }

    It "Should export Invoke-FileExtensionRepair" {
        Get-Command Invoke-FileExtensionRepair -ErrorAction SilentlyContinue | Should -Not BeNullOrEmpty
    }

    Context "Invoke-TelemetryCleanup" {
        Mock Write-TronLog {}
        
        It "Should run without errors in basic invocation" {
            { Invoke-TelemetryCleanup -StagePath "C:\Temp" } | Should -Not -Throw
        }
    }

    Context "Invoke-FileExtensionRepair" {
        Mock Write-TronLog {}
        Mock Get-ChildItem { return @() }
        Mock Test-Path { return $true }

        It "Should run without errors with valid path" {
            { Invoke-FileExtensionRepair -ResourcePath "C:\Temp" } | Should -Not -Throw
        }
    }
}
