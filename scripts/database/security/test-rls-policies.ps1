# RLS Policy Review Script
# This script reviews RLS policies by analyzing migration files and database schema

<#
.SYNOPSIS
    Reviews RLS policies implementation in the Grex database

.DESCRIPTION
    This script analyzes migration files and database schema to verify
    that RLS policies are properly implemented and comprehensive.

.EXAMPLE
    .\rls-policy-review.ps1
    Review all RLS policies

.NOTES
    Author: Grex Development Team
    Date: 2024-01-15
    Version: 1.0
#>

# Configuration
$script:MigrationsDir = "supabase/migrations"
$script:LogFile = "logs/rls-review-$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
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

# Review RLS enablement
function Test-RLSEnablement {
    Write-Log "=== Reviewing RLS Enablement ===" "INFO" "Cyan"
    
    $rlsFile = Join-Path $script:MigrationsDir "00011_enable_row_level_security.sql"
    
    if (Test-Path $rlsFile) {
        $content = Get-Content $rlsFile -Raw
        
        # Expected tables that should have RLS enabled
        $expectedTables = @('users', 'groups', 'group_members', 'expenses', 'expense_participants', 'payments', 'audit_logs')
        
        foreach ($table in $expectedTables) {
            if ($content -match "ALTER TABLE $table ENABLE ROW LEVEL SECURITY") {
                Write-Log "[PASS] RLS enabled for table: $table" "INFO" "Green"
            } else {
                Add-SecurityIssue -Title "RLS Not Enabled" -Description "Table '$table' does not have RLS enabled" -Severity "CRITICAL" -File $rlsFile -Recommendation "Add 'ALTER TABLE $table ENABLE ROW LEVEL SECURITY;'"
            }
        }
    } else {
        Add-SecurityIssue -Title "RLS Migration Missing" -Description "RLS enablement migration file not found" -Severity "CRITICAL" -Recommendation "Create migration to enable RLS on all tables"
    }
}

# Review RLS policies
function Test-RLSPolicies {
    Write-Log "=== Reviewing RLS Policies ===" "INFO" "Cyan"
    
    # Find RLS policy files
    $policyFiles = Get-ChildItem -Path $script:MigrationsDir -Filter "*row_level_security*" -Name
    
    if ($policyFiles.Count -eq 0) {
        Add-SecurityIssue -Title "No RLS Policy Files" -Description "No RLS policy migration files found" -Severity "CRITICAL" -Recommendation "Create comprehensive RLS policies for all tables"
        return
    }
    
    foreach ($file in $policyFiles) {
        $filePath = Join-Path $script:MigrationsDir $file
        $content = Get-Content $filePath -Raw
        
        Write-Log "Reviewing RLS policies in: $file" "INFO" "Yellow"
        
        # Check for comprehensive policies
        $expectedPolicies = @{
            'users' = @('users_view_own_profile', 'users_update_own_profile', 'users_view_group_members', 'users_insert_own_profile')
            'groups' = @('groups_view_member_groups', 'groups_create_own_groups', 'groups_admin_update', 'groups_admin_delete')
            'group_members' = @('group_members_view_own_groups', 'group_members_admin_add', 'group_members_admin_update_roles', 'group_members_admin_remove', 'group_members_self_leave')
            'expenses' = @('expenses_view_group_expenses', 'expenses_editor_create', 'expenses_editor_update_own', 'expenses_admin_update_any', 'expenses_admin_delete')
            'expense_participants' = @('expense_participants_view_group_expenses', 'expense_participants_editor_add_to_own', 'expense_participants_admin_add_any', 'expense_participants_editor_update_own', 'expense_participants_admin_update_any', 'expense_participants_editor_delete_own', 'expense_participants_admin_delete_any')
            'payments' = @('payments_view_group_payments', 'payments_editor_create_as_payer', 'payments_delete_own_payments', 'payments_admin_delete_any')
            'audit_logs' = @('audit_logs_admin_view_group_logs', 'audit_logs_no_manual_insert', 'audit_logs_no_updates', 'audit_logs_no_deletes')
        }
        
        foreach ($table in $expectedPolicies.Keys) {
            foreach ($policy in $expectedPolicies[$table]) {
                if ($content -match "CREATE POLICY $policy") {
                    Write-Log "[PASS] Policy found: $policy" "INFO" "Green"
                } else {
                    Add-SecurityIssue -Title "Missing RLS Policy" -Description "Policy '$policy' not found for table '$table'" -Severity "HIGH" -File $file -Recommendation "Implement missing RLS policy"
                }
            }
        }
        
        # Check for dangerous patterns
        $dangerousPatterns = @(
            @{ Pattern = "USING \(true\)"; Issue = "Always-true policy condition" },
            @{ Pattern = "USING \(1=1\)"; Issue = "Always-true policy condition" },
            @{ Pattern = "WITH CHECK \(true\)"; Issue = "Always-true check condition" },
            @{ Pattern = "USING \(\)"; Issue = "Empty policy condition" }
        )
        
        foreach ($pattern in $dangerousPatterns) {
            if ($content -match $pattern.Pattern) {
                Add-SecurityIssue -Title "Dangerous RLS Policy" -Description $pattern.Issue -Severity "HIGH" -File $file -Recommendation "Review and tighten policy conditions"
            }
        }
        
        # Check for proper permission functions
        if ($content -notmatch "check_user_permission") {
            Add-SecurityIssue -Title "Missing Permission Checks" -Description "RLS policies should use check_user_permission function" -Severity "MEDIUM" -File $file -Recommendation "Use check_user_permission function for role-based access"
        }
    }
}

