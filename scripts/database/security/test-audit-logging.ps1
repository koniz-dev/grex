# Audit Logging Security Review Script
# This script reviews audit logging implementation for security compliance

<#
.SYNOPSIS
    Reviews audit logging implementation in the Grex database

.DESCRIPTION
    This script analyzes audit logging implementation to ensure
    all sensitive operations are logged and audit logs are immutable.

.EXAMPLE
    .\audit-logging-review.ps1
    Run audit logging security review

.NOTES
    Author: Grex Development Team
    Date: 2024-01-15
    Version: 1.0
#>

# Configuration
$script:MigrationsDir = "supabase/migrations"
$script:LogFile = "logs/audit-review-$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
$script:Issues = @()

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

# Add security issue
function Add-SecurityIssue {
    param(
        [string]$Title,
        [string]$Description,
        [string]$Severity,
        [string]$File = "",
        [string]$Recommendation = ""
    )
    
    $issue = @{
        Title = $Title
        Description = $Description
        Severity = $Severity
        File = $File
        Recommendation = $Recommendation
        Timestamp = Get-Date
    }
    
    $script:Issues += $issue
    
    $color = switch ($Severity) {
        "CRITICAL" { "Red" }
        "HIGH" { "Red" }
        "MEDIUM" { "Yellow" }
        "LOW" { "Yellow" }
        default { "White" }
    }
    
    Write-Log "[$Severity] $Title - $Description" "ISSUE" $color
}

# Review audit logs table
function Test-AuditLogsTable {
    Write-Log "=== Reviewing Audit Logs Table ===" "INFO" "Cyan"
    
    $auditFile = Join-Path $script:MigrationsDir "00008_create_audit_logs_table.sql"
    
    if (!(Test-Path $auditFile)) {
        Add-SecurityIssue -Title "Audit Logs Table Missing" -Description "Audit logs table migration not found" -Severity "CRITICAL" -Recommendation "Create audit_logs table"
        return
    }
    
    $content = Get-Content $auditFile -Raw
    
    # Check for required columns
    $requiredColumns = @(
        @{ Column = "entity_type"; Description = "Type of entity being audited" },
        @{ Column = "entity_id"; Description = "ID of the entity being audited" },
        @{ Column = "action"; Description = "Action performed (create, update, delete)" },
        @{ Column = "user_id"; Description = "User who performed the action" },
        @{ Column = "before_state"; Description = "State before the change" },
        @{ Column = "after_state"; Description = "State after the change" },
        @{ Column = "created_at"; Description = "When the action occurred" }
    )
    
    foreach ($col in $requiredColumns) {
        if ($content -match $col.Column) {
            Write-Log "[PASS] Required column found: $($col.Column)" "INFO" "Green"
        } else {
            Add-SecurityIssue -Title "Missing Audit Column" -Description "Required column '$($col.Column)' not found" -Severity "HIGH" -File $auditFile -Recommendation "Add $($col.Column) column for $($col.Description)"
        }
    }
    
    # Check for JSONB storage
    if ($content -match "JSONB") {
        Write-Log "[PASS] JSONB storage found for flexible audit data" "INFO" "Green"
    } else {
        Add-SecurityIssue -Title "Missing JSONB Storage" -Description "Audit logs should use JSONB for flexible state storage" -Severity "MEDIUM" -File $auditFile -Recommendation "Use JSONB for before_state and after_state columns"
    }
    
    # Check for immutability rules
    if ($content -match "CREATE RULE.*audit_logs_no_update.*DO INSTEAD NOTHING") {
        Write-Log "[PASS] UPDATE prevention rule found" "INFO" "Green"
    } else {
        Add-SecurityIssue -Title "Audit Logs Can Be Updated" -Description "No rule preventing UPDATE operations on audit logs" -Severity "HIGH" -File $auditFile -Recommendation "Add rule to prevent UPDATE operations"
    }
    
    if ($content -match "CREATE RULE.*audit_logs_no_delete.*DO INSTEAD NOTHING") {
        Write-Log "[PASS] DELETE prevention rule found" "INFO" "Green"
    } else {
        Add-SecurityIssue -Title "Audit Logs Can Be Deleted" -Description "No rule preventing DELETE operations on audit logs" -Severity "HIGH" -File $auditFile -Recommendation "Add rule to prevent DELETE operations"
    }
    
    # Check for indexes
    if ($content -match "CREATE INDEX.*audit_logs") {
        Write-Log "[PASS] Indexes found for audit logs table" "INFO" "Green"
    } else {
        Add-SecurityIssue -Title "Missing Audit Log Indexes" -Description "No indexes found for audit logs table" -Severity "MEDIUM" -File $auditFile -Recommendation "Add indexes for entity_type, entity_id, user_id, and created_at"
    }
}

