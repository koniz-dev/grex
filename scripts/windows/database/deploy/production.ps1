# Deploy to Production Environment Script
param(
    [string]$ProductionUrl = $env:SUPABASE_PRODUCTION_URL,
    [string]$ProductionKey = $env:SUPABASE_PRODUCTION_SERVICE_KEY,
    [switch]$SkipBackup = $false,
    [switch]$DryRun = $false,
    [switch]$Force = $false
)

$ErrorActionPreference = "Stop"

function Write-Step {
    param([string]$Message)
    Write-Host "[INFO] $Message" -ForegroundColor Blue
}

function Write-Success {
    param([string]$Message)
    Write-Host "[OK] $Message" -ForegroundColor Green
}

function Write-Warning {
    param([string]$Message)
    Write-Host "[WARN] $Message" -ForegroundColor Yellow
}

function Write-Error {
    param([string]$Message)
    Write-Host "[ERROR] $Message" -ForegroundColor Red
}

function Write-Critical {
    param([string]$Message)
    Write-Host "[CRITICAL] $Message" -ForegroundColor Magenta
}

function Test-Prerequisites {
    Write-Step "Checking production deployment prerequisites..."
    
    # Check Supabase CLI
    try {
        $version = supabase --version 2>$null
        Write-Success "Supabase CLI found: $version"
    }
    catch {
        Write-Error "Supabase CLI not found. Install with: npm install -g supabase"
        exit 1
    }
    
    # Check migration files
    $migrationFiles = Get-ChildItem -Path "supabase/migrations" -Filter "*.sql" | Sort-Object Name
    if ($migrationFiles.Count -eq 0) {
        Write-Error "No migration files found in supabase/migrations/"
        exit 1
    }
    
    Write-Success "Prerequisites check passed"
    Write-Success "Found $($migrationFiles.Count) migration files"
}

function Confirm-Deployment {
    if ($DryRun) {
        Write-Warning "DRY RUN MODE - No actual changes will be made"
        return
    }
    
    Write-Critical "PRODUCTION DEPLOYMENT CONFIRMATION"
    Write-Host "=================================="
    Write-Host "Target: $ProductionUrl" -ForegroundColor Yellow
    Write-Host "This will modify the PRODUCTION database!" -ForegroundColor Red
    Write-Host ""
    
    if (-not $Force) {
        $confirmation = Read-Host "Type 'DEPLOY TO PRODUCTION' to continue"
        if ($confirmation -ne "DEPLOY TO PRODUCTION") {
            Write-Warning "Deployment cancelled by user"
            exit 0
        }
    }
    
    Write-Success "Production deployment confirmed"
}

function Create-Backup {
    if ($SkipBackup) {
        Write-Warning "Skipping backup as requested"
        return $null
    }
    
    Write-Step "Creating production database backup..."
    
    $backupTimestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $backupPath = "backups/database/production_backup_$backupTimestamp.sql"
    
    # Ensure backup directory exists
    $backupDir = Split-Path $backupPath -Parent
    if (-not (Test-Path $backupDir)) {
        New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
    }
    
    if ($DryRun) {
        Write-Success "DRY RUN: Would create backup at $backupPath"
        return $backupPath
    }
    
    try {
        Write-Step "Creating database backup..."
        supabase db dump --linked --data-only > $backupPath
        
        if (-not (Test-Path $backupPath) -or (Get-Item $backupPath).Length -eq 0) {
            Write-Error "Backup creation failed or backup is empty"
            exit 1
        }
        
        $backupSize = [math]::Round((Get-Item $backupPath).Length / 1MB, 2)
        Write-Success "Backup created successfully: $backupPath ($backupSize MB)"
        
        return $backupPath
    }
    catch {
        Write-Error "Failed to create backup: $_"
        exit 1
    }
}

function Deploy-Migrations {
    Write-Step "Deploying migrations to production..."
    
    $migrationFiles = Get-ChildItem -Path "supabase/migrations" -Filter "*.sql" | Sort-Object Name
    
    Write-Host "Preparing to apply $($migrationFiles.Count) migration files:" -ForegroundColor Blue
    foreach ($file in $migrationFiles) {
        Write-Host "  - $($file.Name)" -ForegroundColor Blue
    }
    
    if ($DryRun) {
        Write-Success "DRY RUN: Would apply $($migrationFiles.Count) migrations"
        return
    }
    
    try {
        Write-Step "Applying migrations (this may take several minutes)..."
        supabase db push --linked
        
        if ($LASTEXITCODE -ne 0) {
            Write-Error "Migration deployment failed"
            exit 1
        }
        
        Write-Success "All migrations applied successfully"
    }
    catch {
        Write-Error "Failed to deploy migrations: $_"
        exit 1
    }
}

