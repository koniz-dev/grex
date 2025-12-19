# Database Monitoring System

## Overview

Comprehensive database monitoring system for Supabase PostgreSQL database with health checks, performance monitoring, and alerting capabilities.

## Components

### 1. Health Monitoring
- **Script:** `check-health.ps1`
- **Purpose:** Test database connectivity and basic functionality
- **Output:** Health status and log entries

### 2. Performance Dashboard
- **Script:** `generate-dashboard.ps1`
- **Purpose:** Generate HTML performance reports
- **Output:** HTML dashboard in `reports/` directory

### 3. SQL Monitoring Queries
- **Location:** `queries/` directory
- **Files:**
  - `slow_queries.sql` - Identify slow-performing queries
  - `connections.sql` - Monitor database connections
  - `table_sizes.sql` - Track table growth
  - `index_usage.sql` - Monitor index efficiency

### 4. Task Runner
- **Script:** `run-tasks.ps1`
- **Purpose:** Execute monitoring tasks individually or all together
- **Options:** `health`, `dashboard`, `all`

## Quick Start

### 1. Run Health Check
```powershell
.\scripts\windows\database\monitoring\check-health.ps1
```

### 2. Generate Performance Dashboard
```powershell
.\scripts\windows\database\monitoring\generate-dashboard.ps1
```

### 3. Run All Monitoring Tasks
```powershell
.\scripts\windows\database\monitoring\run-tasks.ps1
```

## File Structure

```
scripts/windows/database/monitoring/
├── check-health.ps1                   # Health monitoring
├── generate-dashboard.ps1             # Dashboard generator
├── run-tasks.ps1                      # Task runner
├── README.md                          # This documentation
├── queries/                           # SQL monitoring queries
│   ├── slow_queries.sql
│   ├── connections.sql
│   ├── table_sizes.sql
│   └── index_usage.sql
├── alerts/                            # Alert configuration and logs
│   ├── config.md                      # Alert configuration
│   └── health.log                     # Health check logs
└── reports/                           # Generated reports
    └── dashboard_*.html               # Performance dashboards
```

## Configuration

### Alert Thresholds
Edit `alerts/config.md` to configure:
- Slow query thresholds
- Connection pool limits
- Database size warnings
- Index efficiency thresholds

### Environment Variables
Set these for database connectivity:
- `SUPABASE_PRODUCTION_URL`
- `SUPABASE_PRODUCTION_SERVICE_KEY`

## Automated Monitoring

### Windows Task Scheduler Setup
1. Open Task Scheduler as Administrator
2. Create Basic Task
3. Set name: "Database Monitoring"
4. Set trigger: Every 5 minutes
5. Set action: Start a program
6. Program: `PowerShell.exe`
7. Arguments: `-File "C:\path\to\scripts\database\monitoring\run-tasks.ps1"`

### Recommended Schedule
- **Health Check:** Every 5 minutes
- **Performance Dashboard:** Every 15 minutes
- **Daily Summary:** Once per day

## Customization

### Adding New Monitoring Queries
1. Create SQL file in `queries/` directory
2. Add execution logic to dashboard generator
3. Update documentation

### Email Notifications
Modify `check-health.ps1` to add SMTP configuration:
```powershell
# Add email notification logic
if ($healthStatus -eq "FAILED") {
    Send-MailMessage -To "admin@example.com" -Subject "Database Alert" -Body $alertMessage
}
```

### Slack Integration
Add webhook URL to send alerts to Slack:
```powershell
# Add Slack webhook logic
$webhookUrl = "https://hooks.slack.com/services/YOUR/WEBHOOK/URL"
Invoke-RestMethod -Uri $webhookUrl -Method Post -Body (@{text=$alertMessage} | ConvertTo-Json)
```

## Troubleshooting

### Common Issues

1. **"Cannot find project ref" error**
   - Run `supabase link --project-ref YOUR_PROJECT_ID`
   - Ensure environment variables are set

2. **Permission denied errors**
   - Run PowerShell as Administrator
   - Check file permissions

3. **Missing reports**
   - Verify `reports/` directory exists
   - Check disk space

### Log Files
- **Health Check Logs:** `alerts/health.log`
- **System Logs:** Windows Event Viewer
- **PowerShell Errors:** Console output

## Integration with Deployment

This monitoring system integrates with the deployment scripts:
- Health checks validate deployment success
- Performance monitoring tracks post-deployment metrics
- Alerts notify of any issues after deployment

## Security Considerations

- Store service keys securely (environment variables)
- Limit access to monitoring scripts
- Regularly rotate database credentials
- Monitor access logs

---
*Database Monitoring System*
*Created: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')*