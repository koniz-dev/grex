# Monitoring Task Runner
param([string]$Task = "all")

switch ($Task) {
    "health" { 
        & "scripts/database/monitoring/check-health.ps1" 
    }
    "dashboard" { 
        & "scripts/database/monitoring/generate-dashboard.ps1" 
    }
    "all" {
        Write-Host "[INFO] Running all monitoring tasks..." -ForegroundColor Blue
        & "scripts/database/monitoring/check-health.ps1"
        & "scripts/database/monitoring/generate-dashboard.ps1"
        Write-Host "[OK] All tasks completed" -ForegroundColor Green
    }
}