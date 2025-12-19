# Migration Management Script for Grex Database
# This script provides comprehensive utilities for managing database migrations

<#
.SYNOPSIS
    Manages database migrations for the Grex expense splitting application

.DESCRIPTION
    This script provides utilities for applying, rolling back, and validating database migrations.
    It supports multiple environments and includes comprehensive error handling and logging.

.PARAMETER Action
    The action to perform: apply, status, validate, rollback, verify, create

.PARAMETER Environment
    Target environment: development, staging, production

.PARAMETER MigrationName
    Name for new migration (used with 'create' action)

.PARAMETER DryRun
    Perform a dry run without making actual changes

.PARAMETER Force
    Force operation without confirmation prompts

.EXAMPLE
    .\manage-migrations.ps1 -Action apply -Environment development
    Apply all pending migrations to development environment

.EXAMPLE
    .\manage-migrations.ps1 -Action create -MigrationName "add_expense_categories"
    Create a new migration file

.EXAMPLE
    .\manage-migrations.ps1 -Action rollback -Environment staging -Force
    Rollback last migration in staging without confirmation

.NOTES
    Author: Grex Development Team
    Date: 2024-01-15
    Version: 2.0
    Requires: PowerShell 7+, Supabase CLI, PostgreSQL client tools
#>

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("apply", "status", "validate", "rollback", "verify", "create")]
    [string]$Action,
    
    [Parameter(Mandatory=$false)]
    [ValidateSet("development", "staging", "production")]
    [string]$Environment = "development",
    
    [Parameter(Mandatory=$false)]
    [string]$MigrationName,
    
    [Parameter(Mandatory=$false)]
    [switch]$DryRun,
    
    [Parameter(Mandatory=$false)]
    [switch]$Force
)

# Configuration
$script:LogFile = "logs/migration-$(Get-Date -Format 'yyyyMMdd').log"
$script:BackupDir = "backups/migrations"
$script:MigrationsDir = "supabase/migrations"

# Ensure log directory exists
$logDir = Split-Path $script:LogFile -Parent
if (!(Test-Path $logDir)) {
    New-Item -ItemType Directory -Path $logDir -Force | Out-Null
}

# Logging function
function Write-Log {
    param(
        [string]$Message,
        [string]$Level = "INFO",
        [string]$Color = "White"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] $Message"
    
    # Write to console with color
    Write-Host $logMessage -ForegroundColor $Color
    
    # Write to log file
    Add-Content -Path $script:LogFile -Value $logMessage
}

# Error handling function
function Write-Error-Log {
    param([string]$Message, [System.Management.Automation.ErrorRecord]$ErrorRecord)
    
    Write-Log "ERROR: $Message" "ERROR" "Red"
    if ($ErrorRecord) {
        Write-Log "Exception: $($ErrorRecord.Exception.Message)" "ERROR" "Red"
        Write-Log "Stack Trace: $($ErrorRecord.ScriptStackTrace)" "ERROR" "Red"
    }
}

# Get database connection string based on environment
function Get-DatabaseUrl {
    param([string]$Env)
    
    switch ($Env) {
        "development" { 
            return $env:DATABASE_URL_DEV ?? "postgresql://postgres:postgres@127.0.0.1:54322/postgres"
        }
        "staging" { 
            return $env:DATABASE_URL_STAGING ?? $env:DATABASE_URL
        }
        "production" { 
            return $env:DATABASE_URL_PROD ?? $env:DATABASE_URL
        }
        default { 
            throw "Invalid environment: $Env"
        }
    }
}