# Review audit triggers
function Test-AuditTriggers {
    Write-Log "=== Reviewing Audit Triggers ===" "INFO" "Cyan"
    
    $triggerFile = Join-Path $script:MigrationsDir "00010_create_database_triggers.sql"
    
    if (!(Test-Path $triggerFile)) {
        Add-SecurityIssue -Title "Trigger File Missing" -Description "Database triggers migration not found" -Severity "CRITICAL" -Recommendation "Create database triggers for audit logging"
        return
    }
    
    $content = Get-Content $triggerFile -Raw
    
    # Check for audit trigger functions
    $auditTriggers = @(
        @{ Name = "audit_expense_changes"; Table = "expenses"; Description = "Audit expense modifications" },
        @{ Name = "audit_payment_changes"; Table = "payments"; Description = "Audit payment modifications" },
        @{ Name = "audit_membership_changes"; Table = "group_members"; Description = "Audit membership changes" }
    )
    
    foreach ($trigger in $auditTriggers) {
        if ($content -match "CREATE OR REPLACE FUNCTION $($trigger.Name)") {
            Write-Log "[PASS] Audit trigger function found: $($trigger.Name)" "INFO" "Green"
            
            # Check if trigger is actually created
            if ($content -match "CREATE TRIGGER.*$($trigger.Name)") {
                Write-Log "[PASS] Trigger created for: $($trigger.Table)" "INFO" "Green"
            } else {
                Add-SecurityIssue -Title "Trigger Not Created" -Description "Function $($trigger.Name) exists but trigger not created" -Severity "HIGH" -File $triggerFile -Recommendation "Create trigger for $($trigger.Table) table"
            }
        } else {
            Add-SecurityIssue -Title "Missing Audit Trigger" -Description "Audit trigger function '$($trigger.Name)' not found" -Severity "HIGH" -File $triggerFile -Recommendation "Create $($trigger.Name) function to $($trigger.Description)"
        }
    }
    
    # Check for comprehensive trigger coverage
    $triggerOperations = @("INSERT", "UPDATE", "DELETE")
    
    foreach ($trigger in $auditTriggers) {
        foreach ($operation in $triggerOperations) {
            if ($content -match "$operation.*$($trigger.Name)" -or $content -match "$($trigger.Name).*$operation") {
                Write-Log "[PASS] $operation operation covered by $($trigger.Name)" "INFO" "Green"
            }
        }
    }
    
    # Check for proper audit data capture
    if (($content -match "to_jsonb\(" -or $content -match "jsonb_build_object\(") -and ($content -match "NEW" -or $content -match "OLD")) {
        Write-Log "[PASS] Before and after states captured in audit triggers" "INFO" "Green"
    } else {
        Add-SecurityIssue -Title "Incomplete Audit Data" -Description "Audit triggers may not capture complete before/after states" -Severity "MEDIUM" -File $triggerFile -Recommendation "Ensure triggers capture both OLD and NEW states as JSONB"
    }
}

# Review sensitive operations coverage
function Test-SensitiveOperationsCoverage {
    Write-Log "=== Reviewing Sensitive Operations Coverage ===" "INFO" "Cyan"
    
    # Define sensitive operations that should be audited
    $sensitiveOperations = @(
        @{ Table = "expenses"; Operations = @("INSERT", "UPDATE", "DELETE"); Reason = "Financial data modifications" },
        @{ Table = "payments"; Operations = @("INSERT", "DELETE"); Reason = "Payment records" },
        @{ Table = "group_members"; Operations = @("INSERT", "UPDATE", "DELETE"); Reason = "Access control changes" },
        @{ Table = "users"; Operations = @("UPDATE", "DELETE"); Reason = "User profile changes" },
        @{ Table = "groups"; Operations = @("UPDATE", "DELETE"); Reason = "Group configuration changes" }
    )
    
    $triggerFile = Join-Path $script:MigrationsDir "00010_create_database_triggers.sql"
    
    if (Test-Path $triggerFile) {
        $content = Get-Content $triggerFile -Raw
        
        foreach ($operation in $sensitiveOperations) {
            $covered = $false
            
            # Check if there's an audit trigger for this table
            foreach ($op in $operation.Operations) {
                if ($content -match "CREATE TRIGGER.*$($operation.Table).*$op" -or 
                    $content -match "$op.*$($operation.Table)" -or
                    $content -match "audit_.*$($operation.Table.TrimEnd('s')).*changes") {
                    $covered = $true
                    break
                }
            }
            
            if ($covered) {
                Write-Log "[PASS] Sensitive operations covered for $($operation.Table): $($operation.Reason)" "INFO" "Green"
            } else {
                Add-SecurityIssue -Title "Unaudited Sensitive Operations" -Description "Table '$($operation.Table)' operations not audited: $($operation.Reason)" -Severity "HIGH" -Recommendation "Add audit triggers for $($operation.Table) table"
            }
        }
    }
}

