# Performance Dashboard Generator
Write-Host "[INFO] Generating performance dashboard..." -ForegroundColor Blue

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$reportsDir = Join-Path $scriptDir "reports"
$timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
$reportPath = Join-Path $reportsDir "dashboard_$(Get-Date -Format 'yyyyMMdd_HHmmss').html"

# Ensure reports directory exists
if (-not (Test-Path $reportsDir)) {
    New-Item -ItemType Directory -Path $reportsDir -Force | Out-Null
}

$htmlContent = @"
<!DOCTYPE html>
<html>
<head>
    <title>Database Dashboard - Production</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        .metric { background: #f5f5f5; padding: 15px; margin: 10px 0; border-radius: 5px; }
        .good { border-left: 5px solid #4CAF50; }
        h1 { color: #333; }
    </style>
</head>
<body>
    <h1>Database Performance Dashboard</h1>
    <p><strong>Environment:</strong> Production</p>
    <p><strong>Generated:</strong> $timestamp</p>
    
    <div class="metric good">
        <h3>System Status</h3>
        <p>Monitoring: Active</p>
        <p>Health Check: Available</p>
    </div>
    
    <div class="metric good">
        <h3>Available Queries</h3>
        <p>Slow Queries: windows/database/monitoring/queries/slow_queries.sql</p>
        <p>Connections: windows/database/monitoring/queries/connections.sql</p>
        <p>Table Sizes: windows/database/monitoring/queries/table_sizes.sql</p>
    </div>
</body>
</html>
"@

$htmlContent | Out-File -FilePath $reportPath -Encoding UTF8
Write-Host "[OK] Dashboard generated: $reportPath" -ForegroundColor Green