# Database Vulnerability Scanner for Grex Application
# This script scans for common database security vulnerabilities

<#
.SYNOPSIS
    Scans the Grex database for security vulnerabilities

.DESCRIPTION
    This script performs automated vulnerability scanning to identify
    potential security issues, misconfigurations, and compliance violations.

.PARAMETER Environment
    Target environment: development, staging, production

.PARAMETER ScanType
    Type of scan: all, config, permissions, data, network

.PARAMETER OutputFormat
    Output format: console, json, html

.EXAMPLE
    .\vulnerability-scan.ps1 -Environment production -ScanType all -OutputFormat json
    Perform comprehensive vulnerability scan with JSON output

.NOTES
    Author: Grex Development Team
    Date: 2024-01-15
    Version: 1.0
#>

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("development", "staging", "production")]
    [string]$Environment,
    
    [Parameter(Mandatory=$false)]
    [ValidateSet("all", "config", "permissions", "data", "network")]
    [string]$ScanType = "all",
    
    [Parameter(Mandatory=$false)]
    [ValidateSet("console", "json", "html")]
    [string]$OutputFormat = "console"
)

# Configuration
$script:Vulnerabilities = @()
$script:LogFile = "logs/vulnerability-scan-$(Get-Date -Format 'yyyyMMdd_HHmmss').log"

# Vulnerability severity levels
$SeverityLevels = @{
    "CRITICAL" = @{ Color = "Red"; Score = 10 }
    "HIGH" = @{ Color = "Red"; Score = 8 }
    "MEDIUM" = @{ Color = "Yellow"; Score = 5 }
    "LOW" = @{ Color = "Yellow"; Score = 3 }
    "INFO" = @{ Color = "Cyan"; Score = 1 }
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
    
    Write-Host $logMessage -ForegroundColor $Color
    Add-Content -Path $script:LogFile -Value $logMessage
}

# Add vulnerability finding
function Add-Vulnerability {
    param(
        [string]$Title,
        [string]$Description,
        [string]$Severity,
        [string]$Category,
        [string]$Recommendation = "",
        [hashtable]$Details = @{}
    )
    
    $vulnerability = @{
        Title = $Title
        Description = $Description
        Severity = $Severity
        Category = $Category
        Recommendation = $Recommendation
        Details = $Details
        Timestamp = Get-Date
        Score = $SeverityLevels[$Severity].Score
    }
    
    $script:Vulnerabilities += $vulnerability
    
    $color = $SeverityLevels[$Severity].Color
    Write-Log "[$Severity] $Title - $Description" "VULN" $color
}

# Get database connection
function Get-DatabaseUrl {
    param([string]$Env)
    
    switch ($Env) {
        "development" { 
            if ($env:DATABASE_URL_DEV) { 
                return $env:DATABASE_URL_DEV 
            } else { 
                return "postgresql://postgres:postgres@127.0.0.1:54322/postgres" 
            }
        }
        "staging" { 
            if ($env:DATABASE_URL_STAGING) { 
                return $env:DATABASE_URL_STAGING 
            } else { 
                return $env:DATABASE_URL 
            }
        }
        "production" { 
            if ($env:DATABASE_URL_PROD) { 
                return $env:DATABASE_URL_PROD 
            } else { 
                return $env:DATABASE_URL 
            }
        }
        default { 
            throw "Invalid environment: $Env"
        }
    }
}

# Execute SQL query
function Invoke-SqlQuery {
    param(
        [string]$Query,
        [string]$DbUrl,
        [switch]$ReturnResult
    )
    
    try {
        if ($ReturnResult) {
            return psql $DbUrl -c $Query -t -A 2>$null
        } else {
            psql $DbUrl -c $Query 2>$null | Out-Null
            return $LASTEXITCODE -eq 0
        }
    }
    catch {
        return $null
    }
}

