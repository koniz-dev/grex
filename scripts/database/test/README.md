# Database Testing Scripts

This directory contains scripts for testing deployment readiness and simulating deployments.

## Scripts

### staging-readiness.ps1
Tests if staging environment is ready for deployment.

**Usage:**
```powershell
.\staging-readiness.ps1
```

**Checks:**
- Migration files exist
- Backup directory setup
- RLS policies present
- Audit triggers present
- Environment variables (optional for staging)

### production-readiness.ps1
Tests if production environment is ready for deployment.

**Usage:**
```powershell
.\production-readiness.ps1
```

**Checks:**
- Migration files exist
- Backup directory setup
- RLS policies present
- Audit triggers present
- Environment variables (required for production)

### simulate-staging.ps1
Simulates staging deployment process without making changes.

**Usage:**
```powershell
.\simulate-staging.ps1 [-Verbose]
```

### simulate-production.ps1
Simulates production deployment process without making changes.

**Usage:**
```powershell
.\simulate-production.ps1 [-Verbose]
```

## Workflow

1. **Run readiness test** to check prerequisites
2. **Run simulation** to verify deployment process
3. **Proceed to actual deployment** if tests pass

## Reports

All scripts generate detailed reports with:
- Test results
- Issues found
- Next steps
- Recommendations