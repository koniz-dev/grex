# API Key Security Review Script
# This script reviews API key security practices for Supabase integration

<#
.SYNOPSIS
    Reviews API key security in the Grex application

.DESCRIPTION
    This script analyzes API key usage, storage, and security practices
    to ensure proper handling of Supabase API keys and prevent exposure
    of sensitive credentials.

.EXAMPLE
    .\api-key-security-review.ps1
    Run API key security review

.NOTES
    Author: Grex Development Team
    Date: 2024-12-11
    Version: 1.0
#>

# Configuration
$script:ProjectRoot = "."
$script:LogFile = "logs/api-key-security-review-$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
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

# Review environment configuration
function Test-EnvironmentConfiguration {
    Write-Log "=== Reviewing Environment Configuration ===" "INFO" "Cyan"
    
    # Check .env.example file
    $envExampleFile = ".env.example"
    if (Test-Path $envExampleFile) {
        $envContent = Get-Content $envExampleFile -Raw
        
        # Check for proper API key documentation
        if ($envContent -match "SUPABASE_ANON_KEY") {
            Write-Log "[PASS] SUPABASE_ANON_KEY documented in .env.example" "INFO" "Green"
        } else {
            Add-SecurityIssue -Title "Missing ANON_KEY Documentation" -Description "SUPABASE_ANON_KEY not documented in .env.example" -Severity "MEDIUM" -File $envExampleFile -Recommendation "Add SUPABASE_ANON_KEY to environment template"
        }
        
        if ($envContent -match "SUPABASE_SERVICE_ROLE_KEY") {
            Write-Log "[PASS] SUPABASE_SERVICE_ROLE_KEY documented in .env.example" "INFO" "Green"
        } else {
            Add-SecurityIssue -Title "Missing SERVICE_ROLE_KEY Documentation" -Description "SUPABASE_SERVICE_ROLE_KEY not documented in .env.example" -Severity "MEDIUM" -File $envExampleFile -Recommendation "Add SUPABASE_SERVICE_ROLE_KEY to environment template"
        }
        
        # Check for security warnings
        if ($envContent -match "Keep this secret" -or $envContent -match "server-side") {
            Write-Log "[PASS] Security warnings present for service role key" "INFO" "Green"
        } else {
            Add-SecurityIssue -Title "Missing Security Warnings" -Description "No security warnings for service role key" -Severity "MEDIUM" -File $envExampleFile -Recommendation "Add security warnings for sensitive keys"
        }
        
        # Check for client-side safety notes
        if ($envContent -match "safe to use in client-side" -or $envContent -match "client-side access") {
            Write-Log "[PASS] Client-side safety notes present for anon key" "INFO" "Green"
        } else {
            Add-SecurityIssue -Title "Missing Client-Side Safety Notes" -Description "No notes about anon key client-side safety" -Severity "LOW" -File $envExampleFile -Recommendation "Add notes about anon key client-side usage"
        }
        
    } else {
        Add-SecurityIssue -Title "Missing Environment Template" -Description ".env.example file not found" -Severity "HIGH" -Recommendation "Create .env.example with proper API key documentation"
    }
    
    # Check if .env is in .gitignore
    $gitignoreFile = ".gitignore"
    if (Test-Path $gitignoreFile) {
        $gitignoreContent = Get-Content $gitignoreFile -Raw
        if ($gitignoreContent -split "`n" | Where-Object { $_.Trim() -eq ".env" }) {
            Write-Log "[PASS] .env file is properly ignored by git" "INFO" "Green"
        } else {
            Add-SecurityIssue -Title "Environment File Not Ignored" -Description ".env file may not be properly ignored by git" -Severity "CRITICAL" -File $gitignoreFile -Recommendation "Add .env to .gitignore to prevent credential exposure"
        }
    } else {
        Add-SecurityIssue -Title "Missing .gitignore" -Description ".gitignore file not found" -Severity "HIGH" -Recommendation "Create .gitignore and add .env to prevent credential exposure"
    }
}

