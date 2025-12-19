# Monitoring Task Runner
param([string]$Task = "all")

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$healthScript = Join-Path $scriptDir "check-health.ps1"
$dashboardScript = Join-Path $scriptDir "generate-dashboard.ps1"

switch ($Task) {
    "health" { 
        & $healthScript
    }
    "dashboard" { 
        & $dashboardScript
    }
    "all" {
        Write-Host "[INFO] Running all monitoring tasks..." -ForegroundColor Blue
        & $healthScript
        & $dashboardScript
        Write-Host "[OK] All tasks completed" -ForegroundColor Green
    }
}