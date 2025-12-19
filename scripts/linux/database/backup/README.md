# Database Backup Scripts

This directory contains scripts for managing database backups.

## Scripts

### manage-backups.ps1
Comprehensive backup management script with multiple actions.

**Usage:**
```powershell
.\manage-backups.ps1 -Action <action> [parameters]
```

**Actions:**

#### create
Creates a new database backup.
```powershell
.\manage-backups.ps1 -Action create [-Environment production|staging]
```

#### restore
Restores database from backup.
```powershell
.\manage-backups.ps1 -Action restore -BackupPath "path/to/backup.sql" [-Force]
```

#### list
Lists all available backups.
```powershell
.\manage-backups.ps1 -Action list
```

#### cleanup
Removes old backups based on retention policy.
```powershell
.\manage-backups.ps1 -Action cleanup [-RetentionDays 30] [-Force]
```

#### verify
Verifies backup file integrity.
```powershell
.\manage-backups.ps1 -Action verify -BackupPath "path/to/backup.sql"
```

## Features

- **Automatic metadata**: Each backup includes metadata file
- **Integrity verification**: Validates backup files
- **Retention management**: Automatic cleanup of old backups
- **Environment tagging**: Tracks which environment backup came from
- **Size tracking**: Monitors backup file sizes

## Backup Location

All backups are stored in: `backups/database/`

## Safety

- Restore operations require confirmation
- Use `-Force` flag to skip confirmations (automation only)
- Always verify backups before relying on them