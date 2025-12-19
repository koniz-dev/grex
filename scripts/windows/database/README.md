# Database Scripts

This directory contains all database-related scripts organized by function.

## Directory Structure

```
scripts/windows/database/
├── deploy/          # Main deployment scripts
│   ├── staging.ps1
│   ├── production.ps1
│   └── README.md
├── test/           # Testing and simulation scripts
│   ├── staging-readiness.ps1
│   ├── production-readiness.ps1
│   ├── simulate-staging.ps1
│   ├── simulate-production.ps1
│   └── README.md
├── backup/         # Backup management scripts
│   ├── manage-backups.ps1
│   └── README.md
├── security/       # Security testing and review scripts
│   ├── security-review.ps1
│   ├── rls-policy-review.ps1
│   ├── sql-injection-review.ps1
│   └── README.md
├── monitoring/     # Monitoring and health check scripts
│   ├── check-health.ps1
│   ├── generate-dashboard.ps1
│   └── queries/
├── utils/          # Utility scripts
│   ├── final-verification.ps1
│   ├── validate-structure.ps1
│   └── README.md
└── README.md       # This file
```

## Quick Start

### 1. Test Readiness
```powershell
# For staging
.\test\staging-readiness.ps1

# For production  
.\test\production-readiness.ps1
```

### 2. Simulate Deployment
```powershell
# Staging simulation
.\test\simulate-staging.ps1

# Production simulation
.\test\simulate-production.ps1
```

### 3. Deploy
```powershell
# Deploy to staging
.\deploy\staging.ps1

# Deploy to production (with dry run first)
.\deploy\production.ps1 -DryRun
.\deploy\production.ps1
```

### 4. Manage Backups
```powershell
# Create backup
.\backup\manage-backups.ps1 -Action create

# List backups
.\backup\manage-backups.ps1 -Action list

# Cleanup old backups
.\backup\manage-backups.ps1 -Action cleanup
```

### 5. Monitor System
```powershell
# Health check
.\monitoring\check-health.ps1

# Generate dashboard
.\monitoring\generate-dashboard.ps1
```

### 6. Security Review
```powershell
# Comprehensive security review
.\security\security-review.ps1 -Environment staging -TestType all

# Specific security tests
.\security\test-rls-policies.ps1
.\security\test-sql-injection.ps1
```

### 7. Final Verification
```powershell
# Verify all components
.\utils\final-verification.ps1
```

## Environment Variables

### Staging
- `SUPABASE_STAGING_URL`
- `SUPABASE_STAGING_SERVICE_KEY`

### Production
- `SUPABASE_PRODUCTION_URL`
- `SUPABASE_PRODUCTION_SERVICE_KEY`

## Workflow

1. **Prepare**: Set environment variables
2. **Test**: Run readiness tests
3. **Simulate**: Run deployment simulation
4. **Deploy**: Execute actual deployment
5. **Monitor**: Check system health
6. **Backup**: Manage database backups

## Safety Features

- Readiness testing before deployment
- Deployment simulation
- Automatic backup creation
- Schema integrity verification
- Detailed logging and reporting
- Rollback support

## Support

Each subdirectory contains its own README.md with detailed usage instructions.