# Scan 1: Configuration Vulnerabilities
function Test-ConfigurationSecurity {
    param([string]$DbUrl)
    
    Write-Log "=== Scanning Configuration Security ===" "INFO" "Cyan"
    
    # Check for weak authentication settings
    $authQuery = "SELECT name, setting FROM pg_settings WHERE name LIKE '%auth%' OR name LIKE '%password%';"
    $authSettings = Invoke-SqlQuery -Query $authQuery -DbUrl $DbUrl -ReturnResult
    
    if ($authSettings) {
        foreach ($setting in $authSettings) {
            $parts = $setting -split '\|'
            if ($parts.Length -ge 2) {
                $name = $parts[0]
                $value = $parts[1]
                
                # Check for insecure settings
                if ($name -eq "password_encryption" -and $value -ne "scram-sha-256") {
                    Add-Vulnerability -Title "Weak Password Encryption" -Description "Password encryption is not using SCRAM-SHA-256" -Severity "MEDIUM" -Category "Configuration" -Recommendation "Set password_encryption = 'scram-sha-256'"
                }
                
                if ($name -like "*ssl*" -and $value -eq "off") {
                    Add-Vulnerability -Title "SSL Disabled" -Description "SSL is disabled for database connections" -Severity "HIGH" -Category "Configuration" -Recommendation "Enable SSL for all database connections"
                }
            }
        }
    }
    
    # Check for default database names
    $dbQuery = "SELECT datname FROM pg_database WHERE datname IN ('postgres', 'template1', 'template0');"
    $databases = Invoke-SqlQuery -Query $dbQuery -DbUrl $DbUrl -ReturnResult
    
    if ($databases -match "postgres" -and $Environment -eq "production") {
        Add-Vulnerability -Title "Default Database Name" -Description "Using default 'postgres' database name in production" -Severity "LOW" -Category "Configuration" -Recommendation "Use a custom database name for production"
    }
    
    # Check for excessive privileges
    $privQuery = "SELECT rolname, rolsuper, rolcreaterole, rolcreatedb FROM pg_roles WHERE rolsuper = true;"
    $superUsers = Invoke-SqlQuery -Query $privQuery -DbUrl $DbUrl -ReturnResult
    
    if ($superUsers) {
        $superUserCount = ($superUsers | Measure-Object).Count
        if ($superUserCount -gt 2) {  # postgres + one admin user
            Add-Vulnerability -Title "Excessive Superuser Accounts" -Description "Found $superUserCount superuser accounts" -Severity "MEDIUM" -Category "Configuration" -Recommendation "Limit superuser accounts to minimum necessary"
        }
    }
}

# Scan 2: Permission Vulnerabilities
function Test-PermissionSecurity {
    param([string]$DbUrl)
    
    Write-Log "=== Scanning Permission Security ===" "INFO" "Cyan"
    
    # Check for overly permissive RLS policies
    $rlsQuery = @"
SELECT 
    tablename,
    policyname,
    cmd,
    qual,
    with_check
FROM pg_policies 
WHERE schemaname = 'public'
AND (qual IS NULL OR qual = '' OR qual LIKE '%true%' OR qual LIKE '%1=1%');
"@
    
    $permissivePolicies = Invoke-SqlQuery -Query $rlsQuery -DbUrl $DbUrl -ReturnResult
    
    if ($permissivePolicies) {
        foreach ($policy in $permissivePolicies) {
            $parts = $policy -split '\|'
            if ($parts.Length -ge 2) {
                $table = $parts[0]
                $policyName = $parts[1]
                
                Add-Vulnerability -Title "Overly Permissive RLS Policy" -Description "Policy '$policyName' on table '$table' may be too permissive" -Severity "MEDIUM" -Category "Permissions" -Recommendation "Review and tighten RLS policy conditions"
            }
        }
    }
    
    # Check for functions with SECURITY DEFINER
    $secDefQuery = "SELECT proname, prosecdef FROM pg_proc WHERE prosecdef = true AND proname NOT LIKE 'pg_%';"
    $secDefFunctions = Invoke-SqlQuery -Query $secDefQuery -DbUrl $DbUrl -ReturnResult
    
    if ($secDefFunctions) {
        foreach ($func in $secDefFunctions) {
            $funcName = ($func -split '\|')[0]
            Add-Vulnerability -Title "SECURITY DEFINER Function" -Description "Function '$funcName' runs with elevated privileges" -Severity "LOW" -Category "Permissions" -Recommendation "Review function security and ensure proper input validation" -Details @{ Function = $funcName }
        }
    }
    
    # Check for public schema permissions
    $publicPermsQuery = "SELECT grantee, privilege_type FROM information_schema.schema_privileges WHERE schema_name = 'public';"
    $publicPerms = Invoke-SqlQuery -Query $publicPermsQuery -DbUrl $DbUrl -ReturnResult
    
    if ($publicPerms -match "PUBLIC.*CREATE") {
        Add-Vulnerability -Title "Public Schema CREATE Permission" -Description "PUBLIC role has CREATE permission on public schema" -Severity "MEDIUM" -Category "Permissions" -Recommendation "Revoke CREATE permission from PUBLIC role on public schema"
    }
}

