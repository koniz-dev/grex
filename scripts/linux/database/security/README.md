# Database Security Scripts

This directory contains scripts for security testing and review of the database.

## Scripts

### security-review.ps1
Comprehensive security review and testing script.

**Usage:**
```powershell
.\security-review.ps1 -Environment <env> [-TestType <type>] [-VerboseOutput]
```

**Parameters:**
- `-Environment`: Target environment (development, staging, production)
- `-TestType`: Type of test (all, rls, injection, permissions, isolation)
- `-VerboseOutput`: Enable detailed output

**Tests Performed:**
- RLS enablement verification
- RLS policies validation
- Data isolation testing
- Permission escalation prevention
- SQL injection prevention
- Audit log security
- Security configuration review

### Other Security Scripts

- **test-api-key-security.ps1**: Test API key security configuration
- **test-audit-logging.ps1**: Test audit logging system functionality
- **test-rls-policies.ps1**: Test Row Level Security policies
- **test-rls-simple.ps1**: Simple RLS functionality testing
- **test-sql-injection.ps1**: Test SQL injection prevention
- **scan-vulnerabilities.ps1**: Scan for security vulnerabilities

## Security Testing Workflow

1. **Run comprehensive review**: `.\security-review.ps1 -Environment staging -TestType all`
2. **Review specific areas**: Use individual scripts for focused testing
3. **Generate reports**: All scripts generate detailed security reports
4. **Fix issues**: Address any security vulnerabilities found
5. **Re-test**: Verify fixes with follow-up testing

## Reports

All security scripts generate:
- Detailed test results
- Security scores
- Issue summaries
- Remediation recommendations

Reports are saved in `logs/` directory with timestamps.