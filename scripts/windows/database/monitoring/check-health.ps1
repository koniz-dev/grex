# Database Health Check
param([string]$Environment = "production")

Write-Host "[INFO] Running health check for $Environment..." -ForegroundColor Blue

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$logFile = Join-Path $scriptDir "alerts/health.log"

try {
    supabase db test --linked
    if ($LASTEXITCODE -eq 0) {
        Write-Host "[OK] Database health check passed" -ForegroundColor Green
        "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - Health check PASSED" | Out-File -FilePath $logFile -Append
    } else {
        Write-Host "[ERROR] Database health check failed" -ForegroundColor Red
        "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - Health check FAILED" | Out-File -FilePath $logFile -Append
    }
} catch {
    Write-Host "[ERROR] Health check error: $_" -ForegroundColor Red
}