# Scan 3: Data Security Vulnerabilities
function Test-DataSecurity {
    param([string]$DbUrl)
    
    Write-Log "=== Scanning Data Security ===" "INFO" "Cyan"
    
    # Check for unencrypted sensitive data
    $sensitiveColumns = @(
        @{ Table = "users"; Column = "email"; Type = "PII" },
        @{ Table = "audit_logs"; Column = "before_state"; Type = "Sensitive" },
        @{ Table = "audit_logs"; Column = "after_state"; Type = "Sensitive" }
    )
    
    foreach ($col in $sensitiveColumns) {
        $encryptQuery = @"
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = '$($col.Table)' 
AND column_name = '$($col.Column)'
AND data_type NOT LIKE '%encrypted%';
"@
        
        $result = Invoke-SqlQuery -Query $encryptQuery -DbUrl $DbUrl -ReturnResult
        
        if ($result) {
            Add-Vulnerability -Title "Unencrypted Sensitive Data" -Description "$($col.Type) data in $($col.Table).$($col.Column) is not encrypted" -Severity "MEDIUM" -Category "Data Security" -Recommendation "Consider encrypting sensitive data at rest"
        }
    }
    
    # Check for data retention policies
    $retentionQuery = @"
SELECT 
    schemaname,
    tablename,
    n_tup_ins,
    n_tup_upd,
    n_tup_del
FROM pg_stat_user_tables 
WHERE schemaname = 'public'
ORDER BY n_tup_ins DESC;
"@
    
    $tableStats = Invoke-SqlQuery -Query $retentionQuery -DbUrl $DbUrl -ReturnResult
    
    if ($tableStats) {
        foreach ($stat in $tableStats) {
            $parts = $stat -split '\|'
            if ($parts.Length -ge 5) {
                $table = $parts[1]
                $inserts = [int]$parts[2]
                
                # Check for tables with high insert counts but no apparent cleanup
                if ($table -eq "audit_logs" -and $inserts -gt 100000) {
                    Add-Vulnerability -Title "Large Audit Log Table" -Description "Audit logs table has $inserts records without apparent retention policy" -Severity "LOW" -Category "Data Security" -Recommendation "Implement audit log retention and archival policy"
                }
            }
        }
    }
    
    # Check for soft-deleted data cleanup
    $softDeleteQuery = @"
SELECT 
    table_name,
    COUNT(*) as deleted_count
FROM (
    SELECT 'users' as table_name, COUNT(*) FROM users WHERE deleted_at IS NOT NULL
    UNION ALL
    SELECT 'groups' as table_name, COUNT(*) FROM groups WHERE deleted_at IS NOT NULL
    UNION ALL
    SELECT 'expenses' as table_name, COUNT(*) FROM expenses WHERE deleted_at IS NOT NULL
    UNION ALL
    SELECT 'payments' as table_name, COUNT(*) FROM payments WHERE deleted_at IS NOT NULL
) t
WHERE t.count > 0;
"@
    
    $softDeleted = Invoke-SqlQuery -Query $softDeleteQuery -DbUrl $DbUrl -ReturnResult
    
    if ($softDeleted) {
        foreach ($table in $softDeleted) {
            $parts = $table -split '\|'
            if ($parts.Length -ge 2) {
                $tableName = $parts[0]
                $count = $parts[1]
                
                if ([int]$count -gt 1000) {
                    Add-Vulnerability -Title "Large Soft-Deleted Dataset" -Description "Table '$tableName' has $count soft-deleted records" -Severity "LOW" -Category "Data Security" -Recommendation "Implement cleanup policy for old soft-deleted records"
                }
            }
        }
    }
}