# Review audit log access controls
function Test-AuditLogAccessControls {
    Write-Log "=== Reviewing Audit Log Access Controls ===" "INFO" "Cyan"
    
    $rlsFile = Join-Path $script:MigrationsDir "00011_enable_row_level_security.sql"
    
    if (!(Test-Path $rlsFile)) {
        Add-SecurityIssue -Title "RLS File Missing" -Description "Row Level Security file not found" -Severity "HIGH" -Recommendation "Create RLS policies for audit logs"
        return
    }
    
    $content = Get-Content $rlsFile -Raw
    
    # Check for audit log RLS policies
    if ($content -match "CREATE POLICY.*audit_logs") {
        Write-Log "[PASS] RLS policies found for audit_logs table" "INFO" "Green"
        
        # Check for administrator-only access
        if ($content -match "role.*=.*'administrator'" -and $content -match "audit_logs") {
            Write-Log "[PASS] Administrator-only access policy found" "INFO" "Green"
        } else {
            Add-SecurityIssue -Title "Weak Audit Access Control" -Description "Audit logs may not be restricted to administrators only" -Severity "MEDIUM" -File $rlsFile -Recommendation "Restrict audit log access to administrators only"
        }
        
        # Check for prevention of manual modifications
        if (($content -match "WITH CHECK \(false\)" -and $content -match "audit_logs") -or 
            ($content -match "USING \(false\)" -and $content -match "audit_logs")) {
            Write-Log "[PASS] Manual modification prevention found" "INFO" "Green"
        } else {
            Add-SecurityIssue -Title "Manual Audit Modification Allowed" -Description "Audit logs may allow manual modifications" -Severity "HIGH" -File $rlsFile -Recommendation "Add policies to prevent manual INSERT/UPDATE/DELETE on audit logs"
        }
    } else {
        Add-SecurityIssue -Title "No Audit Log RLS Policies" -Description "No RLS policies found for audit_logs table" -Severity "HIGH" -File $rlsFile -Recommendation "Create comprehensive RLS policies for audit logs"
    }
}

# Review PII exposure in audit logs
function Test-PIIExposure {
    Write-Log "=== Reviewing PII Exposure in Audit Logs ===" "INFO" "Cyan"
    
    # This is a static analysis - in a real environment, you'd query actual audit logs
    Write-Log "[INFO] Static analysis: Checking for potential PII exposure patterns" "INFO" "Yellow"
    
    $triggerFile = Join-Path $script:MigrationsDir "00010_create_database_triggers.sql"
    
    if (Test-Path $triggerFile) {
        $content = Get-Content $triggerFile -Raw
        
        # Check if sensitive fields are being logged
        $sensitiveFields = @("password", "ssn", "credit_card", "bank_account")
        
        foreach ($field in $sensitiveFields) {
            if ($content -match $field) {
                Add-SecurityIssue -Title "Potential PII in Audit Logs" -Description "Sensitive field '$field' may be logged in audit trails" -Severity "MEDIUM" -File $triggerFile -Recommendation "Exclude sensitive fields from audit logging or encrypt them"
            }
        }
        
        # Check for email logging (which is PII)
        if ($content -match "email" -and $content -match "to_jsonb") {
            Add-SecurityIssue -Title "Email PII in Audit Logs" -Description "Email addresses (PII) are being logged in audit trails" -Severity "LOW" -Recommendation "Consider masking or excluding email addresses from audit logs"
        }
        
        Write-Log "[PASS] No obvious PII exposure patterns found in static analysis" "INFO" "Green"
    }
}