# Review audit log security
function Test-AuditLogSecurity {
    Write-Log "=== Reviewing Audit Log Security ===" "INFO" "Cyan"
    
    $auditFile = Join-Path $script:MigrationsDir "00008_create_audit_logs_table.sql"
    
    if (Test-Path $auditFile) {
        $content = Get-Content $auditFile -Raw
        
        # Check for immutability rules
        if ($content -match "CREATE RULE.*audit_logs_no_update.*DO INSTEAD NOTHING") {
            Write-Log "[PASS] Audit log UPDATE prevention rule found" "INFO" "Green"
        } else {
            Add-SecurityIssue -Title "Audit Log Mutability" -Description "Audit logs can be updated" -Severity "HIGH" -File $auditFile -Recommendation "Add rule to prevent UPDATE operations on audit_logs"
        }
        
        if ($content -match "CREATE RULE.*audit_logs_no_delete.*DO INSTEAD NOTHING") {
            Write-Log "[PASS] Audit log DELETE prevention rule found" "INFO" "Green"
        } else {
            Add-SecurityIssue -Title "Audit Log Deletion" -Description "Audit logs can be deleted" -Severity "HIGH" -File $auditFile -Recommendation "Add rule to prevent DELETE operations on audit_logs"
        }
    } else {
        Add-SecurityIssue -Title "Audit Log Table Missing" -Description "Audit logs table migration not found" -Severity "HIGH" -Recommendation "Create audit_logs table with proper security"
    }
}

# Review function security
function Test-FunctionSecurity {
    Write-Log "=== Reviewing Function Security ===" "INFO" "Cyan"
    
    $functionFile = Join-Path $script:MigrationsDir "00009_create_database_functions.sql"
    
    if (Test-Path $functionFile) {
        $content = Get-Content $functionFile -Raw
        
        # Check for input validation in functions
        $functions = @('calculate_group_balances', 'validate_expense_split', 'generate_settlement_plan', 'check_user_permission')
        
        foreach ($func in $functions) {
            if ($content -match "CREATE OR REPLACE FUNCTION $func") {
                Write-Log "[PASS] Function found: $func" "INFO" "Green"
                
                # Check for basic input validation
                $funcPattern = "CREATE OR REPLACE FUNCTION $func"
                $funcContent = ($content -split $funcPattern)[1]
                
                if ($funcContent -notmatch "IF.*IS NULL" -and $funcContent -notmatch "COALESCE") {
                    Add-SecurityIssue -Title "Missing Input Validation" -Description "Function '$func' may lack proper input validation" -Severity "MEDIUM" -File "00009_create_database_functions.sql" -Recommendation "Add input validation to prevent null pointer errors"
                }
            } else {
                Add-SecurityIssue -Title "Missing Security Function" -Description "Function '$func' not found" -Severity "HIGH" -File $functionFile -Recommendation "Implement required security function"
            }
        }
        
        # Check for SECURITY DEFINER usage
        if ($content -match "SECURITY DEFINER") {
            Add-SecurityIssue -Title "SECURITY DEFINER Usage" -Description "Functions using SECURITY DEFINER require careful review" -Severity "MEDIUM" -File $functionFile -Recommendation "Review SECURITY DEFINER functions for privilege escalation risks"
        }
    } else {
        Add-SecurityIssue -Title "Function File Missing" -Description "Database functions migration not found" -Severity "HIGH" -Recommendation "Create database functions with proper security"
    }
}

# Review trigger security
function Test-TriggerSecurity {
    Write-Log "=== Reviewing Trigger Security ===" "INFO" "Cyan"
    
    $triggerFile = Join-Path $script:MigrationsDir "00010_create_database_triggers.sql"
    
    if (Test-Path $triggerFile) {
        $content = Get-Content $triggerFile -Raw
        
        # Check for audit triggers
        $auditTriggers = @('audit_expense_changes', 'audit_payment_changes', 'audit_membership_changes')
        
        foreach ($trigger in $auditTriggers) {
            if ($content -match "CREATE TRIGGER.*$trigger") {
                Write-Log "[PASS] Audit trigger found: $trigger" "INFO" "Green"
            } else {
                Add-SecurityIssue -Title "Missing Audit Trigger" -Description "Audit trigger '$trigger' not found" -Severity "HIGH" -File $triggerFile -Recommendation "Implement audit trigger for complete audit trail"
            }
        }
        
        # Check for timestamp triggers
        if ($content -match "set_timestamps") {
            Write-Log "[PASS] Timestamp trigger found" "INFO" "Green"
        } else {
            Add-SecurityIssue -Title "Missing Timestamp Trigger" -Description "Automatic timestamp trigger not found" -Severity "MEDIUM" -File $triggerFile -Recommendation "Implement automatic timestamp management"
        }
    } else {
        Add-SecurityIssue -Title "Trigger File Missing" -Description "Database triggers migration not found" -Severity "HIGH" -Recommendation "Create database triggers for audit and timestamp management"
    }
}