# Scan 4: Network Security
function Test-NetworkSecurity {
    param([string]$DbUrl)
    
    Write-Log "=== Scanning Network Security ===" "INFO" "Cyan"
    
    # Parse connection string to check security
    if ($DbUrl -match "postgresql://([^:]+):([^@]+)@([^:]+):(\d+)/(.+)") {
        $dbHost = $matches[3]
        $dbPort = $matches[4]
        
        # Check for localhost in production
        if ($Environment -eq "production" -and ($dbHost -eq "localhost" -or $dbHost -eq "127.0.0.1")) {
            Add-Vulnerability -Title "Localhost Database in Production" -Description "Production environment using localhost database connection" -Severity "HIGH" -Category "Network Security" -Recommendation "Use proper database host for production environment"
        }
        
        # Check for default ports
        if ($dbPort -eq "5432") {
            Add-Vulnerability -Title "Default Database Port" -Description "Using default PostgreSQL port 5432" -Severity "LOW" -Category "Network Security" -Recommendation "Consider using non-default port for additional security"
        }
        
        # Check for unencrypted connections
        if ($DbUrl -notmatch "sslmode=require" -and $Environment -eq "production") {
            Add-Vulnerability -Title "Unencrypted Database Connection" -Description "Database connection may not be encrypted" -Severity "HIGH" -Category "Network Security" -Recommendation "Ensure SSL/TLS encryption for database connections"
        }
    }
    
    # Check connection limits
    $connQuery = "SELECT name, setting FROM pg_settings WHERE name = 'max_connections';"
    $maxConn = Invoke-SqlQuery -Query $connQuery -DbUrl $DbUrl -ReturnResult
    
    if ($maxConn) {
        $connLimit = [int](($maxConn -split '\|')[1])
        
        if ($connLimit -gt 200) {
            Add-Vulnerability -Title "High Connection Limit" -Description "Maximum connections set to $connLimit" -Severity "LOW" -Category "Network Security" -Recommendation "Review connection pooling and limit settings"
        }
    }
}

# Generate vulnerability report
function New-VulnerabilityReport {
    Write-Log "=== Vulnerability Scan Report ===" "INFO" "Cyan"
    
    $totalVulns = $script:Vulnerabilities.Count
    $criticalVulns = ($script:Vulnerabilities | Where-Object { $_.Severity -eq "CRITICAL" }).Count
    $highVulns = ($script:Vulnerabilities | Where-Object { $_.Severity -eq "HIGH" }).Count
    $mediumVulns = ($script:Vulnerabilities | Where-Object { $_.Severity -eq "MEDIUM" }).Count
    $lowVulns = ($script:Vulnerabilities | Where-Object { $_.Severity -eq "LOW" }).Count
    
    Write-Log "Total Vulnerabilities: $totalVulns" "INFO" "Cyan"
    Write-Log "Critical: $criticalVulns" "INFO" "Red"
    Write-Log "High: $highVulns" "INFO" "Red"
    Write-Log "Medium: $mediumVulns" "INFO" "Yellow"
    Write-Log "Low: $lowVulns" "INFO" "Yellow"
    
    # Calculate risk score
    $riskScore = ($criticalVulns * 10) + ($highVulns * 8) + ($mediumVulns * 5) + ($lowVulns * 3)
    Write-Log "Risk Score: $riskScore" "INFO" "Cyan"
    
    # Group by category
    $categories = $script:Vulnerabilities | Group-Object Category
    foreach ($category in $categories) {
        Write-Log "$($category.Name): $($category.Count) vulnerabilities" "INFO" "Cyan"
    }
    
    # Generate output based on format
    $report = @{
        Environment = $Environment
        ScanType = $ScanType
        Timestamp = Get-Date
        Summary = @{
            TotalVulnerabilities = $totalVulns
            Critical = $criticalVulns
            High = $highVulns
            Medium = $mediumVulns
            Low = $lowVulns
            RiskScore = $riskScore
        }
        Vulnerabilities = $script:Vulnerabilities
        Categories = ($categories | ForEach-Object { @{ Name = $_.Name; Count = $_.Count } })
    }
    
    switch ($OutputFormat) {
        "json" {
            $reportPath = "logs/vulnerability-report-$(Get-Date -Format 'yyyyMMdd_HHmmss').json"
            $report | ConvertTo-Json -Depth 10 | Set-Content -Path $reportPath
            Write-Log "JSON report saved to: $reportPath" "INFO" "Green"
        }
        "html" {
            $reportPath = "logs/vulnerability-report-$(Get-Date -Format 'yyyyMMdd_HHmmss').html"
            $html = New-HtmlReport -Report $report
            $html | Set-Content -Path $reportPath
            Write-Log "HTML report saved to: $reportPath" "INFO" "Green"
        }
        "console" {
            # Already displayed above
        }
    }
    
    return $riskScore
}

