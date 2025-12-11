# SQL Injection Prevention Review Script
# This script reviews database functions and queries for SQL injection vulnerabilities

<#
.SYNOPSIS
    Reviews SQL injection prevention in the Grex database

.DESCRIPTION
    This script analyzes database functions, triggers, and migration files
    to identify potential SQL injection vulnerabilities and ensure proper
    parameterized query usage.

.EXAMPLE
    .\sql-injection-review.ps1
    Run SQL injection prevention review

.NOTES
    Author: Grex Development Team
    Date: 2024-01-15
    Version: 1.0
#>

# Configuration
$script:MigrationsDir = "supabase/migrations"
$script:LogFile = "logs/sql-injection-review-$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
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

# Review database functions for SQL injection
function Test-DatabaseFunctions {
    Write-Log "=== Reviewing Database Functions for SQL Injection ===" "INFO" "Cyan"
    
    $functionFile = Join-Path $script:MigrationsDir "00009_create_database_functions.sql"
    
    if (!(Test-Path $functionFile)) {
        Add-SecurityIssue -Title "Function File Missing" -Description "Database functions file not found" -Severity "HIGH" -Recommendation "Create database functions file"
        return
    }
    
    $content = Get-Content $functionFile -Raw
    
    # Check for dangerous patterns that could indicate SQL injection vulnerabilities
    $dangerousPatterns = @(
        @{ Pattern = "EXECUTE\s+['`]"; Name = "Dynamic SQL execution with string literals"; Severity = "CRITICAL" },
        @{ Pattern = "EXECUTE\s+\w+\s*\|\|"; Name = "Dynamic SQL with string concatenation"; Severity = "CRITICAL" },
        @{ Pattern = "'\s*\|\|\s*\w+\s*\|\|\s*'"; Name = "String concatenation in SQL"; Severity = "HIGH" },
        @{ Pattern = "format\s*\(.*%s"; Name = "String formatting in SQL"; Severity = "MEDIUM" },
        @{ Pattern = "EXECUTE\s+format"; Name = "Dynamic SQL with format function"; Severity = "MEDIUM" }
    )
    
    $vulnerabilitiesFound = 0
    
    foreach ($pattern in $dangerousPatterns) {
        $matches = [regex]::Matches($content, $pattern.Pattern, [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
        
        if ($matches.Count -gt 0) {
            Add-SecurityIssue -Title "Potential SQL Injection" -Description "$($pattern.Name) found $($matches.Count) times" -Severity $pattern.Severity -File "00009_create_database_functions.sql" -Recommendation "Use parameterized queries instead of dynamic SQL"
            $vulnerabilitiesFound += $matches.Count
        }
    }
    
    if ($vulnerabilitiesFound -eq 0) {
        Write-Log "[PASS] No dangerous SQL patterns found in database functions" "INFO" "Green"
    }
    
    # Check for proper parameter usage
    $functions = @('calculate_group_balances', 'validate_expense_split', 'generate_settlement_plan', 'check_user_permission')
    
    foreach ($func in $functions) {
        if ($content -match "CREATE OR REPLACE FUNCTION $func\s*\([^)]*\)") {
            Write-Log "[PASS] Function with parameters found: $func" "INFO" "Green"
            
            # Extract function content
            $funcStart = $content.IndexOf("CREATE OR REPLACE FUNCTION $func")
            $funcEnd = $content.IndexOf('$$ LANGUAGE plpgsql;', $funcStart)
            
            if ($funcStart -ge 0 -and $funcEnd -gt $funcStart) {
                $funcContent = $content.Substring($funcStart, $funcEnd - $funcStart)
                
                # Check for parameter usage (p_parameter_name pattern)
                if ($funcContent -match "p_\w+") {
                    Write-Log "[PASS] Parameterized queries used in $func" "INFO" "Green"
                } else {
                    Add-SecurityIssue -Title "Non-Parameterized Function" -Description "Function '$func' may not use proper parameters" -Severity "MEDIUM" -File "00009_create_database_functions.sql" -Recommendation "Use parameterized inputs (p_parameter_name pattern)"
                }
            }
        }
    }
}

# Review triggers for SQL injection
function Test-TriggerFunctions {
    Write-Log "=== Reviewing Trigger Functions for SQL Injection ===" "INFO" "Cyan"
    
    $triggerFile = Join-Path $script:MigrationsDir "00010_create_database_triggers.sql"
    
    if (!(Test-Path $triggerFile)) {
        Add-SecurityIssue -Title "Trigger File Missing" -Description "Database triggers file not found" -Severity "HIGH" -Recommendation "Create database triggers file"
        return
    }
    
    $content = Get-Content $triggerFile -Raw
    
    # Check for dangerous patterns in triggers
    $dangerousPatterns = @(
        @{ Pattern = "EXECUTE\s+['`]"; Name = "Dynamic SQL execution"; Severity = "CRITICAL" },
        @{ Pattern = "'\s*\|\|\s*NEW\.\w+\s*\|\|\s*'"; Name = "String concatenation with NEW values"; Severity = "HIGH" },
        @{ Pattern = "'\s*\|\|\s*OLD\.\w+\s*\|\|\s*'"; Name = "String concatenation with OLD values"; Severity = "HIGH" }
    )
    
    $vulnerabilitiesFound = 0
    
    foreach ($pattern in $dangerousPatterns) {
        $matches = [regex]::Matches($content, $pattern.Pattern, [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
        
        if ($matches.Count -gt 0) {
            Add-SecurityIssue -Title "Potential SQL Injection in Triggers" -Description "$($pattern.Name) found $($matches.Count) times" -Severity $pattern.Severity -File "00010_create_database_triggers.sql" -Recommendation "Use safe data handling methods"
            $vulnerabilitiesFound += $matches.Count
        }
    }
    
    if ($vulnerabilitiesFound -eq 0) {
        Write-Log "[PASS] No dangerous SQL patterns found in trigger functions" "INFO" "Green"
    }
    
    # Check for safe JSONB usage
    if ($content -match "jsonb_build_object" -or $content -match "to_jsonb") {
        Write-Log "[PASS] Safe JSONB functions used for data serialization" "INFO" "Green"
    } else {
        Add-SecurityIssue -Title "Unsafe Data Serialization" -Description "Triggers may not use safe JSONB functions" -Severity "MEDIUM" -File "00010_create_database_triggers.sql" -Recommendation "Use jsonb_build_object() or to_jsonb() for safe data serialization"
    }
}

# Review migration files for SQL injection patterns
function Test-MigrationFiles {
    Write-Log "=== Reviewing Migration Files for SQL Injection Patterns ===" "INFO" "Cyan"
    
    $migrationFiles = Get-ChildItem -Path $script:MigrationsDir -Filter "*.sql" -Name
    
    foreach ($file in $migrationFiles) {
        $filePath = Join-Path $script:MigrationsDir $file
        $content = Get-Content $filePath -Raw
        
        # Check for potentially dangerous patterns
        $patterns = @(
            @{ Pattern = "EXECUTE\s+['`]"; Name = "Dynamic SQL execution"; Severity = "CRITICAL" },
            @{ Pattern = "'\s*\+\s*"; Name = "String concatenation (potential)"; Severity = "LOW" },
            @{ Pattern = "CONCAT\s*\(.*'.*\w+.*'"; Name = "String concatenation with variables"; Severity = "MEDIUM" }
        )
        
        foreach ($pattern in $patterns) {
            $matches = [regex]::Matches($content, $pattern.Pattern, [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
            
            if ($matches.Count -gt 0) {
                Add-SecurityIssue -Title "Potential SQL Injection Pattern" -Description "$($pattern.Name) found in $file" -Severity $pattern.Severity -File $file -Recommendation "Review and ensure safe SQL practices"
            }
        }
    }
    
    Write-Log "[PASS] Migration files reviewed for SQL injection patterns" "INFO" "Green"
}

# Review input validation
function Test-InputValidation {
    Write-Log "=== Reviewing Input Validation ===" "INFO" "Cyan"
    
    # Check constraint-based validation
    $tableFiles = Get-ChildItem -Path $script:MigrationsDir -Filter "*create_*_table.sql" -Name
    
    $validationCount = 0
    
    foreach ($file in $tableFiles) {
        $filePath = Join-Path $script:MigrationsDir $file
        $content = Get-Content $filePath -Raw
        
        # Count validation constraints
        $constraints = @(
            "CHECK.*>.*0",           # Positive number checks
            "CHECK.*LENGTH",         # Length checks
            "CHECK.*~",              # Regex pattern checks
            "CHECK.*IN\s*\(",        # Enum-like checks
            "CHECK.*!=",             # Inequality checks
            "NOT NULL"               # Not null constraints
        )
        
        foreach ($constraint in $constraints) {
            $matches = [regex]::Matches($content, $constraint, [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
            $validationCount += $matches.Count
        }
    }
    
    Write-Log "[PASS] Found $validationCount input validation constraints across table files" "INFO" "Green"
    
    if ($validationCount -lt 10) {
        Add-SecurityIssue -Title "Insufficient Input Validation" -Description "Only $validationCount validation constraints found" -Severity "MEDIUM" -Recommendation "Add more comprehensive input validation constraints"
    }
}

# Generate SQL injection prevention report
function New-SQLInjectionReport {
    Write-Log "=== SQL Injection Prevention Report ===" "INFO" "Cyan"
    
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
        Write-Log "CRITICAL SQL INJECTION VULNERABILITIES FOUND!" "ERROR" "Red"
        $script:Issues | Where-Object { $_.Severity -eq "CRITICAL" } | ForEach-Object {
            Write-Log "  - $($_.Title): $($_.Description)" "ERROR" "Red"
        }
    }
    
    # Calculate SQL injection prevention score
    $sqlScore = 100 - ($criticalIssues * 30) - ($highIssues * 20) - ($mediumIssues * 10) - ($lowIssues * 5)
    $sqlScore = [Math]::Max(0, $sqlScore)
    
    Write-Log "SQL Injection Prevention Score: $sqlScore/100" "INFO" "Cyan"
    
    # Security assessment
    if ($sqlScore -eq 100) {
        Write-Log "SQL Injection Prevention: EXCELLENT - No vulnerabilities found" "INFO" "Green"
    } elseif ($sqlScore -ge 80) {
        Write-Log "SQL Injection Prevention: GOOD - Minor issues found" "INFO" "Green"
    } elseif ($sqlScore -ge 60) {
        Write-Log "SQL Injection Prevention: FAIR - Some vulnerabilities need attention" "WARN" "Yellow"
    } else {
        Write-Log "SQL Injection Prevention: POOR - Critical vulnerabilities found" "ERROR" "Red"
    }
    
    # Recommendations
    Write-Log "=== Recommendations ===" "INFO" "Cyan"
    
    if ($criticalIssues -gt 0) {
        Write-Log "- URGENT: Fix critical SQL injection vulnerabilities immediately" "ERROR" "Red"
    }
    
    if ($highIssues -gt 0) {
        Write-Log "- HIGH PRIORITY: Address high-severity SQL injection risks" "WARN" "Red"
    }
    
    if ($totalIssues -eq 0) {
        Write-Log "- Continue using parameterized queries and safe SQL practices" "INFO" "Green"
        Write-Log "- Regular security reviews to maintain security posture" "INFO" "Green"
        Write-Log "- Consider automated SQL injection testing in CI/CD pipeline" "INFO" "Green"
    }
    
    # Export detailed report
    $reportPath = "logs/sql-injection-report-$(Get-Date -Format 'yyyyMMdd_HHmmss').json"
    $report = @{
        Timestamp = Get-Date
        Summary = @{
            TotalIssues = $totalIssues
            Critical = $criticalIssues
            High = $highIssues
            Medium = $mediumIssues
            Low = $lowIssues
            SQLInjectionScore = $sqlScore
        }
        Issues = $script:Issues
        Recommendations = @(
            "Use parameterized queries for all user inputs",
            "Validate and sanitize all input parameters",
            "Use prepared statements in application code",
            "Implement input length limits and format validation",
            "Regular security testing and code reviews"
        )
    }
    
    $report | ConvertTo-Json -Depth 10 | Set-Content -Path $reportPath
    Write-Log "Detailed SQL injection report saved to: $reportPath" "INFO" "Cyan"
    
    return $sqlScore
}

# Main execution
try {
    Write-Log "Starting SQL injection prevention review..." "INFO" "Green"
    
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
    
    # Run SQL injection tests
    Test-DatabaseFunctions
    Test-TriggerFunctions
    Test-MigrationFiles
    Test-InputValidation
    
    # Generate report
    $sqlScore = New-SQLInjectionReport
    
    Write-Log "SQL injection prevention review completed" "INFO" "Green"
    
    # Exit with appropriate code
    if (($script:Issues | Where-Object { $_.Severity -in @("CRITICAL", "HIGH") }).Count -gt 0) {
        Write-Log "SQL injection review completed with CRITICAL or HIGH severity issues" "ERROR" "Red"
        exit 1
    } else {
        Write-Log "SQL injection review completed successfully" "INFO" "Green"
        exit 0
    }
}
catch {
    Write-Log "SQL injection prevention review failed: $($_.Exception.Message)" "ERROR" "Red"
    exit 1
}