# Execute SQL query with error handling
function Invoke-SqlQuery {
    param(
        [string]$Query,
        [string]$DbUrl,
        [switch]$ReturnResult
    )
    
    try {
        Write-Log "Executing SQL query..." "DEBUG"
        
        if ($DryRun) {
            Write-Log "DRY RUN: Would execute query: $($Query.Substring(0, [Math]::Min(100, $Query.Length)))..." "INFO" "Yellow"
            return "DRY_RUN_SUCCESS"
        }
        
        if ($ReturnResult) {
            $result = psql $DbUrl -c $Query -t -A
            return $result
        } else {
            psql $DbUrl -c $Query | Out-Null
            return "SUCCESS"
        }
    }
    catch {
        Write-Error-Log "Failed to execute SQL query" $_
        throw
    }
}

# Create backup before major operations
function New-MigrationBackup {
    param([string]$DbUrl)
    
    if ($DryRun) {
        Write-Log "DRY RUN: Would create backup" "INFO" "Yellow"
        return
    }
    
    try {
        # Ensure backup directory exists
        if (!(Test-Path $script:BackupDir)) {
            New-Item -ItemType Directory -Path $script:BackupDir -Force | Out-Null
        }
        
        $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
        $backupFile = "$script:BackupDir/backup_${Environment}_${timestamp}.sql"
        
        Write-Log "Creating backup: $backupFile" "INFO" "Yellow"
        
        # Extract connection components for pg_dump
        if ($DbUrl -match "postgresql://([^:]+):([^@]+)@([^:]+):(\d+)/(.+)") {
            $user = $matches[1]
            $password = $matches[2]
            $host = $matches[3]
            $port = $matches[4]
            $database = $matches[5]
            
            $env:PGPASSWORD = $password
            pg_dump -h $host -p $port -U $user -d $database -f $backupFile
            
            Write-Log "Backup created successfully: $backupFile" "INFO" "Green"
        } else {
            throw "Invalid database URL format"
        }
    }
    catch {
        Write-Error-Log "Failed to create backup" $_
        throw
    }
}

# Get migration status
function Get-MigrationStatus {
    param([string]$DbUrl)
    
    Write-Log "=== Migration Status ===" "INFO" "Green"
    
    try {
        $query = "SELECT migration_name, version, applied_at, success FROM get_migration_status() ORDER BY version;"
        $result = Invoke-SqlQuery -Query $query -DbUrl $DbUrl -ReturnResult
        
        if ($result -and $result -ne "DRY_RUN_SUCCESS") {
            Write-Log "Applied Migrations:" "INFO" "Yellow"
            $result | ForEach-Object {
                $parts = $_ -split '\|'
                if ($parts.Length -ge 4) {
                    $name = $parts[0]
                    $version = $parts[1]
                    $applied = $parts[2]
                    $success = $parts[3]
                    
                    $status = if ($success -eq 't') { "[OK]" } else { "[FAIL]" }
                    $color = if ($success -eq 't') { "Green" } else { "Red" }
                    Write-Log "  $status $version - $name ($applied)" "INFO" $color
                }
            }
        } else {
            Write-Log "No migrations found or error occurred" "WARN" "Yellow"
        }
        
        # Show pending migrations
        $pendingMigrations = Get-PendingMigrations
        if ($pendingMigrations.Count -gt 0) {
            Write-Log "Pending Migrations:" "INFO" "Yellow"
            $pendingMigrations | ForEach-Object {
                Write-Log "  [PENDING] $($_.Name)" "INFO" "Cyan"
            }
        } else {
            Write-Log "No pending migrations" "INFO" "Green"
        }
    }
    catch {
        Write-Error-Log "Failed to get migration status" $_
        throw
    }
}

# Get pending migrations
function Get-PendingMigrations {
    try {
        $migrationFiles = Get-ChildItem -Path $script:MigrationsDir -Filter "*.sql" | Sort-Object Name
        
        # For now, return all migration files (in production, compare with applied migrations)
        return $migrationFiles
    }
    catch {
        Write-Error-Log "Failed to get pending migrations" $_
        return @()
    }
}

