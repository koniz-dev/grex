# Database Backup Management Script
# This script manages database backups for production deployments

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("create", "restore", "list", "cleanup", "verify")]
    [string]$Action,
    
    [string]$BackupPath = "",
    [string]$Environment = "production",
    [int]$RetentionDays = 30,
    [switch]$Force = $false,
    [switch]$Verbose = $false
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

function Create-DatabaseBackup {
    Write-Step "Creating database backup for $Environment environment..."
    
    try {
        $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
        $backupFileName = "${Environment}_backup_$timestamp.sql"
        $backupDir = "backups/database"
        $fullBackupPath = Join-Path $backupDir $backupFileName
        
        # Ensure backup directory exists
        if (-not (Test-Path $backupDir)) {
            New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
            Write-Success "Created backup directory: $backupDir"
        }
        
        # Create the backup
        Write-Step "Dumping database to $fullBackupPath..."
        supabase db dump --linked --data-only > $fullBackupPath
        
        # Verify backup was created successfully
        if (-not (Test-Path $fullBackupPath)) {
            throw "Backup file was not created"
        }
        
        $backupSize = Get-Item $fullBackupPath | Select-Object -ExpandProperty Length
        if ($backupSize -eq 0) {
            throw "Backup file is empty"
        }
        
        $backupSizeMB = [math]::Round($backupSize / 1MB, 2)
        Write-Success "Backup created successfully: $fullBackupPath ($backupSizeMB MB)"
        
        # Create metadata file
        $metadataPath = $fullBackupPath -replace "\.sql$", ".metadata.json"
        $metadata = @{
            environment = $Environment
            timestamp = $timestamp
            size_bytes = $backupSize
            size_mb = $backupSizeMB
            created_by = $env:USERNAME
            supabase_version = (supabase --version)
        } | ConvertTo-Json -Depth 2
        
        $metadata | Out-File -FilePath $metadataPath -Encoding UTF8
        Write-Success "Backup metadata saved: $metadataPath"
        
        return $fullBackupPath
    }
    catch {
        Write-Error "Failed to create backup: $_"
        throw
    }
}

function Restore-DatabaseBackup {
    param([string]$BackupFile)
    
    if (-not $BackupFile) {
        Write-Error "Backup file path is required for restore operation"
        return
    }
    
    if (-not (Test-Path $BackupFile)) {
        Write-Error "Backup file not found: $BackupFile"
        return
    }
    
    Write-Warning "DANGEROUS OPERATION: This will restore the database from backup"
    Write-Warning "Current data will be LOST"
    Write-Warning "Target: $Environment environment"
    Write-Warning "Backup: $BackupFile"
    
    if (-not $Force) {
        $confirmation = Read-Host "Type 'RESTORE DATABASE' to continue"
        if ($confirmation -ne "RESTORE DATABASE") {
            Write-Warning "Restore operation cancelled"
            return
        }
    }
    
    try {
        Write-Step "Restoring database from backup..."
        
        # First, reset the database
        Write-Step "Resetting database..."
        supabase db reset --linked
        
        # Then restore from backup
        Write-Step "Applying backup data..."
        Get-Content $BackupFile | supabase db reset --linked --file -
        
        Write-Success "Database restored successfully from: $BackupFile"
        
        # Verify restore
        Write-Step "Verifying restore..."
        $testResult = supabase db test --linked
        if ($LASTEXITCODE -eq 0) {
            Write-Success "Database restore verification passed"
        } else {
            Write-Warning "Database restore verification failed - please check manually"
        }
    }
    catch {
        Write-Error "Failed to restore database: $_"
        throw
    }
}

function List-DatabaseBackups {
    Write-Step "Listing database backups..."
    
    $backupDir = "backups/database"
    
    if (-not (Test-Path $backupDir)) {
        Write-Warning "No backup directory found: $backupDir"
        return
    }
    
    $backups = Get-ChildItem -Path $backupDir -Filter "*.sql" | Sort-Object LastWriteTime -Descending
    
    if ($backups.Count -eq 0) {
        Write-Warning "No backup files found in $backupDir"
        return
    }
    
    Write-Success "Found $($backups.Count) backup files:"
    Write-Host ""
    Write-Host "Backup Files:" -ForegroundColor Blue
    Write-Host "=============" -ForegroundColor Blue
    
    foreach ($backup in $backups) {
        $sizeMB = [math]::Round($backup.Length / 1MB, 2)
        $age = (Get-Date) - $backup.LastWriteTime
        $ageText = if ($age.Days -gt 0) { "$($age.Days) days ago" } else { "$($age.Hours) hours ago" }
        
        # Try to read metadata if available
        $metadataPath = $backup.FullName -replace "\.sql$", ".metadata.json"
        $environment = "unknown"
        if (Test-Path $metadataPath) {
            try {
                $metadata = Get-Content $metadataPath | ConvertFrom-Json
                $environment = $metadata.environment
            }
            catch {
                # Ignore metadata read errors
            }
        }
        
        Write-Host "[BACKUP] $($backup.Name)" -ForegroundColor Cyan
        Write-Host "   Environment: $environment"
        Write-Host "   Size: $sizeMB MB"
        Write-Host "   Created: $($backup.LastWriteTime.ToString('yyyy-MM-dd HH:mm:ss')) ($ageText)"
        Write-Host "   Path: $($backup.FullName)"
        Write-Host ""
    }
}