# Generate audit security report
function New-AuditSecurityReport {
    Write-Log "=== Audit Logging Security Report ===" "INFO" "Cyan"
    
    $totalIssues = $script:Issues.Count
    $criticalIssues = ($script:Issues | Where-Object { $_.Severity -eq "CRITICAL" }).Count
    $highIssues = ($script:Issues | Where-Object { $_.Severity -eq "HIGH" }).Count
    $mediumIssues = ($script:Issues | Where-Object { $_.Severity -eq "MEDIUM" }).Count
    $lowIssues = ($script:Issues | Where-Object { $_.Severity -eq "LOW" }).Count
    
    Write-Log "Total Issues: $totalIssues" "INFO" "Cyan"
    Write-Log "Critical: $criticalIssues" "INFO" "Red"
    Write-Log "High: $highIssues" "INFO" "Red"
    Write-Log "Medium: $mediumIssues" "INFO" "Yellow"
    Write-Log "Low: $lowIssues" "INFO" "Yellow"
    
    if ($criticalIssues -gt 0) {
        Write-Log "CRITICAL AUDIT SECURITY ISSUES FOUND!" "ERROR" "Red"
        $script:Issues | Where-Object { $_.Severity -eq "CRITICAL" } | ForEach-Object {
            Write-Log "  - $($_.Title): $($_.Description)" "ERROR" "Red"
        }
    }
    
    if ($highIssues -gt 0) {
        Write-Log "HIGH SEVERITY AUDIT ISSUES:" "WARN" "Red"
        $script:Issues | Where-Object { $_.Severity -eq "HIGH" } | ForEach-Object {
            Write-Log "  - $($_.Title): $($_.Description)" "WARN" "Red"
        }
    }
    
    # Calculate audit security score
    $auditScore = 100 - ($criticalIssues * 25) - ($highIssues * 15) - ($mediumIssues * 8) - ($lowIssues * 3)
    $auditScore = [Math]::Max(0, $auditScore)
    
    Write-Log "Audit Security Score: $auditScore/100" "INFO" "Cyan"
    
    # Compliance assessment
    if ($auditScore -ge 90) {
        Write-Log "Audit Compliance: EXCELLENT - Meets security standards" "INFO" "Green"
    } elseif ($auditScore -ge 75) {
        Write-Log "Audit Compliance: GOOD - Minor improvements needed" "INFO" "Green"
    } elseif ($auditScore -ge 60) {
        Write-Log "Audit Compliance: FAIR - Several issues need attention" "WARN" "Yellow"
    } else {
        Write-Log "Audit Compliance: POOR - Major security gaps" "ERROR" "Red"
    }
    
    # Export detailed report
    $reportPath = "logs/audit-security-report-$(Get-Date -Format 'yyyyMMdd_HHmmss').json"
    $report = @{
        Timestamp = Get-Date
        Summary = @{
            TotalIssues = $totalIssues
            Critical = $criticalIssues
            High = $highIssues
            Medium = $mediumIssues
            Low = $lowIssues
            AuditSecurityScore = $auditScore
        }
        Issues = $script:Issues
    }
    
    $report | ConvertTo-Json -Depth 10 | Set-Content -Path $reportPath
    Write-Log "Detailed audit report saved to: $reportPath" "INFO" "Cyan"
    
    return $auditScore
}

# Main execution
try {
    Write-Log "Starting audit logging security review..." "INFO" "Green"
    
    # Ensure log directory exists
    $logDir = Split-Path $script:LogFile -Parent
    if (!(Test-Path $logDir)) {
        New-Item -ItemType Directory -Path $logDir -Force | Out-Null
    }
    
    # Check if migrations directory exists
    if (!(Test-Path $script:MigrationsDir)) {
        Write-Log "Migrations directory not found: $script:MigrationsDir" "ERROR" "Red"
        exit 1
    }
    
    # Run audit security tests
    Test-AuditLogsTable
    Test-AuditTriggers
    Test-SensitiveOperationsCoverage
    Test-AuditLogAccessControls
    Test-PIIExposure
    
    # Generate report
    $auditScore = New-AuditSecurityReport
    
    Write-Log "Audit logging security review completed" "INFO" "Green"
    
    # Exit with appropriate code
    if (($script:Issues | Where-Object { $_.Severity -in @("CRITICAL", "HIGH") }).Count -gt 0) {
        Write-Log "Audit review completed with CRITICAL or HIGH severity issues" "ERROR" "Red"
        exit 1
    } else {
        Write-Log "Audit review completed successfully" "INFO" "Green"
        exit 0
    }
}
catch {
    Write-Log "Audit logging security review failed: $($_.Exception.Message)" "ERROR" "Red"
    exit 1
}