# Test coverage script for Windows
# Usage: .\scripts\windows\testing\test_coverage.ps1 [-Html] [-Open] [-Min <percent>] [-Exclude <path>] [-Analyze] [-NoTest]
#        Run from project root directory

param(
    [switch]$Html,
    [switch]$Open,
    [int]$Min = 80,
    [string[]]$Exclude = @(),
    [switch]$Analyze,
    [switch]$NoTest
)

$ErrorActionPreference = "Stop"

# Find project root (directory containing pubspec.yaml)
function Find-ProjectRoot {
    $currentDir = Get-Location
    $dir = $currentDir
    
    while ($dir -ne $null -and $dir.Path -ne $dir.Drive.Root) {
        if (Test-Path (Join-Path $dir.Path "pubspec.yaml")) {
            return $dir.Path
        }
        $dir = Split-Path $dir.Path -Parent
    }
    
    return $currentDir.Path
}

# Change to project root
$projectRoot = Find-ProjectRoot
if ((Get-Location).Path -ne $projectRoot) {
    Write-Host "Changing to project root: $projectRoot" -ForegroundColor Yellow
    Set-Location $projectRoot
}

# Colors for output
function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$Color = "White"
    )
    Write-Host $Message -ForegroundColor $Color
}

# Run tests with coverage (unless skipped)
if (-not $NoTest) {
    Write-ColorOutput "Running tests with coverage..." "Cyan"
    Write-Host ""
    flutter test --coverage
} else {
    Write-ColorOutput "Skipping tests (using existing coverage data)" "Yellow"
    Write-Host ""
}

# Check if lcov.info exists
if (-not (Test-Path "coverage/lcov.info")) {
    Write-ColorOutput "Error: coverage/lcov.info not found" "Red"
    exit 1
}

Write-ColorOutput "[OK] Tests completed" "Green"
Write-Host ""

# Generate HTML report if requested
if ($Html -or $Open) {
    Write-ColorOutput "Generating HTML coverage report..." "Yellow"
    
    # Check if genhtml is available (via WSL or Git Bash)
    $genhtmlAvailable = $false
    $genhtmlCommand = ""
    
    if (Get-Command wsl -ErrorAction SilentlyContinue) {
        # Try to use genhtml via WSL
        $wslTest = wsl which genhtml 2>$null
        if ($LASTEXITCODE -eq 0) {
            $genhtmlAvailable = $true
            $genhtmlCommand = "wsl"
        }
    }
    
    if (-not $genhtmlAvailable -and (Get-Command bash -ErrorAction SilentlyContinue)) {
        # Try Git Bash
        $bashTest = bash -c "which genhtml" 2>$null
        if ($LASTEXITCODE -eq 0) {
            $genhtmlAvailable = $true
            $genhtmlCommand = "bash"
        }
    }
    
    if ($genhtmlAvailable) {
        # Create HTML report directory
        if (-not (Test-Path "coverage/html")) {
            New-Item -ItemType Directory -Path "coverage/html" -Force | Out-Null
        }
        
        # Generate HTML report
        if ($genhtmlCommand -eq "wsl") {
            $wslPath = (Resolve-Path "coverage/lcov.info").Path -replace '^([A-Z]):\\', '/mnt/$1/' -replace '\\', '/' | ForEach-Object { $_.ToLower() }
            $wslOutPath = (Resolve-Path "coverage/html").Path -replace '^([A-Z]):\\', '/mnt/$1/' -replace '\\', '/' | ForEach-Object { $_.ToLower() }
            wsl genhtml "$wslPath" -o "$wslOutPath" --no-function-coverage
        } else {
            bash -c "genhtml coverage/lcov.info -o coverage/html --no-function-coverage"
        }
        
        Write-ColorOutput "[OK] HTML report generated at coverage/html/index.html" "Green"
        Write-Host ""
        
        # Open HTML report if requested
        if ($Open) {
            Start-Process "coverage/html/index.html"
        }
    } else {
        Write-ColorOutput "Warning: genhtml not found. Install lcov to generate HTML reports." "Yellow"
        Write-Host ""
    }
}

# Calculate coverage percentage
Write-ColorOutput "Calculating coverage..." "Yellow"

function Calculate-Coverage {
    $totalLines = 0
    $coveredLines = 0
    
    $content = Get-Content "coverage/lcov.info"
    foreach ($line in $content) {
        if ($line -match '^DA:\d+,(\d+)$') {
            $totalLines++
            $execCount = [int]$matches[1]
            if ($execCount -gt 0) {
                $coveredLines++
            }
        }
    }
    
    if ($totalLines -gt 0) {
        $percent = [math]::Round(($coveredLines / $totalLines) * 100, 2)
        return @{
            Percent = $percent
            Total = $totalLines
            Covered = $coveredLines
        }
    } else {
        return @{
            Percent = 0
            Total = 0
            Covered = 0
        }
    }
}

# Try to use lcov command if available (more accurate)
$coverage = $null
if (Get-Command wsl -ErrorAction SilentlyContinue) {
    $lcovSummary = wsl lcov --summary coverage/lcov.info 2>&1 | Select-String "lines.*:" | Select-Object -First 1
    if ($lcovSummary) {
        if ($lcovSummary -match '(\d+\.\d+)%') {
            $coverage = @{
                Percent = [double]$matches[1]
                Total = 0
                Covered = 0
            }
        }
    }
}

# If lcov parsing failed, use direct calculation
if (-not $coverage) {
    $coverage = Calculate-Coverage
}

# Display coverage statistics
if ($coverage.Total -gt 0) {
    Write-ColorOutput "Coverage Statistics:" "Cyan"
    Write-Host "  Total lines: $($coverage.Total)"
    Write-Host "  Covered lines: $($coverage.Covered)"
    Write-Host "  Coverage: $($coverage.Percent)%"
    Write-Host ""
} else {
    Write-ColorOutput "Coverage: $($coverage.Percent)%" "Cyan"
    Write-Host ""
}

# Analyze coverage by layer if requested
if ($Analyze) {
    Write-Host ""
    Write-ColorOutput "=== Coverage Analysis by Layer ===" "Cyan"
    Write-Host ""
    
    # Use calculate_layer_coverage script
    $layerScript = Join-Path $PSScriptRoot "calculate_layer_coverage.ps1"
    if (Test-Path $layerScript) {
        $lcovPath = Join-Path $projectRoot "coverage/lcov.info"
        & $layerScript $lcovPath
    } else {
        Write-ColorOutput "Warning: calculate_layer_coverage.ps1 not found" "Yellow"
    }
    Write-Host ""
}

# Check against minimum threshold
$exitCode = 0
if ($coverage.Percent -lt $Min) {
    Write-ColorOutput "[FAIL] Coverage $($coverage.Percent)% is below minimum threshold of ${Min}%" "Red"
    $exitCode = 1
} else {
    Write-ColorOutput "[OK] Coverage $($coverage.Percent)% meets minimum threshold of ${Min}%" "Green"
}

Write-Host ""
Write-ColorOutput "Coverage report complete!" "Green"

exit $exitCode