function Cleanup-OldBackups {
    Write-Step "Cleaning up old backups (retention: $RetentionDays days)..."
    
    $backupDir = "backups/database"
    
    if (-not (Test-Path $backupDir)) {
        Write-Warning "No backup directory found: $backupDir"
        return
    }
    
    $cutoffDate = (Get-Date).AddDays(-$RetentionDays)
    $oldBackups = Get-ChildItem -Path $backupDir -Filter "*.sql" | Where-Object { $_.LastWriteTime -lt $cutoffDate }
    
    if ($oldBackups.Count -eq 0) {
        Write-Success "No old backups to clean up"
        return
    }
    
    Write-Warning "Found $($oldBackups.Count) backups older than $RetentionDays days"
    
    if (-not $Force) {
        Write-Host "Backups to be deleted:" -ForegroundColor Yellow
        foreach ($backup in $oldBackups) {
            $age = (Get-Date) - $backup.LastWriteTime
            Write-Host "  - $($backup.Name) ($($age.Days) days old)" -ForegroundColor Yellow
        }
        
        $confirmation = Read-Host "Delete these backups? (y/N)"
        if ($confirmation -ne "y" -and $confirmation -ne "Y") {
            Write-Warning "Cleanup cancelled"
            return
        }
    }
    
    try {
        $deletedCount = 0
        foreach ($backup in $oldBackups) {
            Remove-Item $backup.FullName -Force
            
            # Also remove metadata file if it exists
            $metadataPath = $backup.FullName -replace "\.sql$", ".metadata.json"
            if (Test-Path $metadataPath) {
                Remove-Item $metadataPath -Force
            }
            
            $deletedCount++
            if ($Verbose) {
                Write-Host "Deleted: $($backup.Name)" -ForegroundColor Gray
            }
        }
        
        Write-Success "Cleaned up $deletedCount old backup files"
    }
    catch {
        Write-Error "Failed to cleanup old backups: $_"
        throw
    }
}

function Verify-BackupIntegrity {
    param([string]$BackupFile)
    
    if (-not $BackupFile) {
        Write-Error "Backup file path is required for verification"
        return
    }
    
    if (-not (Test-Path $BackupFile)) {
        Write-Error "Backup file not found: $BackupFile"
        return
    }
    
    Write-Step "Verifying backup integrity: $BackupFile"
    
    try {
        # Check if file is readable
        $content = Get-Content $BackupFile -TotalCount 10
        if ($content.Count -eq 0) {
            throw "Backup file appears to be empty"
        }
        
        # Check if it looks like a SQL file
        $sqlContent = $content -join " "
        if ($sqlContent -notmatch "(INSERT|CREATE|ALTER|DROP)" -and $sqlContent -notmatch "PostgreSQL") {
            Write-Warning "Backup file may not be a valid SQL dump"
        }
        
        # Check file size
        $fileSize = (Get-Item $BackupFile).Length
        if ($fileSize -lt 1KB) {
            Write-Warning "Backup file is very small ($fileSize bytes) - may be incomplete"
        }
        
        # Try to read metadata
        $metadataPath = $BackupFile -replace "\.sql$", ".metadata.json"
        if (Test-Path $metadataPath) {
            try {
                $metadata = Get-Content $metadataPath | ConvertFrom-Json
                Write-Success "Backup metadata is valid"
                
                if ($Verbose) {
                    Write-Host "Metadata:" -ForegroundColor Blue
                    Write-Host "  Environment: $($metadata.environment)"
                    Write-Host "  Size: $($metadata.size_mb) MB"
                    Write-Host "  Created by: $($metadata.created_by)"
                    Write-Host "  Timestamp: $($metadata.timestamp)"
                }
            }
            catch {
                Write-Warning "Backup metadata file is corrupted"
            }
        } else {
            Write-Warning "No metadata file found for backup"
        }
        
        Write-Success "Backup integrity verification completed"
        Write-Success "File size: $([math]::Round($fileSize / 1MB, 2)) MB"
        
    }
    catch {
        Write-Error "Backup integrity verification failed: $_"
        throw
    }
}

# Main execution
try {
    Write-Host "[BACKUP] Database Backup Management" -ForegroundColor Blue
    Write-Host "==============================="
    Write-Host ""
    
    switch ($Action) {
        "create" {
            $backupPath = Create-DatabaseBackup
            Write-Host ""
            Write-Success "Backup operation completed successfully"
            Write-Host "Backup location: $backupPath" -ForegroundColor Cyan
        }
        
        "restore" {
            Restore-DatabaseBackup -BackupFile $BackupPath
            Write-Host ""
            Write-Success "Restore operation completed"
        }
        
        "list" {
            List-DatabaseBackups
        }
        
        "cleanup" {
            Cleanup-OldBackups
            Write-Host ""
            Write-Success "Cleanup operation completed"
        }
        
        "verify" {
            Verify-BackupIntegrity -BackupFile $BackupPath
            Write-Host ""
            Write-Success "Verification completed"
        }
        
        default {
            Write-Error "Unknown action: $Action"
            Write-Host "Valid actions: create, restore, list, cleanup, verify"
            exit 1
        }
    }
}
catch {
    Write-Error "Backup management operation failed: $_"
    exit 1
}