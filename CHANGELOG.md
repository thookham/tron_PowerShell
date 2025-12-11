# Changelog

All notable changes to this project will be documented in this file.

## [1.0.2] - 2025-12-11

### Added

- GitHub Actions workflow (`ci.yml`) for automated testing and builds.
- Unit tests for Stage 1 (TempClean) (`Tests\Tron.Stage1.Tests.ps1`).

### Fixed

- Fixed missing `Tron.Core` dependency in `Tron.Stages.psm1`.

## [1.0.1] - 2025-12-11

### Added

- `Remote-Tron.ps1` for remote execution capability.
- Unit tests for Telemetry module (`Tests\Tron.Telemetry.Tests.ps1`).

### Changed

- Updated `Debug-Tron.ps1` to correctly mock environment variables for sandboxing.
- Sanitized contact information in documentation.
- Removed legacy Sophos configuration.

### Fixed

- Fixed Pester syntax in Telemetry tests to be compatible with Pester 3.4.0.
