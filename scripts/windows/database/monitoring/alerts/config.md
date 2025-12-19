# Database Monitoring Alert Configuration

## Environment: Production
**Created:** $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')

## Alert Thresholds
- **Slow Query Threshold:** 1000ms (queries taking more than 1 second)
- **Connection Pool Warning:** 80% capacity
- **Connection Pool Critical:** 95% capacity
- **Database Size Warning:** Monitor growth trends
- **Index Efficiency Warning:** Below 85%

## Alert Channels
- **Log Files:** scripts/windows/database/monitoring/alerts/health.log
- **Email:** Configure SMTP settings in health check script
- **Slack:** Configure webhook URL for notifications

## Monitoring Schedule (Recommended)
- **Health Check:** Every 5 minutes
- **Performance Check:** Every 15 minutes
- **Daily Report:** Generate daily summary at 9:00 AM

## Usage Instructions

### Manual Monitoring
```powershell
# Run health check
.\scripts\windows\database\monitoring\check-health.ps1

# Generate performance dashboard
.\scripts\windows\database\monitoring\generate-dashboard.ps1

# Run all monitoring tasks
.\scripts\windows\database\monitoring\run-tasks.ps1
```

### Automated Monitoring
Set up Windows Task Scheduler to run monitoring tasks automatically:
1. Open Task Scheduler
2. Create Basic Task
3. Set trigger (e.g., every 5 minutes)
4. Set action to run PowerShell script

## SQL Queries Available
- **Slow Queries:** queries/slow_queries.sql
- **Connections:** queries/connections.sql
- **Table Sizes:** queries/table_sizes.sql
- **Index Usage:** queries/index_usage.sql

## Log Files
- **Health Check Log:** alerts/health.log
- **Performance Reports:** reports/ directory

## Customization
Edit the PowerShell scripts to:
- Add email notifications
- Configure Slack webhooks
- Adjust alert thresholds
- Add custom monitoring queries