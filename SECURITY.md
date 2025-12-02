# Security Policy

## Overview

Tron PowerShell is a system maintenance and cleaning tool that requires elevated privileges to function properly. As such, security is a critical concern. This document outlines our security practices and how to report security vulnerabilities.

## Supported Versions

We provide security updates for the following versions:

| Version | Supported          | Status |
| ------- | ------------------ | ------ |
| 1.0.x   | :white_check_mark: | Current stable release |
| < 1.0   | :x:                | Legacy batch version (separate repository) |

## Security Considerations

### Running Tron Safely

> [!CAUTION]
> Tron requires Administrator privileges to perform many of its operations. Always review the code and understand what it does before running it on production systems.

**Best Practices:**
- Always download Tron from the official repository
- Verify the integrity of downloaded files
- Review the code before running, especially if making modifications
- Test in a non-production environment first (use `Debug-Tron.ps1` for sandbox testing)
- Use the `-DryRun` parameter to preview actions without making changes
- Back up important data before running Tron

### What Tron Does

Tron performs system modifications including:
- Removing installed applications and bloatware
- Modifying system settings and registry entries
- Deleting temporary files and caches
- Running third-party security tools
- Disabling telemetry and tracking features
- Executing custom scripts from Stage 8

### Third-Party Tools

Tron includes and executes several third-party tools:
- Malwarebytes Anti-Malware
- Kaspersky Virus Removal Tool
- AdwCleaner
- CCleaner
- RKill
- And others

While we strive to keep these tools updated, users should be aware that these tools are maintained by their respective authors and may have their own security considerations.

## Reporting a Vulnerability

### How to Report

If you discover a security vulnerability in Tron PowerShell, please report it responsibly:

1. **DO NOT** open a public GitHub issue
2. Send an email to the repository owner via GitHub's private vulnerability reporting feature, or create a security advisory at:
   - https://github.com/thookham/tron_PowerShell/security/advisories/new

### What to Include

Please include the following information in your report:
- Description of the vulnerability
- Steps to reproduce the issue
- Potential impact of the vulnerability
- Any suggested fixes or mitigations (if available)
- Your contact information (if you'd like to be credited)

### Response Timeline

- **Initial Response:** We aim to acknowledge receipt of vulnerability reports within 48 hours
- **Status Updates:** You will receive updates on the progress at least every 7 days
- **Resolution:** We will work to validate and fix confirmed vulnerabilities as quickly as possible, typically within 30 days for critical issues

### Disclosure Policy

- We request that you do not publicly disclose the vulnerability until we have released a fix
- Once a fix is released, we will publicly acknowledge the vulnerability and credit the reporter (unless they prefer to remain anonymous)
- If we determine the report is not a security issue, we will explain our reasoning

## Security Update Process

When security updates are released:
1. A new version will be tagged in the repository
2. Release notes will detail the security fixes (without exposing exploitation details)
3. Users will be encouraged to update via GitHub releases and the changelog

## Scope

### In Scope
- Vulnerabilities in Tron PowerShell code (`Tron.ps1`, modules, build scripts)
- Security issues in the configuration system
- Privilege escalation vulnerabilities
- Code injection vulnerabilities
- Unintended data disclosure

### Out of Scope
- Vulnerabilities in third-party tools (please report to the original authors)
- Issues requiring physical access to the machine
- Social engineering attacks
- Malware that already has Administrator access

## Additional Resources

- [Contributing Guidelines](CONTRIBUTING.md)
- [Code of Conduct](CODE_OF_CONDUCT.md)
- [Main README](README.md)

---

**Thank you for helping keep Tron PowerShell and its users safe!**
