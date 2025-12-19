# Changelog generation script for Grex
# Usage: .\scripts\windows\maintenance\generate_changelog.ps1 [version]

param(
    [string]$Version = ""
)

$ErrorActionPreference = "Stop"

# Get version from argument or pubspec.yaml
if ([string]::IsNullOrEmpty($Version)) {
    $pubspecContent = Get-Content "pubspec.yaml"
    $versionLine = $pubspecContent | Where-Object { $_ -match '^version:\s*(.+)$' }
    if ($versionLine) {
        $Version = ($versionLine -replace '^version:\s*', '').Split('+')[0]
    } else {
        Write-Error "Could not find version in pubspec.yaml"
        exit 1
    }
}

# Get current date
$Date = Get-Date -Format "yyyy-MM-dd"

# Get last tag
$lastTag = ""
try {
    $lastTag = git describe --tags --abbrev=0 2>$null
} catch {
    # No previous tag
}

# Get commits
$commits = @()
if ([string]::IsNullOrEmpty($lastTag)) {
    Write-Host "Warning: No previous tag found. Using all commits." -ForegroundColor Yellow
    $commits = git log --pretty=format:"%s" --no-merges
} else {
    Write-Host "Generating changelog from $lastTag to HEAD" -ForegroundColor Green
    $commits = git log --pretty=format:"%s" --no-merges "${lastTag}..HEAD"
}

# Initialize changelog sections
$added = @()
$changed = @()
$fixed = @()
$security = @()
$perf = @()
$refactor = @()
$docs = @()
$style = @()
$test = @()
$chore = @()
$ci = @()
$build = @()
$revert = @()

# Parse commits
foreach ($commit in $commits) {
    if ([string]::IsNullOrWhiteSpace($commit)) {
        continue
    }
    
    # Extract type and message
    $parts = $commit -split ':', 2
    if ($parts.Length -lt 2) {
        $changed += $commit
        continue
    }
    
    $typePart = $parts[0].ToLower()
    $type = $typePart -split '\(', 2 | Select-Object -First 1
    $message = $parts[1].Trim()
    
    switch -Wildcard ($type) {
        "feat*" { $added += $message }
        "fix*" { $fixed += $message }
        "security*" { $security += $message }
        "perf*" { $perf += $message }
        "refactor*" { $refactor += $message }
        "docs*" { $docs += $message }
        "style*" { $style += $message }
        "test*" { $test += $message }
        "chore*" { $chore += $message }
        "ci*" { $ci += $message }
        "build*" { $build += $message }
        "revert*" { $revert += $message }
        default { $changed += $message }
    }
}

# Generate changelog entry
$changelogEntry = "## [$Version] - $Date`n`n"

if ($added.Count -gt 0) {
    $changelogEntry += "### Added`n"
    foreach ($item in $added) {
        $changelogEntry += "- $item`n"
    }
    $changelogEntry += "`n"
}

if ($changed.Count -gt 0) {
    $changelogEntry += "### Changed`n"
    foreach ($item in $changed) {
        $changelogEntry += "- $item`n"
    }
    $changelogEntry += "`n"
}

if ($fixed.Count -gt 0) {
    $changelogEntry += "### Fixed`n"
    foreach ($item in $fixed) {
        $changelogEntry += "- $item`n"
    }
    $changelogEntry += "`n"
}

if ($security.Count -gt 0) {
    $changelogEntry += "### Security`n"
    foreach ($item in $security) {
        $changelogEntry += "- $item`n"
    }
    $changelogEntry += "`n"
}

if ($perf.Count -gt 0) {
    $changelogEntry += "### Performance`n"
    foreach ($item in $perf) {
        $changelogEntry += "- $item`n"
    }
    $changelogEntry += "`n"
}

if ($refactor.Count -gt 0) {
    $changelogEntry += "### Refactored`n"
    foreach ($item in $refactor) {
        $changelogEntry += "- $item`n"
    }
    $changelogEntry += "`n"
}

if ($docs.Count -gt 0) {
    $changelogEntry += "### Documentation`n"
    foreach ($item in $docs) {
        $changelogEntry += "- $item`n"
    }
    $changelogEntry += "`n"
}

if ($style.Count -gt 0) {
    $changelogEntry += "### Style`n"
    foreach ($item in $style) {
        $changelogEntry += "- $item`n"
    }
    $changelogEntry += "`n"
}

if ($test.Count -gt 0) {
    $changelogEntry += "### Tests`n"
    foreach ($item in $test) {
        $changelogEntry += "- $item`n"
    }
    $changelogEntry += "`n"
}

if ($chore.Count -gt 0) {
    $changelogEntry += "### Chore`n"
    foreach ($item in $chore) {
        $changelogEntry += "- $item`n"
    }
    $changelogEntry += "`n"
}

if ($ci.Count -gt 0) {
    $changelogEntry += "### CI/CD`n"
    foreach ($item in $ci) {
        $changelogEntry += "- $item`n"
    }
    $changelogEntry += "`n"
}

if ($build.Count -gt 0) {
    $changelogEntry += "### Build`n"
    foreach ($item in $build) {
        $changelogEntry += "- $item`n"
    }
    $changelogEntry += "`n"
}

if ($revert.Count -gt 0) {
    $changelogEntry += "### Reverted`n"
    foreach ($item in $revert) {
        $changelogEntry += "- $item`n"
    }
    $changelogEntry += "`n"
}

# Check if CHANGELOG.md exists
if (-not (Test-Path "CHANGELOG.md")) {
    Write-Host "Creating CHANGELOG.md" -ForegroundColor Yellow
    $header = @"
# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

"@
    Set-Content -Path "CHANGELOG.md" -Value $header
}

# Prepend to CHANGELOG.md
$existingContent = Get-Content "CHANGELOG.md" -Raw
$newContent = $changelogEntry + $existingContent
Set-Content -Path "CHANGELOG.md" -Value $newContent

Write-Host "Changelog generated successfully!" -ForegroundColor Green
Write-Host "  Version: $Version" -ForegroundColor Yellow
Write-Host "  Date: $Date" -ForegroundColor Yellow
Write-Host ""
Write-Host "Review CHANGELOG.md and commit if satisfied."
