# Database Deployment Scripts

This directory contains the main deployment scripts for staging and production environments.

## Scripts

### staging.ps1
Deploys database schema to staging environment with comprehensive testing.

**Usage:**
```powershell
.\staging.ps1 [-SkipTests] [-Verbose]
```

**Parameters:**
- `-SkipTests`: Skip integration tests (not recommended)
- `-Verbose`: Show detailed output

**Environment Variables Required:**
- `SUPABASE_STAGING_URL`
- `SUPABASE_STAGING_SERVICE_KEY`

### production.ps1
Deploys database schema to production environment with safety checks.

**Usage:**
```powershell
.\production.ps1 [-SkipBackup] [-DryRun] [-Force]
```

**Parameters:**
- `-SkipBackup`: Skip backup creation (not recommended)
- `-DryRun`: Simulate deployment without making changes
- `-Force`: Skip confirmation prompts

**Environment Variables Required:**
- `SUPABASE_PRODUCTION_URL`
- `SUPABASE_PRODUCTION_SERVICE_KEY`

## Workflow

1. **Test readiness**: Run readiness tests first
2. **Simulate**: Run simulation to verify process
3. **Deploy**: Execute actual deployment

## Safety Features

- Automatic backup creation (production)
- Schema integrity verification
- Integration testing (staging)
- Rollback support
- Detailed reporting