# Review API key usage in code
function Test-APIKeyUsage {
    Write-Log "=== Reviewing API Key Usage in Code ===" "INFO" "Cyan"
    
    # Search for hardcoded API keys
    $codeFiles = Get-ChildItem -Path "lib" -Recurse -Include "*.dart" -ErrorAction SilentlyContinue
    $hardcodedKeyCount = 0
    
    foreach ($file in $codeFiles) {
        $content = Get-Content $file.FullName -Raw -ErrorAction SilentlyContinue
        
        # Check for hardcoded Supabase keys (full JWT pattern, not placeholders)
        if ($content -match "eyJ[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+" -and $content -notmatch "\.\.\.") {
            $hardcodedKeyCount++
            Add-SecurityIssue -Title "Hardcoded API Key" -Description "Potential hardcoded JWT/API key found in code" -Severity "CRITICAL" -File $file.Name -Recommendation "Use environment variables instead of hardcoded keys"
        }
        
        # Check for proper environment variable usage
        if ($content -match "SUPABASE_.*KEY" -and $content -notmatch "hardcoded") {
            Write-Log "[PASS] Environment variable usage found in $($file.Name)" "INFO" "Green"
        }
    }
    
    if ($hardcodedKeyCount -eq 0) {
        Write-Log "[PASS] No hardcoded API keys found in Dart code" "INFO" "Green"
    }
    
    # Check configuration files
    $configFiles = @("lib/core/config/app_config.dart", "lib/core/config/env_config.dart")
    foreach ($configFile in $configFiles) {
        if (Test-Path $configFile) {
            $content = Get-Content $configFile -Raw
            
            # Check for proper environment variable loading
            if ($content -match "String\.fromEnvironment" -or $content -match "Platform\.environment" -or $content -match "EnvConfig\.get") {
                Write-Log "[PASS] Environment variable loading found in $configFile" "INFO" "Green"
            } else {
                Add-SecurityIssue -Title "Missing Environment Loading" -Description "No environment variable loading found in config" -Severity "MEDIUM" -File $configFile -Recommendation "Use String.fromEnvironment or Platform.environment for API keys"
            }
        }
    }
}