# Apply pending migrations
function Invoke-MigrationApply {
    param([string]$DbUrl)
    
    Write-Log "=== Applying Migrations ===" "INFO" "Green"
    
    try {
        $pendingMigrations = Get-PendingMigrations
        
        if ($pendingMigrations.Count -eq 0) {
            Write-Log "No pending migrations to apply" "INFO" "Green"
            return
        }
        
        # Create backup before applying migrations
        if (!$DryRun -and $Environment -ne "development") {
            New-MigrationBackup -DbUrl $DbUrl
        }
        
        foreach ($migration in $pendingMigrations) {
            Write-Log "Applying migration: $($migration.Name)" "INFO" "Yellow"
            
            if (!$DryRun) {
                $migrationContent = Get-Content -Path $migration.FullName -Raw
                Invoke-SqlQuery -Query $migrationContent -DbUrl $DbUrl
            }
            
            Write-Log "Migration applied successfully: $($migration.Name)" "INFO" "Green"
        }
        
        Write-Log "All migrations applied successfully" "INFO" "Green"
    }
    catch {
        Write-Error-Log "Failed to apply migrations" $_
        throw
    }
}

# Validate migration order and integrity
function Test-MigrationOrder {
    Write-Log "=== Migration Order Validation ===" "INFO" "Green"
    
    try {
        $migrationFiles = Get-ChildItem -Path $script:MigrationsDir -Filter "*.sql" | Sort-Object Name
        
        $expectedVersion = 1
        $valid = $true
        
        foreach ($file in $migrationFiles) {
            if ($file.Name -match '^(\d{5})_') {
                $fileVersion = [int]$matches[1]
                
                if ($fileVersion -ne $expectedVersion) {
                    Write-Log "Gap in migration sequence: Expected $($expectedVersion.ToString('00000')), found $($fileVersion.ToString('00000'))" "ERROR" "Red"
                    $valid = $false
                } else {
                    Write-Log "[OK] $($file.Name)" "INFO" "Green"
                }
                
                $expectedVersion = $fileVersion + 1
            } else {
                Write-Log "Invalid migration filename format: $($file.Name)" "ERROR" "Red"
                $valid = $false
            }
        }
        
        if ($valid) {
            Write-Log "Migration sequence is valid" "INFO" "Green"
        } else {
            Write-Log "Migration sequence has issues" "ERROR" "Red"
            throw "Migration validation failed"
        }
        
        return $valid
    }
    catch {
        Write-Error-Log "Failed to validate migration order" $_
        throw
    }
}

# Verify schema integrity
function Test-SchemaIntegrity {
    param([string]$DbUrl)
    
    Write-Log "=== Schema Integrity Verification ===" "INFO" "Green"
    
    try {
        $query = "SELECT check_name, status, details FROM verify_schema_integrity();"
        $result = Invoke-SqlQuery -Query $query -DbUrl $DbUrl -ReturnResult
        
        if ($result -and $result -ne "DRY_RUN_SUCCESS") {
            $allPassed = $true
            $result | ForEach-Object {
                $parts = $_ -split '\|'
                if ($parts.Length -ge 3) {
                    $checkName = $parts[0]
                    $status = $parts[1]
                    $details = $parts[2]
                    
                    $symbol = if ($status -eq "PASS") { "[PASS]" } else { "[FAIL]" }
                    $color = if ($status -eq "PASS") { "Green" } else { "Red" }
                    
                    Write-Log "$symbol $checkName - $details" "INFO" $color
                    
                    if ($status -ne "PASS") {
                        $allPassed = $false
                    }
                }
            }
            
            if (!$allPassed) {
                throw "Schema integrity verification failed"
            }
        } else {
            Write-Log "Schema integrity verification completed (or dry run)" "INFO" "Green"
        }
    }
    catch {
        Write-Error-Log "Failed to verify schema integrity" $_
        throw
    }
}