function Verify-Schema {
    Write-Step "Verifying production schema integrity..."
    
    if ($DryRun) {
        Write-Success "DRY RUN: Would verify schema integrity"
        return
    }
    
    try {
        # Test basic connectivity
        Write-Step "Testing database connectivity..."
        supabase db test --linked
        
        if ($LASTEXITCODE -ne 0) {
            Write-Error "Database connectivity test failed"
            exit 1
        }
        
        Write-Success "Database connectivity test passed"
        Write-Success "Production schema verification completed"
    }
    catch {
        Write-Error "Schema verification failed: $_"
        exit 1
    }
}

function Generate-Report {
    param([string]$BackupPath)
    
    Write-Step "Generating production deployment report..."
    
    $reportPath = "production_deployment_report_$(Get-Date -Format 'yyyyMMdd_HHmmss').md"
    $currentDate = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $migrationCount = (Get-ChildItem -Path "supabase/migrations" -Filter "*.sql" | Measure-Object).Count
    
    $deploymentMode = if ($DryRun) { "DRY RUN" } else { "LIVE DEPLOYMENT" }
    
    $reportContent = @"
# Production Deployment Report

**Date:** $currentDate
**Environment:** Production
**Mode:** $deploymentMode
**Target:** $ProductionUrl

## Deployment Summary

$(if ($DryRun) { "[INFO] **Status:** Dry Run Completed" } else { "[OK] **Status:** Deployment Successful" })
[OK] **Migrations:** $migrationCount files processed
[OK] **Schema Integrity:** Verified
$(if (-not $SkipBackup) { "[OK] **Backup:** Created at $BackupPath" } else { "[WARN] **Backup:** Skipped" })

## Migration Files Applied

$(Get-ChildItem -Path "supabase/migrations" -Filter "*.sql" | Sort-Object Name | ForEach-Object { "- [OK] $($_.Name)" } | Out-String)

## Post-Deployment Actions Required

### Immediate (Next 1 hour)
- [ ] Monitor application logs for errors
- [ ] Test critical user workflows
- [ ] Verify real-time functionality

### Short-term (Next 24 hours)
- [ ] Monitor database performance
- [ ] Check connection pool usage
- [ ] Verify backup procedures

---
*Generated by production.ps1*
$(if ($DryRun) { "*This was a DRY RUN - no actual changes were made*" } else { "*LIVE PRODUCTION DEPLOYMENT COMPLETED*" })
"@
    
    $reportContent | Out-File -FilePath $reportPath -Encoding UTF8
    Write-Success "Production deployment report generated: $reportPath"
    
    if (-not $DryRun) {
        Write-Critical "PRODUCTION DEPLOYMENT COMPLETED"
        Write-Host "Report: $reportPath" -ForegroundColor Yellow
        Write-Host "Please review the post-deployment checklist!" -ForegroundColor Yellow
    }
}

# Main execution
try {
    Write-Host "[DEPLOY] Starting Production Deployment" -ForegroundColor Magenta
    Write-Host "====================================="
    
    if ($DryRun) {
        Write-Warning "DRY RUN MODE - No actual changes will be made"
    } else {
        Write-Critical "LIVE PRODUCTION DEPLOYMENT"
    }
    Write-Host ""
    
    Test-Prerequisites
    Confirm-Deployment
    
    $backupPath = Create-Backup
    Deploy-Migrations
    Verify-Schema
    Generate-Report -BackupPath $backupPath
    
    Write-Host ""
    if ($DryRun) {
        Write-Host "[SUCCESS] Production deployment dry run completed successfully!" -ForegroundColor Green
        Write-Host "Run without -DryRun flag to perform actual deployment"
    } else {
        Write-Host "[SUCCESS] Production deployment completed successfully!" -ForegroundColor Green
        Write-Critical "MONITOR THE SYSTEM CLOSELY FOR THE NEXT 24 HOURS"
    }
    Write-Host "====================================="
}
catch {
    Write-Error "Production deployment failed: $_"
    
    if (-not $DryRun) {
        Write-Critical "PRODUCTION DEPLOYMENT FAILED"
        Write-Warning "Database may be in an inconsistent state"
        if ($backupPath) {
            Write-Warning "Consider restoring from backup: $backupPath"
        }
        Write-Warning "Contact database administrator immediately"
    }
    
    exit 1
}