# Building Tron PowerShell

This document explains how to build release packages for Tron PowerShell.

## Prerequisites

### Required
- **PowerShell 5.1 or higher** (included with Windows 10/11)
- **Windows OS** (Windows 7 SP1 or later)
- Git (for cloning the repository)

### Optional
- **7-Zip** (latest version) - Required for creating self-extracting `.exe` packages
  - Download from: https://www.7-zip.org/
  - Install to default location or add to PATH

## Quick Build

The simplest way to build a release:

```powershell
# Navigate to the repository root
cd tron_PowerShell

# Run the build script
.\build_release.ps1
```

This will create packages in the `releases` directory.

## Build Process Details

### What Gets Built

The build script (`build_release.ps1`) creates two package types:

1. **ZIP Package** (`tron_powershell_v{version}.zip`)
   - Standard compressed archive
   - Compatible with all Windows versions
   - Can be extracted and run manually

2. **Self-Extracting EXE** (`tron_powershell_v{version}.exe`) *- Requires 7-Zip*
   - Self-extracting archive
   - Automatically launches Tron after extraction
   - Convenient for end users

### Files Included in Packages

The build script packages the following:
- `Tron.ps1` - Main entry point
- `Modules/` - Core and stage modules
- `Resources/` - Third-party tools and assets
- `Config/` - Configuration files
- `README.md` - User documentation
- `LICENSE` - License information
- `changelog.txt` - Version history

### Build Output

Packages are created in:
```
tron_PowerShell/
└── releases/
    ├── tron_powershell_v1.0.0.zip
    └── tron_powershell_v1.0.0.exe  (if 7-Zip is available)
```

## Modifying the Build

### Changing the Version

Edit `build_release.ps1` and update these variables:

```powershell
$Version = "1.0.0"        # Semantic version
$ReleaseDate = "2025-11-27"  # Release date
```

> [!IMPORTANT]
> Also update the version in `Tron.ps1` (line 52) to match:
> ```powershell
> Write-TronLog "Tron PowerShell Edition v1.0.0 Initialized"
> ```

### Adding Files to the Package

Edit the `$SourceFiles` array in `build_release.ps1`:

```powershell
$SourceFiles = @(
    "Tron.ps1",
    "Modules",
    "Resources",
    "Config",
    "README.md",
    "LICENSE",
    "changelog.txt",
    "YourNewFile.txt"  # Add your file here
)
```

### Custom SFX Configuration

The self-extracting executable behavior can be modified by editing the SFX configuration in `build_release.ps1`:

```powershell
$SfxConfigContent = @(
    ";!@Install@!UTF-8!",
    "Title=""Tron PowerShell v$Version""",
    "Progress=""yes""",
    "RunProgram=""powershell.exe -ExecutionPolicy Bypass -NoProfile -File Tron.ps1""",
    ";!@InstallEnd@!"
)
```

**Configuration Options:**
- `Title` - Window title during extraction
- `Progress` - Show/hide progress bar ("yes"/"no")
- `RunProgram` - Command to run after extraction

## Build Troubleshooting

### 7-Zip Not Found

**Symptom:** Build completes but only creates ZIP, warns about missing 7-Zip

**Solution:** 
1. Install 7-Zip from https://www.7-zip.org/
2. Install to default location (`C:\Program Files\7-Zip\`)
3. Or add 7-Zip to your PATH environment variable

### Permission Errors

**Symptom:** Access denied errors when creating files

**Solution:** Run PowerShell as Administrator:
```powershell
# Right-click PowerShell and select "Run as Administrator"
.\build_release.ps1
```

### Staging Directory Cleanup Failed

**Symptom:** Warning about inability to remove temp staging directory

**Solution:** Temporary files in `%TEMP%\tron_ps_build_stage_*` may be locked. Close any open file explorers and try again, or manually delete after reboot.

## Testing a Build

Before distributing a release:

1. **Extract and Inspect:**
   ```powershell
   # Extract the ZIP
   Expand-Archive -Path releases\tron_powershell_v1.0.0.zip -DestinationPath test_extract
   cd test_extract\tron_powershell
   ```

2. **Dry Run Test:**
   ```powershell
   # Test without making changes
   .\Tron.ps1 -DryRun -Verbose
   ```

3. **Sandbox Test:**
   ```powershell
   # Test with Debug-Tron.ps1 (creates isolated sandbox)
   .\Debug-Tron.ps1
   ```

4. **Full Test (Non-Production System):**
   ```powershell
   # Run on a test machine or VM
   .\Tron.ps1 -Verbose
   ```

## Creating a GitHub Release

After building successfully:

1. **Tag the Release:**
   ```powershell
   git tag -a v1.0.0 -m "Release version 1.0.0"
   git push origin v1.0.0
   ```

2. **Create GitHub Release:**
   - Go to: https://github.com/thookham/tron_PowerShell/releases/new
   - Select your tag
   - Add release notes from `changelog.txt`
   - Upload both `.zip` and `.exe` files
   - Publish release

## Continuous Integration (Future)

> [!NOTE]
> Automated builds via GitHub Actions are planned for future releases. This will automatically build and attach artifacts to releases.

## Additional Resources

- [Architecture Documentation](ARCHITECTURE.md)
- [Contributing Guidelines](CONTRIBUTING.md)
- [Main README](README.md)

---

**Questions?** Open an issue on GitHub: https://github.com/thookham/tron_PowerShell/issues
