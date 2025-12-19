# Calculate coverage by layer from lcov.info file
# This script extracts coverage percentages for different architectural layers
# Usage: .\scripts\windows\testing\calculate_layer_coverage.ps1 [path/to/lcov.info]
#        Or run from project root: .\scripts\windows\testing\calculate_layer_coverage.ps1

param(
    [Parameter(Position=0)]
    [string]$LcovFile = ""
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

# Determine lcov file path
if ([string]::IsNullOrEmpty($LcovFile)) {
    $projectRoot = Find-ProjectRoot
    $LcovFile = Join-Path $projectRoot "coverage/lcov.info"
} elseif (-not [System.IO.Path]::IsPathRooted($LcovFile)) {
    # Relative path - resolve from current directory
    $LcovFile = (Resolve-Path $LcovFile -ErrorAction SilentlyContinue).Path
    if (-not $LcovFile) {
        # Try from project root
        $projectRoot = Find-ProjectRoot
        $LcovFile = Join-Path $projectRoot $LcovFile
    }
}

# Check if lcov file exists
if (-not (Test-Path $LcovFile)) {
    Write-Error "Error: lcov file not found at $LcovFile"
    Write-Host ""
    Write-Host "Please run 'flutter test --coverage' first to generate the coverage file." -ForegroundColor Yellow
    Write-Host "Or specify the path to lcov.info file:" -ForegroundColor Yellow
    Write-Host "  .\scripts\windows\testing\calculate_layer_coverage.ps1 path/to/lcov.info" -ForegroundColor Yellow
    exit 1
}

# Function to calculate coverage for a path pattern
function Calculate-LayerCoverage {
    param(
        [string]$Pattern
    )
    
    $total = 0
    $covered = 0
    $currentFile = ""
    $fileMatches = $false
    
    $content = Get-Content $LcovFile
    
    foreach ($line in $content) {
        if ($line -match '^SF:(.+)$') {
            $currentFile = $matches[1]
            $fileMatches = $currentFile -match $Pattern
        }
        elseif ($line -match '^DA:(\d+),(\d+)$') {
            if ($fileMatches) {
                $total++
                $execCount = [int]$matches[2]
                if ($execCount -gt 0) {
                    $covered++
                }
            }
        }
        elseif ($line -match '^end_of_record$') {
            $currentFile = ""
            $fileMatches = $false
        }
    }
    
    if ($total -gt 0) {
        return [math]::Round(($covered / $total) * 100, 1)
    } else {
        return 0
    }
}

# Calculate coverage for each layer
$domainCov = Calculate-LayerCoverage -Pattern "/features/.*/domain/"
$dataCov = Calculate-LayerCoverage -Pattern "/features/.*/data/"
$presentationCov = Calculate-LayerCoverage -Pattern "/features/.*/presentation/"
$coreCov = Calculate-LayerCoverage -Pattern "/core/"

# Output values with % suffix for display
Write-Host "Output values with % suffix for display"
Write-Host "domain_display=$domainCov%"
Write-Host "data_display=$dataCov%"
Write-Host "presentation_display=$presentationCov%"
Write-Host "core_display=$coreCov%"

# Output numeric values for comparison
Write-Host "Output numeric values for comparison"
Write-Host "domain=$domainCov"
Write-Host "data=$dataCov"
Write-Host "presentation=$presentationCov"
Write-Host "core=$coreCov"

# Print to console for visibility
Write-Host "Summary of coverage by layer"
Write-Host "Domain Layer: ${domainCov}%"
Write-Host "Data Layer: ${dataCov}%"
Write-Host "Presentation Layer: ${presentationCov}%"
Write-Host "Core Layer: ${coreCov}%"
