# Simple RLS Policy Review Script
# This script provides a quick review of RLS policies implementation

<#
.SYNOPSIS
    Simple review of RLS policies in the Grex database

.DESCRIPTION
    This script provides a quick assessment of RLS implementation
    by counting policies and checking for basic security patterns.

.EXAMPLE
    .\simple-rls-review.ps1
    Run simple RLS review

.NOTES
    Author: Grex Development Team
    Date: 2024-01-15
    Version: 1.0
#>

# Configuration
$script:MigrationsDir = "supabase/migrations"
$script:LogFile = "logs/simple-rls-review-$(Get-Date -Format 'yyyyMMdd_HHmmss').log"

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

# Main execution
try {
    Write-Log "Starting simple RLS policy review..." "INFO" "Green"
    
    # Ensure log directory exists
    $logDir = Split-Path $script:LogFile -Parent
    if (!(Test-Path $logDir)) {
        New-Item -ItemType Directory -Path $logDir -Force | Out-Null
    }
    
    # Check RLS enablement file
    $rlsFile = Join-Path $script:MigrationsDir "00011_enable_row_level_security.sql"
    
    if (!(Test-Path $rlsFile)) {
        Write-Log "RLS file not found: $rlsFile" "ERROR" "Red"
        exit 1
    }
    
    $content = Get-Content $rlsFile -Raw
    
    Write-Log "=== RLS Implementation Review ===" "INFO" "Cyan"
    
    # Count RLS enablement
    $rlsEnabled = ($content | Select-String "ALTER TABLE .* ENABLE ROW LEVEL SECURITY" -AllMatches).Matches.Count
    Write-Log "Tables with RLS enabled: $rlsEnabled" "INFO" "Green"
    
    # Count policies
    $totalPolicies = ($content | Select-String "CREATE POLICY" -AllMatches).Matches.Count
    Write-Log "Total RLS policies: $totalPolicies" "INFO" "Green"
    
    # Count policies by table
    $tables = @('users', 'groups', 'group_members', 'expenses', 'expense_participants', 'payments', 'audit_logs')
    
    foreach ($table in $tables) {
        $tablePolicies = ($content | Select-String "CREATE POLICY.*ON $table" -AllMatches).Matches.Count
        Write-Log "Policies for $table table: $tablePolicies" "INFO" "Cyan"
    }
    
    # Check for security patterns
    Write-Log "=== Security Pattern Analysis ===" "INFO" "Cyan"
    
    # Check for auth.uid() usage
    $authUidUsage = ($content | Select-String "auth\.uid\(\)" -AllMatches).Matches.Count
    Write-Log "Policies using auth.uid(): $authUidUsage" "INFO" "Green"
    
    # Check for role-based access
    $roleBasedPolicies = ($content | Select-String "role.*=" -AllMatches).Matches.Count
    Write-Log "Role-based policy conditions: $roleBasedPolicies" "INFO" "Green"
    
    # Check for dangerous patterns
    $dangerousPatterns = @(
        @{ Pattern = "USING \(true\)"; Name = "Always-true conditions" },
        @{ Pattern = "WITH CHECK \(true\)"; Name = "Always-true check conditions" },
        @{ Pattern = "USING \(1=1\)"; Name = "Always-true numeric conditions" }
    )
    
    $dangerousFound = 0
    foreach ($pattern in $dangerousPatterns) {
        $matches = ($content | Select-String $pattern.Pattern -AllMatches).Matches.Count
        if ($matches -gt 0) {
            Write-Log "WARNING: Found $matches instances of $($pattern.Name)" "WARN" "Yellow"
            $dangerousFound += $matches
        }
    }
    
    if ($dangerousFound -eq 0) {
        Write-Log "No dangerous policy patterns found" "INFO" "Green"
    }
    
    # Check for audit log protection
    $auditProtection = ($content | Select-String "audit_logs.*false" -AllMatches).Matches.Count
    Write-Log "Audit log protection policies: $auditProtection" "INFO" "Green"
    
    # Overall assessment
    Write-Log "=== Overall Assessment ===" "INFO" "Cyan"
    
    $score = 0
    $maxScore = 100
    
    # Scoring criteria
    if ($rlsEnabled -ge 7) { $score += 20 } # All tables have RLS
    if ($totalPolicies -ge 25) { $score += 30 } # Comprehensive policies
    if ($authUidUsage -ge 15) { $score += 20 } # Good auth usage
    if ($roleBasedPolicies -ge 10) { $score += 15 } # Role-based access
    if ($auditProtection -ge 3) { $score += 10 } # Audit protection
    if ($dangerousFound -eq 0) { $score += 5 } # No dangerous patterns
    
    Write-Log "Security Score: $score/$maxScore" "INFO" "Cyan"
    
    if ($score -ge 80) {
        Write-Log "RLS implementation: EXCELLENT" "INFO" "Green"
    } elseif ($score -ge 60) {
        Write-Log "RLS implementation: GOOD" "INFO" "Green"
    } elseif ($score -ge 40) {
        Write-Log "RLS implementation: FAIR - needs improvement" "WARN" "Yellow"
    } else {
        Write-Log "RLS implementation: POOR - requires attention" "ERROR" "Red"
    }
    
    # Recommendations
    Write-Log "=== Recommendations ===" "INFO" "Cyan"
    
    if ($rlsEnabled -lt 7) {
        Write-Log "- Enable RLS on all tables" "WARN" "Yellow"
    }
    
    if ($totalPolicies -lt 25) {
        Write-Log "- Add more comprehensive RLS policies" "WARN" "Yellow"
    }
    
    if ($dangerousFound -gt 0) {
        Write-Log "- Review and tighten overly permissive policies" "ERROR" "Red"
    }
    
    if ($auditProtection -lt 3) {
        Write-Log "- Strengthen audit log protection" "WARN" "Yellow"
    }
    
    Write-Log "Simple RLS review completed successfully" "INFO" "Green"
    
    # Export summary
    $summary = @{
        Timestamp = Get-Date
        TablesWithRLS = $rlsEnabled
        TotalPolicies = $totalPolicies
        AuthUidUsage = $authUidUsage
        RoleBasedPolicies = $roleBasedPolicies
        DangerousPatterns = $dangerousFound
        AuditProtection = $auditProtection
        SecurityScore = $score
        MaxScore = $maxScore
    }
    
    $reportPath = "logs/simple-rls-summary-$(Get-Date -Format 'yyyyMMdd_HHmmss').json"
    $summary | ConvertTo-Json -Depth 5 | Set-Content -Path $reportPath
    Write-Log "Summary report saved to: $reportPath" "INFO" "Cyan"
    
    exit 0
}
catch {
    Write-Log "Simple RLS review failed: $($_.Exception.Message)" "ERROR" "Red"
    exit 1
}