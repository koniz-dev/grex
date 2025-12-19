# Version bumping script for Grex (Windows PowerShell version)
# Usage: .\bump_version.ps1 [major|minor|patch|build] [build_number]

param(
    [Parameter(Position=0)]
    [ValidateSet("major", "minor", "patch", "build")]
    [string]$BumpType = "patch",
    
    [Parameter(Position=1)]
    [int]$CustomBuild
)

$ErrorActionPreference = "Stop"

# Colors for output
function Write-ColorOutput {
    param([string]$Message, [string]$Color = "White")
    Write-Host $Message -ForegroundColor $Color
}

# Get current version from pubspec.yaml
$pubspecContent = Get-Content "pubspec.yaml" -Raw
$versionMatch = [regex]::Match($pubspecContent, '^version:\s*(.+)$', [System.Text.RegularExpressions.RegexOptions]::Multiline)
if (-not $versionMatch.Success) {
    Write-ColorOutput "Error: Could not find version in pubspec.yaml" "Red"
    exit 1
}

$currentVersion = $versionMatch.Groups[1].Value.Trim()
$versionParts = $currentVersion -split '\+'
$versionPart = $versionParts[0]
$buildNumber = if ($versionParts.Length -gt 1) { [int]$versionParts[1] } else { 0 }

# Parse version parts
$versionNumbers = $versionPart -split '\.'
$major = [int]$versionNumbers[0]
$minor = [int]$versionNumbers[1]
$patch = [int]$versionNumbers[2]

# Bump version based on type
switch ($BumpType) {
    "major" {
        $major++
        $minor = 0
        $patch = 0
        $buildNumber++
    }
    "minor" {
        $minor++
        $patch = 0
        $buildNumber++
    }
    "patch" {
        $patch++
        $buildNumber++
    }
    "build" {
        $buildNumber++
    }
}

# Use custom build number if provided
if ($PSBoundParameters.ContainsKey('CustomBuild')) {
    $buildNumber = $CustomBuild
}

# Create new version string
$newVersion = "$major.$minor.$patch+$buildNumber"

# Update pubspec.yaml
$newContent = $pubspecContent -replace '^version:\s*.+$', "version: $newVersion" -replace "`r`n", "`n"
Set-Content -Path "pubspec.yaml" -Value $newContent -NoNewline

# Output result
Write-ColorOutput "Version bumped successfully!" "Green"
Write-ColorOutput "  Old version: $currentVersion" "Yellow"
Write-ColorOutput "  New version: $newVersion" "Yellow"
Write-Host ""
Write-Host "Don't forget to:"
Write-Host "  1. Commit the version change"
Write-Host "  2. Update CHANGELOG.md"
Write-Host "  3. Create a release tag"