# Review Supabase configuration
function Test-SupabaseConfiguration {
    Write-Log "=== Reviewing Supabase Configuration ===" "INFO" "Cyan"
    
    $configFile = "supabase/config.toml"
    if (Test-Path $configFile) {
        $content = Get-Content $configFile -Raw
        
        # Check for hardcoded secrets
        if ($content -match "secret\s*=\s*['\`"][^'\`"]*['\`"]" -and $content -notmatch "env\(") {
            Add-SecurityIssue -Title "Hardcoded Secrets in Config" -Description "Potential hardcoded secrets in supabase config" -Severity "HIGH" -File $configFile -Recommendation "Use env() function for all secrets"
        } else {
            Write-Log "[PASS] No hardcoded secrets found in Supabase config" "INFO" "Green"
        }
        
        # Check for proper environment variable usage
        if ($content -match "env\([A-Z_]+\)") {
            Write-Log "[PASS] Environment variable usage found in Supabase config" "INFO" "Green"
        }
        
        # Check JWT configuration
        if ($content -match "jwt_expiry\s*=\s*3600") {
            Write-Log "[PASS] JWT expiry set to reasonable value (1 hour)" "INFO" "Green"
        } elseif ($content -match "jwt_expiry\s*=\s*(\d+)") {
            $expiry = [int]($matches[1])
            if ($expiry -gt 86400) { # More than 24 hours
                Add-SecurityIssue -Title "Long JWT Expiry" -Description "JWT expiry set to more than 24 hours" -Severity "MEDIUM" -File $configFile -Recommendation "Consider shorter JWT expiry for better security"
            }
        }
        
        # Check for refresh token rotation
        if ($content -match "enable_refresh_token_rotation\s*=\s*true") {
            Write-Log "[PASS] Refresh token rotation enabled" "INFO" "Green"
        } else {
            Add-SecurityIssue -Title "Refresh Token Rotation Disabled" -Description "Refresh token rotation not enabled" -Severity "MEDIUM" -File $configFile -Recommendation "Enable refresh token rotation for better security"
        }
        
    } else {
        Add-SecurityIssue -Title "Missing Supabase Config" -Description "supabase/config.toml not found" -Severity "HIGH" -Recommendation "Create proper Supabase configuration"
    }
}

# Review documentation and README files
function Test-DocumentationSecurity {
    Write-Log "=== Reviewing Documentation Security ===" "INFO" "Cyan"
    
    $readmeFiles = Get-ChildItem -Path "." -Recurse -Name "README.md" -ErrorAction SilentlyContinue
    $exposedKeyCount = 0
    
    foreach ($readmeFile in $readmeFiles) {
        $content = Get-Content $readmeFile -Raw -ErrorAction SilentlyContinue
        
        # Check for exposed API keys in documentation (full JWT tokens, not placeholders)
        if ($content -match "eyJ[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+" -and $content -notmatch "\.\.\.") {
            $exposedKeyCount++
            Add-SecurityIssue -Title "Exposed API Key in Documentation" -Description "Potential real API key found in README" -Severity "CRITICAL" -File $readmeFile -Recommendation "Replace with placeholder or example key"
        }
        
        # Check for proper placeholder usage
        if ($content -match "your-project-id" -or $content -match "your-anon-key" -or $content -match "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9\.\.\.") {
            Write-Log "[PASS] Proper placeholders used in $readmeFile" "INFO" "Green"
        }
    }
    
    if ($exposedKeyCount -eq 0) {
        Write-Log "[PASS] No exposed API keys found in documentation" "INFO" "Green"
    }
}

# Review key rotation procedures
function Test-KeyRotationProcedures {
    Write-Log "=== Reviewing Key Rotation Procedures ===" "INFO" "Cyan"
    
    # Check for key rotation documentation
    $securityDocs = Get-ChildItem -Path "docs" -Recurse -Include "*security*", "*key*", "*rotation*" -ErrorAction SilentlyContinue
    
    if ($securityDocs.Count -gt 0) {
        Write-Log "[PASS] Security documentation found" "INFO" "Green"
        
        foreach ($doc in $securityDocs) {
            $content = Get-Content $doc.FullName -Raw -ErrorAction SilentlyContinue
            
            if ($content -match "rotation" -or $content -match "rotate") {
                Write-Log "[PASS] Key rotation procedures documented in $($doc.Name)" "INFO" "Green"
            }
        }
    } else {
        Add-SecurityIssue -Title "Missing Key Rotation Documentation" -Description "No key rotation procedures documented" -Severity "MEDIUM" -Recommendation "Document API key rotation procedures"
    }
    
    # Check for automated rotation scripts
    $rotationScripts = Get-ChildItem -Path "scripts" -Recurse -Include "*rotation*", "*rotate*" -ErrorAction SilentlyContinue
    
    if ($rotationScripts.Count -eq 0) {
        Add-SecurityIssue -Title "Missing Rotation Scripts" -Description "No automated key rotation scripts found" -Severity "LOW" -Recommendation "Consider creating automated key rotation scripts"
    } else {
        Write-Log "[PASS] Key rotation scripts found" "INFO" "Green"
    }
}

# Review access patterns and usage
function Test-AccessPatterns {
    Write-Log "=== Reviewing API Key Access Patterns ===" "INFO" "Cyan"
    
    # Check for proper key separation (anon vs service role)
    $dartFiles = Get-ChildItem -Path "lib" -Recurse -Include "*.dart" -ErrorAction SilentlyContinue
    $anonKeyUsage = 0
    $serviceRoleUsage = 0
    
    foreach ($file in $dartFiles) {
        $content = Get-Content $file.FullName -Raw -ErrorAction SilentlyContinue
        
        if ($content -match "SUPABASE_ANON_KEY" -or $content -match "anonKey") {
            $anonKeyUsage++
        }
        
        if ($content -match "SUPABASE_SERVICE_ROLE_KEY" -or $content -match "serviceRoleKey") {
            $serviceRoleUsage++
            
            # Service role key should only be used in server-side contexts
            if ($content -match "client" -or $content -match "frontend") {
                Add-SecurityIssue -Title "Service Role Key in Client Code" -Description "Service role key may be used in client-side code" -Severity "CRITICAL" -File $file.Name -Recommendation "Use service role key only in server-side contexts"
            }
        }
    }
    
    Write-Log "[INFO] Anonymous key usage found in $anonKeyUsage files" "INFO" "Cyan"
    Write-Log "[INFO] Service role key usage found in $serviceRoleUsage files" "INFO" "Cyan"
    
    if ($anonKeyUsage -gt 0) {
        Write-Log "[PASS] Anonymous key usage detected (appropriate for client-side)" "INFO" "Green"
    }
    
    if ($serviceRoleUsage -eq 0) {
        Write-Log "[INFO] No service role key usage detected (may be appropriate)" "INFO" "Cyan"
    }
}

# Generate API key security report
function New-APIKeySecurityReport {
    Write-Log "=== API Key Security Report ===" "INFO" "Cyan"
    
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
        Write-Log "CRITICAL API KEY SECURITY ISSUES FOUND!" "ERROR" "Red"
        $script:Issues | Where-Object { $_.Severity -eq "CRITICAL" } | ForEach-Object {
            Write-Log "  - $($_.Title): $($_.Description)" "ERROR" "Red"
        }
    }
    
    # Calculate API key security score
    $securityScore = 100 - ($criticalIssues * 40) - ($highIssues * 25) - ($mediumIssues * 15) - ($lowIssues * 5)
    $securityScore = [Math]::Max(0, $securityScore)
    
    Write-Log "API Key Security Score: $securityScore/100" "INFO" "Cyan"
    
    # Security assessment
    if ($securityScore -eq 100) {
        Write-Log "API Key Security: EXCELLENT - No issues found" "INFO" "Green"
    } elseif ($securityScore -ge 80) {
        Write-Log "API Key Security: GOOD - Minor issues found" "INFO" "Green"
    } elseif ($securityScore -ge 60) {
        Write-Log "API Key Security: FAIR - Some issues need attention" "WARN" "Yellow"
    } else {
        Write-Log "API Key Security: POOR - Critical issues found" "ERROR" "Red"
    }
    
    # Recommendations
    Write-Log "=== Recommendations ===" "INFO" "Cyan"
    
    if ($criticalIssues -gt 0) {
        Write-Log "- URGENT: Fix critical API key security issues immediately" "ERROR" "Red"
    }
    
    if ($highIssues -gt 0) {
        Write-Log "- HIGH PRIORITY: Address high-severity API key risks" "WARN" "Red"
    }
    
    if ($totalIssues -eq 0) {
        Write-Log "- Continue following API key security best practices" "INFO" "Green"
        Write-Log "- Regular security reviews to maintain security posture" "INFO" "Green"
        Write-Log "- Consider implementing automated key rotation" "INFO" "Green"
        Write-Log "- Monitor API key usage and access patterns" "INFO" "Green"
    }
    
    # Export detailed report
    $reportPath = "logs/api-key-security-report-$(Get-Date -Format 'yyyyMMdd_HHmmss').json"
    $report = @{
        Timestamp = Get-Date
        Summary = @{
            TotalIssues = $totalIssues
            Critical = $criticalIssues
            High = $highIssues
            Medium = $mediumIssues
            Low = $lowIssues
            APIKeySecurityScore = $securityScore
        }
        Issues = $script:Issues
        Recommendations = @(
            "Use environment variables for all API keys",
            "Never commit API keys to version control",
            "Use anon key for client-side, service role key for server-side only",
            "Implement proper key rotation procedures",
            "Monitor API key usage and access patterns",
            "Document security procedures and best practices"
        )
    }
    
    $report | ConvertTo-Json -Depth 10 | Set-Content -Path $reportPath
    Write-Log "Detailed API key security report saved to: $reportPath" "INFO" "Cyan"
    
    return $securityScore
}

# Main execution
try {
    Write-Log "Starting API key security review..." "INFO" "Green"
    
    # Ensure log directory exists
    $logDir = Split-Path $script:LogFile -Parent
    if (!(Test-Path $logDir)) {
        New-Item -ItemType Directory -Path $logDir -Force | Out-Null
    }
    
    # Run API key security tests
    Test-EnvironmentConfiguration
    Test-APIKeyUsage
    Test-SupabaseConfiguration
    Test-DocumentationSecurity
    Test-KeyRotationProcedures
    Test-AccessPatterns
    
    # Generate report
    $securityScore = New-APIKeySecurityReport
    
    Write-Log "API key security review completed" "INFO" "Green"
    
    # Exit with appropriate code
    if (($script:Issues | Where-Object { $_.Severity -in @("CRITICAL", "HIGH") }).Count -gt 0) {
        Write-Log "API key security review completed with CRITICAL or HIGH severity issues" "ERROR" "Red"
        exit 1
    } else {
        Write-Log "API key security review completed successfully" "INFO" "Green"
        exit 0
    }
}
catch {
    Write-Log "API key security review failed: $($_.Exception.Message)" "ERROR" "Red"
    exit 1
}