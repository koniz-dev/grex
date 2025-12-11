# Production Deployment Readiness Test
param([string]$Environment = "production")

Write-Host "[TEST] Production Deployment Readiness Test" -ForegroundColor Blue
Write-Host "==========================================="
Write-Host ""

$issues = @()

# Test 1: Check migration files
Write-Host "Test 1: Checking migration files..." -ForegroundColor Blue
$migrationFiles = Get-ChildItem -Path "supabase/migrations" -Filter "*.sql" -ErrorAction SilentlyContinue
if ($migrationFiles.Count -eq 0) {
    $issues += "No migration files found"
    Write-Host "[ERROR] No migration files found" -ForegroundColor Red
} else {
    Write-Host "[OK] Found $($migrationFiles.Count) migration files" -ForegroundColor Green
}

# Test 2: Check backup directory
Write-Host "Test 2: Checking backup directory..." -ForegroundColor Blue
$backupDir = "backups/database"
if (-not (Test-Path $backupDir)) {
    Write-Host "[WARN] Creating backup directory..." -ForegroundColor Yellow
    New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
    Write-Host "[OK] Backup directory created" -ForegroundColor Green
} else {
    Write-Host "[OK] Backup directory exists" -ForegroundColor Green
}

# Test 3: Check for RLS policies in migrations
Write-Host "Test 3: Checking for security policies..." -ForegroundColor Blue
$rlsFound = $false
foreach ($file in $migrationFiles) {
    $content = Get-Content $file.FullName -Raw
    if ($content -match "ENABLE ROW LEVEL SECURITY|CREATE POLICY") {
        $rlsFound = $true
        break
    }
}

if ($rlsFound) {
    Write-Host "[OK] Row Level Security policies found" -ForegroundColor Green
} else {
    $issues += "No RLS policies found"
    Write-Host "[ERROR] No Row Level Security policies found" -ForegroundColor Red
}

# Test 4: Check for audit triggers
Write-Host "Test 4: Checking for audit triggers..." -ForegroundColor Blue
$auditFound = $false
foreach ($file in $migrationFiles) {
    $content = Get-Content $file.FullName -Raw
    if ($content -match "audit.*trigger|CREATE TRIGGER.*audit") {
        $auditFound = $true
        break
    }
}

if ($auditFound) {
    Write-Host "[OK] Audit triggers found" -ForegroundColor Green
} else {
    $issues += "No audit triggers found"
    Write-Host "[ERROR] No audit triggers found" -ForegroundColor Red
}

# Test 5: Check production environment variables (strict)
Write-Host "Test 5: Checking production environment configuration..." -ForegroundColor Blue
if ($env:SUPABASE_PRODUCTION_URL) {
    Write-Host "[OK] SUPABASE_PRODUCTION_URL is configured" -ForegroundColor Green
} else {
    $issues += "SUPABASE_PRODUCTION_URL not configured"
    Write-Host "[ERROR] SUPABASE_PRODUCTION_URL not set" -ForegroundColor Red
}

if ($env:SUPABASE_PRODUCTION_SERVICE_KEY) {
    Write-Host "[OK] SUPABASE_PRODUCTION_SERVICE_KEY is configured" -ForegroundColor Green
} else {
    $issues += "SUPABASE_PRODUCTION_SERVICE_KEY not configured"
    Write-Host "[ERROR] SUPABASE_PRODUCTION_SERVICE_KEY not set" -ForegroundColor Red
}

# Generate report
$reportPath = "production_readiness_test_report_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
$reportContent = @"
Production Deployment Readiness Test Report
Date: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
Environment: $Environment

Test Results:
- Migration files: $($migrationFiles.Count) found
- Backup directory: $(if (Test-Path $backupDir) { "Exists" } else { "Created" })
- RLS policies: $(if ($rlsFound) { "Found" } else { "Not found" })
- Audit triggers: $(if ($auditFound) { "Found" } else { "Not found" })
- Environment vars: $(if ($env:SUPABASE_PRODUCTION_URL -and $env:SUPABASE_PRODUCTION_SERVICE_KEY) { "Configured" } else { "Missing" })

Issues found: $($issues.Count)
$(if ($issues.Count -gt 0) { $issues | ForEach-Object { "- $_" } | Out-String } else { "No issues found" })

Status: $(if ($issues.Count -eq 0) { "READY FOR PRODUCTION DEPLOYMENT" } else { "ISSUES MUST BE RESOLVED" })
"@

$reportContent | Out-File -FilePath $reportPath -Encoding UTF8

# Summary
Write-Host ""
Write-Host "Test Summary:" -ForegroundColor Blue
Write-Host "=============" -ForegroundColor Blue

if ($issues.Count -eq 0) {
    Write-Host "[SUCCESS] All tests passed! Production deployment is ready." -ForegroundColor Green
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Green
    Write-Host "1. Run: .\scripts\database\test\simulate-production.ps1"
    Write-Host "2. Run: .\scripts\database\deploy\production.ps1 -DryRun"
    Write-Host "3. If dry run succeeds, run actual deployment"
} else {
    Write-Host "[ERROR] Found $($issues.Count) issues:" -ForegroundColor Red
    foreach ($issue in $issues) {
        Write-Host "  - $issue" -ForegroundColor Red
    }
    Write-Host ""
    Write-Host "Fix all issues before deployment!" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Report saved: $reportPath" -ForegroundColor Cyan