# Generate HTML report
function New-HtmlReport {
    param([hashtable]$Report)
    
    $html = @"
<!DOCTYPE html>
<html>
<head>
    <title>Grex Database Vulnerability Report</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        .header { background-color: #f0f0f0; padding: 20px; border-radius: 5px; }
        .summary { display: flex; gap: 20px; margin: 20px 0; }
        .metric { background-color: #e9ecef; padding: 15px; border-radius: 5px; text-align: center; }
        .critical { color: #dc3545; }
        .high { color: #fd7e14; }
        .medium { color: #ffc107; }
        .low { color: #28a745; }
        .vulnerability { border: 1px solid #ddd; margin: 10px 0; padding: 15px; border-radius: 5px; }
        .vuln-title { font-weight: bold; font-size: 1.1em; }
        .vuln-severity { padding: 3px 8px; border-radius: 3px; color: white; font-size: 0.9em; }
        .severity-critical { background-color: #dc3545; }
        .severity-high { background-color: #fd7e14; }
        .severity-medium { background-color: #ffc107; }
        .severity-low { background-color: #28a745; }
    </style>
</head>
<body>
    <div class="header">
        <h1>Grex Database Vulnerability Report</h1>
        <p><strong>Environment:</strong> $($Report.Environment)</p>
        <p><strong>Scan Type:</strong> $($Report.ScanType)</p>
        <p><strong>Generated:</strong> $($Report.Timestamp)</p>
    </div>
    
    <div class="summary">
        <div class="metric">
            <h3>Total Vulnerabilities</h3>
            <div style="font-size: 2em;">$($Report.Summary.TotalVulnerabilities)</div>
        </div>
        <div class="metric">
            <h3>Risk Score</h3>
            <div style="font-size: 2em;">$($Report.Summary.RiskScore)</div>
        </div>
        <div class="metric critical">
            <h3>Critical</h3>
            <div style="font-size: 2em;">$($Report.Summary.Critical)</div>
        </div>
        <div class="metric high">
            <h3>High</h3>
            <div style="font-size: 2em;">$($Report.Summary.High)</div>
        </div>
        <div class="metric medium">
            <h3>Medium</h3>
            <div style="font-size: 2em;">$($Report.Summary.Medium)</div>
        </div>
        <div class="metric low">
            <h3>Low</h3>
            <div style="font-size: 2em;">$($Report.Summary.Low)</div>
        </div>
    </div>
    
    <h2>Vulnerabilities</h2>
"@
    
    foreach ($vuln in $Report.Vulnerabilities) {
        $severityClass = "severity-$($vuln.Severity.ToLower())"
        $html += @"
    <div class="vulnerability">
        <div class="vuln-title">$($vuln.Title) <span class="vuln-severity $severityClass">$($vuln.Severity)</span></div>
        <p><strong>Category:</strong> $($vuln.Category)</p>
        <p><strong>Description:</strong> $($vuln.Description)</p>
        <p><strong>Recommendation:</strong> $($vuln.Recommendation)</p>
    </div>
"@
    }
    
    $html += @"
</body>
</html>
"@
    
    return $html
}

# Main execution
try {
    Write-Log "Starting vulnerability scan - Environment: $Environment, Type: $ScanType" "INFO" "Green"
    
    $dbUrl = Get-DatabaseUrl -Env $Environment
    Write-Log "Connected to database environment: $Environment" "INFO" "Cyan"
    
    # Execute scans based on type
    switch ($ScanType) {
        "all" {
            Test-ConfigurationSecurity -DbUrl $dbUrl
            Test-PermissionSecurity -DbUrl $dbUrl
            Test-DataSecurity -DbUrl $dbUrl
            Test-NetworkSecurity -DbUrl $dbUrl
        }
        "config" {
            Test-ConfigurationSecurity -DbUrl $dbUrl
        }
        "permissions" {
            Test-PermissionSecurity -DbUrl $dbUrl
        }
        "data" {
            Test-DataSecurity -DbUrl $dbUrl
        }
        "network" {
            Test-NetworkSecurity -DbUrl $dbUrl
        }
    }
    
    # Generate report
    $riskScore = New-VulnerabilityReport
    
    Write-Log "Vulnerability scan completed" "INFO" "Green"
    
    # Exit with appropriate code based on findings
    if (($script:Vulnerabilities | Where-Object { $_.Severity -in @("CRITICAL", "HIGH") }).Count -gt 0) {
        Write-Log "Critical or high severity vulnerabilities found!" "ERROR" "Red"
        exit 1
    } else {
        Write-Log "No critical vulnerabilities found" "INFO" "Green"
        exit 0
    }
}
catch {
    Write-Log "Vulnerability scan failed: $($_.Exception.Message)" "ERROR" "Red"
    exit 1
}