# Review data validation
function Test-DataValidation {
    Write-Log "=== Reviewing Data Validation ===" "INFO" "Cyan"
    
    # Check table creation files for constraints
    $tableFiles = Get-ChildItem -Path $script:MigrationsDir -Filter "*create_*_table.sql" -Name
    
    foreach ($file in $tableFiles) {
        $filePath = Join-Path $script:MigrationsDir $file
        $content = Get-Content $filePath -Raw
        
        # Check for essential constraints
        if ($content -match "CHECK.*amount.*>.*0") {
            Write-Log "[PASS] Positive amount constraint found in $file" "INFO" "Green"
        } elseif ($file -match "(expenses|payments)") {
            Add-SecurityIssue -Title "Missing Amount Validation" -Description "No positive amount constraint in $file" -Severity "MEDIUM" -File $file -Recommendation "Add CHECK constraint for positive amounts"
        }
        
        # Check for email validation
        if ($content -match "CHECK.*email.*~") {
            Write-Log "[PASS] Email format validation found in $file" "INFO" "Green"
        } elseif ($file -match "users") {
            Add-SecurityIssue -Title "Missing Email Validation" -Description "No email format validation in $file" -Severity "MEDIUM" -File $file -Recommendation "Add CHECK constraint for email format validation"
        }
        
        # Check for foreign key constraints
        if ($content -match "REFERENCES.*ON DELETE") {
            Write-Log "[PASS] Foreign key constraints with cascade rules found in $file" "INFO" "Green"
        } else {
            Add-SecurityIssue -Title "Missing Cascade Rules" -Description "Foreign keys without cascade rules in $file" -Severity "LOW" -File $file -Recommendation "Add appropriate ON DELETE cascade rules"
        }
    }
}

# Generate security report
function New-SecurityReport {
    Write-Log "=== Security Review Report ===" "INFO" "Cyan"
    
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
        Write-Log "CRITICAL SECURITY ISSUES FOUND!" "ERROR" "Red"
        $script:Issues | Where-Object { $_.Severity -eq "CRITICAL" } | ForEach-Object {
            Write-Log "  - $($_.Title): $($_.Description)" "ERROR" "Red"
        }
    }
    
    if ($highIssues -gt 0) {
        Write-Log "HIGH SEVERITY ISSUES:" "WARN" "Red"
        $script:Issues | Where-Object { $_.Severity -eq "HIGH" } | ForEach-Object {
            Write-Log "  - $($_.Title): $($_.Description)" "WARN" "Red"
        }
    }
    
    # Calculate security score (100 - weighted issues)
    $securityScore = 100 - ($criticalIssues * 20) - ($highIssues * 10) - ($mediumIssues * 5) - ($lowIssues * 2)
    $securityScore = [Math]::Max(0, $securityScore)
    
    Write-Log "Security Score: $securityScore/100" "INFO" "Cyan"
    
    # Export detailed report
    $reportPath = "logs/rls-security-report-$(Get-Date -Format 'yyyyMMdd_HHmmss').json"
    $report = @{
        Timestamp = Get-Date
        Summary = @{
            TotalIssues = $totalIssues
            Critical = $criticalIssues
            High = $highIssues
            Medium = $mediumIssues
            Low = $lowIssues
            SecurityScore = $securityScore
        }
        Issues = $script:Issues
    }
    
    $report | ConvertTo-Json -Depth 10 | Set-Content -Path $reportPath
    Write-Log "Detailed report saved to: $reportPath" "INFO" "Cyan"
    
    return $securityScore
}

# Main execution
try {
    Write-Log "Starting RLS policy security review..." "INFO" "Green"
    
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
    
    # Run security tests
    Test-RLSEnablement
    Test-RLSPolicies
    Test-AuditLogSecurity
    Test-FunctionSecurity
    Test-TriggerSecurity
    Test-DataValidation
    
    # Generate report
    $securityScore = New-SecurityReport
    
    Write-Log "RLS policy security review completed" "INFO" "Green"
    
    # Exit with appropriate code
    if (($script:Issues | Where-Object { $_.Severity -in @("CRITICAL", "HIGH") }).Count -gt 0) {
        Write-Log "Security review completed with CRITICAL or HIGH severity issues" "ERROR" "Red"
        exit 1
    } else {
        Write-Log "Security review completed successfully" "INFO" "Green"
        exit 0
    }
}
catch {
    Write-Log "RLS policy security review failed: $($_.Exception.Message)" "ERROR" "Red"
    exit 1
}