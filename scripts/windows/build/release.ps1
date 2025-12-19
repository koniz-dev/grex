# Release automation script for Grex (Windows PowerShell version)
# Usage: .\release.ps1 [major|minor|patch]

param(
    [Parameter(Position=0)]
    [ValidateSet("major", "minor", "patch")]
    [string]$BumpType = "patch"
)

$ErrorActionPreference = "Stop"

# Colors for output
function Write-ColorOutput {
    param([string]$Message, [string]$Color = "White")
    Write-Host $Message -ForegroundColor $Color
}

# Check if we're on main branch
$currentBranch = git rev-parse --abbrev-ref HEAD
if ($currentBranch -ne "main" -and $currentBranch -ne "master") {
    Write-ColorOutput "Error: Must be on main/master branch to release" "Red"
    exit 1
}

# Check for uncommitted changes
$status = git status --porcelain
if ($status) {
    Write-ColorOutput "Error: Uncommitted changes detected" "Red"
    Write-Host "Please commit or stash your changes before releasing"
    exit 1
}

Write-ColorOutput "Starting release process..." "Cyan"
Write-Host ""

# Step 1: Run tests
Write-ColorOutput "Step 1: Running tests..." "Yellow"
flutter test
if ($LASTEXITCODE -ne 0) {
    Write-ColorOutput "Tests failed. Aborting release." "Red"
    exit 1
}
Write-ColorOutput "[OK] Tests passed" "Green"
Write-Host ""

# Step 2: Run analysis
Write-ColorOutput "Step 2: Running analysis..." "Yellow"
flutter analyze
if ($LASTEXITCODE -ne 0) {
    Write-ColorOutput "Analysis failed. Aborting release." "Red"
    exit 1
}
Write-ColorOutput "[OK] Analysis passed" "Green"
Write-Host ""

# Step 3: Bump version
Write-ColorOutput "Step 3: Bumping version..." "Yellow"
$scriptPath = Join-Path $PSScriptRoot "..\development\bump_version.ps1"
& $scriptPath $BumpType

$pubspecContent = Get-Content "pubspec.yaml" -Raw
$versionMatch = [regex]::Match($pubspecContent, '^version:\s*(.+)$', [System.Text.RegularExpressions.RegexOptions]::Multiline)
$newVersion = ($versionMatch.Groups[1].Value.Trim() -split '\+')[0]
Write-ColorOutput "[OK] Version bumped to $newVersion" "Green"
Write-Host ""

# Step 4: Generate changelog
Write-ColorOutput "Step 4: Generating changelog..." "Yellow"
$changelogScript = Join-Path $PSScriptRoot "..\maintenance\generate_changelog.ps1"
& $changelogScript $newVersion
Write-ColorOutput "[OK] Changelog generated" "Green"
Write-Host ""

# Step 5: Create release branch
$releaseBranch = "release/v$newVersion"
Write-ColorOutput "Step 5: Creating release branch..." "Yellow"
git checkout -b $releaseBranch
Write-ColorOutput "[OK] Release branch created: $releaseBranch" "Green"
Write-Host ""

# Step 6: Commit changes
Write-ColorOutput "Step 6: Committing changes..." "Yellow"
git add pubspec.yaml CHANGELOG.md
git commit -m "chore: prepare release v$newVersion"
Write-ColorOutput "[OK] Changes committed" "Green"
Write-Host ""

# Step 7: Create tag
Write-ColorOutput "Step 7: Creating release tag..." "Yellow"
git tag -a "v$newVersion" -m "Release v$newVersion"
Write-ColorOutput "[OK] Tag created: v$newVersion" "Green"
Write-Host ""

# Step 8: Push
Write-ColorOutput "Step 8: Pushing to remote..." "Yellow"
$response = Read-Host "Push release branch and tag? (y/n)"
if ($response -eq "y" -or $response -eq "Y") {
    git push origin $releaseBranch
    git push origin "v$newVersion"
    Write-ColorOutput "[OK] Pushed to remote" "Green"
} else {
    Write-ColorOutput "[!] Skipped push. Push manually with:" "Yellow"
    Write-Host "  git push origin $releaseBranch"
    Write-Host "  git push origin v$newVersion"
}
Write-Host ""

# Summary
Write-ColorOutput "Release preparation complete!" "Green"
Write-Host ""
Write-Host "Next steps:"
Write-Host "  1. CI/CD will automatically build and deploy"
Write-Host "  2. Monitor GitHub Actions for build status"
Write-Host "  3. After successful deployment, merge release branch:"
Write-Host "     git checkout main"
Write-Host "     git merge $releaseBranch"
Write-Host "     git push origin main"
Write-Host ""
Write-ColorOutput "Release: v$newVersion" "Cyan"
