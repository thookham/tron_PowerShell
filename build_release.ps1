<#
.SYNOPSIS
    Builds Tron PowerShell release packages (ZIP and SFX EXE).
.DESCRIPTION
    This script creates a 'releases' directory and packages the current Tron PowerShell version
    into a .zip file and, if 7-Zip is available, a self-extracting .exe.
#>

$Version = "1.0.1"
$ReleaseDate = "2025-12-05"
$OutputDir = Join-Path $PSScriptRoot "releases"
$SourceFiles = @("Tron.ps1", "Modules", "Resources", "Config", "README.md", "LICENSE", "changelog.txt")

# Ensure output directory exists
if (-not (Test-Path $OutputDir)) {
    New-Item -ItemType Directory -Path $OutputDir | Out-Null
}

Write-Host "Building Tron PowerShell v$Version ($ReleaseDate)..." -ForegroundColor Cyan

# --- Locate 7-Zip ---
$7zPath = $null
$7zSfxPath = $null

$PossiblePaths = @(
    "$env:ProgramFiles\7-Zip\7z.exe",
    "$env:ProgramFiles(x86)\7-Zip\7z.exe",
    "C:\Program Files\7-Zip\7z.exe"
)

foreach ($path in $PossiblePaths) {
    if (Test-Path $path) {
        $7zPath = $path
        $7zSfxPath = Join-Path (Get-Item $path).Directory.FullName "7z.sfx"
        break
    }
}

if (-not $7zPath) {
    # Check PATH
    try {
        $7zPath = (Get-Command "7z" -ErrorAction Stop).Source
        $7zSfxPath = Join-Path (Get-Item $7zPath).Directory.FullName "7z.sfx"
    }
    catch {
        Write-Warning "7-Zip not found. SFX (.exe) creation will be skipped."
    }
}

# --- Create ZIP Package ---
$ZipFileName = "tron_powershell_v$Version.zip"
$ZipFilePath = Join-Path $OutputDir $ZipFileName

Write-Host "Creating ZIP package: $ZipFileName"
if (Test-Path $ZipFilePath) { Remove-Item $ZipFilePath -Force }

# Create a temporary directory for staging
$StageDir = Join-Path $env:TEMP "tron_ps_build_stage_$((Get-Random))"
$TronStageDir = Join-Path $StageDir "tron_powershell"
New-Item -ItemType Directory -Path $TronStageDir -Force | Out-Null

foreach ($item in $SourceFiles) {
    $itemPath = Join-Path $PSScriptRoot $item
    if (Test-Path $itemPath) {
        Copy-Item -Path $itemPath -Destination $TronStageDir -Recurse -Force
    }
    else {
        Write-Warning "Source file not found: $item"
    }
}

# Compress
Compress-Archive -Path "$TronStageDir\*" -DestinationPath $ZipFilePath -Force
Write-Host "ZIP package created successfully." -ForegroundColor Green

# --- Create SFX EXE Package ---
if ($7zPath -and (Test-Path $7zSfxPath)) {
    $ExeFileName = "tron_powershell_v$Version.exe"
    $ExeFilePath = Join-Path $OutputDir $ExeFileName
    
    Write-Host "Creating SFX EXE package: $ExeFileName"
    if (Test-Path $ExeFilePath) { Remove-Item $ExeFilePath -Force }

    # SFX Config
    $SfxConfigPath = Join-Path $StageDir "config.txt"
    # Note: Running PowerShell directly from SFX might require a wrapper or specific command
    # We'll try to launch PowerShell with the script
    $SfxConfigContent = @(
        ";!@Install@!UTF-8!",
        "Title=""Tron PowerShell v$Version""",
        "Progress=""yes""",
        "RunProgram=""powershell.exe -ExecutionPolicy Bypass -NoProfile -File Tron.ps1""",
        ";!@InstallEnd@!"
    )
    Set-Content -Path $SfxConfigPath -Value $SfxConfigContent -Encoding UTF8

    # Create 7z archive for SFX
    $Temp7zPath = Join-Path $StageDir "payload.7z"
    
    # We use the staging dir content
    $ProcessInfo = New-Object System.Diagnostics.ProcessStartInfo
    $ProcessInfo.FileName = $7zPath
    $ProcessInfo.Arguments = "a -mx9 ""$Temp7zPath"" ""$TronStageDir\*"""
    $ProcessInfo.RedirectStandardOutput = $true
    $ProcessInfo.UseShellExecute = $false
    $Process = [System.Diagnostics.Process]::Start($ProcessInfo)
    $Process.WaitForExit()

    # Combine SFX module + Config + Archive
    # copy /b 7z.sfx + config.txt + payload.7z tron.exe
    
    $SfxBytes = [System.IO.File]::ReadAllBytes($7zSfxPath)
    $ConfigBytes = [System.IO.File]::ReadAllBytes($SfxConfigPath)
    $PayloadBytes = [System.IO.File]::ReadAllBytes($Temp7zPath)
    
    $OutputStream = [System.IO.File]::OpenWrite($ExeFilePath)
    $OutputStream.Write($SfxBytes, 0, $SfxBytes.Length)
    $OutputStream.Write($ConfigBytes, 0, $ConfigBytes.Length)
    $OutputStream.Write($PayloadBytes, 0, $PayloadBytes.Length)
    $OutputStream.Close()
    
    Write-Host "SFX EXE package created successfully." -ForegroundColor Green
}
elseif ($7zPath -and -not (Test-Path $7zSfxPath)) {
    Write-Warning "7-Zip found but '7z.sfx' module is missing. Skipping EXE creation."
}

# Cleanup
Remove-Item $StageDir -Recurse -Force

Write-Host "Build complete. Artifacts in: $OutputDir" -ForegroundColor Cyan