# Rollback last migration
function Invoke-MigrationRollback {
    param([string]$DbUrl)
    
    Write-Log "=== Migration Rollback ===" "INFO" "Yellow"
    
    if (!$Force) {
        Write-Log "WARNING: This will rollback the last applied migration!" "WARN" "Red"
        $confirmation = Read-Host "Are you sure you want to proceed? (yes/no)"
        
        if ($confirmation -ne "yes") {
            Write-Log "Rollback cancelled" "INFO" "Yellow"
            return
        }
    }
    
    try {
        # Create backup before rollback
        if (!$DryRun) {
            New-MigrationBackup -DbUrl $DbUrl
        }
        
        $query = "SELECT rollback_last_migration();"
        $result = Invoke-SqlQuery -Query $query -DbUrl $DbUrl -ReturnResult
        
        if ($result -and $result -ne "DRY_RUN_SUCCESS") {
            Write-Log "Rollback result: $result" "INFO" "Green"
        } else {
            Write-Log "Rollback completed (or dry run)" "INFO" "Green"
        }
    }
    catch {
        Write-Error-Log "Failed to rollback migration" $_
        throw
    }
}

# Create new migration file
function New-Migration {
    param([string]$Name)
    
    if (!$Name) {
        throw "Migration name is required for create action"
    }
    
    try {
        # Get next version number
        $migrationFiles = Get-ChildItem -Path $script:MigrationsDir -Filter "*.sql" | Sort-Object Name
        $nextVersion = 1
        
        if ($migrationFiles.Count -gt 0) {
            $lastFile = $migrationFiles[-1]
            if ($lastFile.Name -match '^(\d{5})_') {
                $nextVersion = [int]$matches[1] + 1
            }
        }
        
        $versionString = $nextVersion.ToString('00000')
        $fileName = "${versionString}_${Name}.sql"
        $filePath = Join-Path $script:MigrationsDir $fileName
        
        # Create migration template
        $template = @"
-- Migration: $fileName
-- Description: $Name
-- Author: $(whoami)
-- Date: $(Get-Date -Format 'yyyy-MM-dd')

BEGIN;

-- Add your migration SQL here
-- Example:
-- CREATE TABLE example_table (
--     id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
--     name TEXT NOT NULL,
--     created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
-- );

COMMIT;
"@
        
        if ($DryRun) {
            Write-Log "DRY RUN: Would create migration file: $filePath" "INFO" "Yellow"
            Write-Log "Template content:" "INFO" "Yellow"
            Write-Log $template "INFO" "Cyan"
        } else {
            Set-Content -Path $filePath -Value $template
            Write-Log "Created migration file: $filePath" "INFO" "Green"
        }
    }
    catch {
        Write-Error-Log "Failed to create migration" $_
        throw
    }
}

# Main script execution
try {
    Write-Log "Starting migration management - Action: $Action, Environment: $Environment" "INFO" "Green"
    
    # Get database URL for environment
    $dbUrl = Get-DatabaseUrl -Env $Environment
    Write-Log "Using database environment: $Environment" "INFO" "Cyan"
    
    # Execute requested action
    switch ($Action) {
        "apply" {
            Test-MigrationOrder
            Invoke-MigrationApply -DbUrl $dbUrl
            Test-SchemaIntegrity -DbUrl $dbUrl
        }
        "status" {
            Get-MigrationStatus -DbUrl $dbUrl
        }
        "validate" {
            Test-MigrationOrder
            Test-SchemaIntegrity -DbUrl $dbUrl
        }
        "rollback" {
            Invoke-MigrationRollback -DbUrl $dbUrl
        }
        "verify" {
            Test-SchemaIntegrity -DbUrl $dbUrl
        }
        "create" {
            New-Migration -Name $MigrationName
        }
        default {
            throw "Invalid action: $Action"
        }
    }
    
    Write-Log "Migration management completed successfully" "INFO" "Green"
}
catch {
    Write-Error-Log "Migration management failed" $_
    exit 1
}