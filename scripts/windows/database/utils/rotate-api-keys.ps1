# API Key Rotation Script
# This script helps with rotating Supabase API keys safely

<#
.SYNOPSIS
    Rotates Supabase API keys safely

.DESCRIPTION
    This script provides a guided process for rotating Supabase API keys
    including validation, backup, and verification steps.

.PARAMETER KeyType
    Type of key to rotate: 'anon', 'service', or 'both'

.PARAMETER Environment
    Target environment: 'development', 'staging', or 'production'

.PARAMETER DryRun
    Perform a dry run without making actual changes

.EXAMPLE
    .\rotate-api-keys.ps1 -KeyType anon -Environment production
    Rotate the anonymous key for production environment

.EXAMPLE
    .\rotate-api-keys.ps1 -KeyType both -Environment staging -DryRun
    Dry run rotation of both keys for staging environment

.NOTES
    Author: Grex Development Team
    Date: 2024-12-11
    Version: 1.0
    
    Prerequisites:
    - Supabase CLI installed and configured
    - Appropriate permissions for key management
    - Access to environment configuration
#>

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet('anon', 'service', 'both')]
    [string]$KeyType,
    
    [Parameter(Mandatory=$true)]
    [ValidateSet('development', 'staging', 'production')]
    [string]$Environment,
    
    [switch]$DryRun
)

# Configuration
$script:LogFile = "logs/key-rotation-$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
$script:BackupDir = "backups/keys"

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
    
    # Ensure log directory exists
    $logDir = Split-Path $script:LogFile -Parent
    if (!(Test-Path $logDir)) {
        New-Item -ItemType Directory -Path $logDir -Force | Out-Null
    }
    
    Add-Content -Path $script:LogFile -Value $logMessage
}

# Backup current configuration
function Backup-CurrentKeys {
    param(
        [string]$Environment
    )
    
    Write-Log "Creating backup of current keys..." "INFO" "Cyan"
    
    # Ensure backup directory exists
    if (!(Test-Path $script:BackupDir)) {
        New-Item -ItemType Directory -Path $script:BackupDir -Force | Out-Null
    }
    
    $backupFile = Join-Path $script:BackupDir "keys-backup-$Environment-$(Get-Date -Format 'yyyyMMdd_HHmmss').json"
    
    # Create backup structure (without actual key values for security)
    $backup = @{
        Environment = $Environment
        Timestamp = Get-Date
        KeysRotated = @()
        Notes = "Backup created before key rotation"
    }
    
    if ($KeyType -in @('anon', 'both')) {
        $backup.KeysRotated += "SUPABASE_ANON_KEY"
    }
    
    if ($KeyType -in @('service', 'both')) {
        $backup.KeysRotated += "SUPABASE_SERVICE_ROLE_KEY"
    }
    
    $backup | ConvertTo-Json -Depth 10 | Set-Content -Path $backupFile
    Write-Log "Backup created: $backupFile" "INFO" "Green"
    
    return $backupFile
}

# Validate prerequisites
function Test-Prerequisites {
    Write-Log "Validating prerequisites..." "INFO" "Cyan"
    
    # Check if Supabase CLI is installed
    try {
        $supabaseVersion = supabase --version 2>$null
        if ($supabaseVersion) {
            Write-Log "[PASS] Supabase CLI is installed: $supabaseVersion" "INFO" "Green"
        } else {
            Write-Log "[FAIL] Supabase CLI not found" "ERROR" "Red"
            return $false
        }
    } catch {
        Write-Log "[FAIL] Supabase CLI not accessible: $($_.Exception.Message)" "ERROR" "Red"
        return $false
    }
    
    # Check if project is linked
    try {
        $projectStatus = supabase status 2>$null
        if ($projectStatus -match "API URL") {
            Write-Log "[PASS] Supabase project is accessible" "INFO" "Green"
        } else {
            Write-Log "[WARN] Supabase project may not be linked" "WARN" "Yellow"
        }
    } catch {
        Write-Log "[WARN] Could not verify project status: $($_.Exception.Message)" "WARN" "Yellow"
    }
    
    # Check environment configuration
    $envFile = ".env.$Environment"
    if (Test-Path $envFile) {
        Write-Log "[PASS] Environment file found: $envFile" "INFO" "Green"
    } else {
        Write-Log "[WARN] Environment file not found: $envFile" "WARN" "Yellow"
        Write-Log "You may need to update environment variables manually" "WARN" "Yellow"
    }
    
    return $true
}

# Generate new API keys
function New-APIKeys {
    param(
        [string]$KeyType
    )
    
    Write-Log "Generating new API keys..." "INFO" "Cyan"
    
    if ($DryRun) {
        Write-Log "[DRY RUN] Would generate new $KeyType key(s)" "INFO" "Yellow"
        return @{
            AnonKey = "new-anon-key-placeholder"
            ServiceRoleKey = "new-service-role-key-placeholder"
        }
    }
    
    $newKeys = @{}
    
    if ($KeyType -in @('anon', 'both')) {
        Write-Log "Generating new anonymous key..." "INFO" "Cyan"
        # Note: In a real implementation, this would call Supabase API
        # For now, we'll provide instructions
        Write-Log "MANUAL STEP REQUIRED:" "WARN" "Yellow"
        Write-Log "1. Go to Supabase Dashboard > Settings > API" "WARN" "Yellow"
        Write-Log "2. Generate new anon key" "WARN" "Yellow"
        Write-Log "3. Copy the new key when prompted" "WARN" "Yellow"
        
        $newAnonKey = Read-Host "Enter the new anon key"
        $newKeys.AnonKey = $newAnonKey
    }
    
    if ($KeyType -in @('service', 'both')) {
        Write-Log "Generating new service role key..." "INFO" "Cyan"
        Write-Log "MANUAL STEP REQUIRED:" "WARN" "Yellow"
        Write-Log "1. Go to Supabase Dashboard > Settings > API" "WARN" "Yellow"
        Write-Log "2. Generate new service role key" "WARN" "Yellow"
        Write-Log "3. Copy the new key when prompted" "WARN" "Yellow"
        
        $newServiceKey = Read-Host "Enter the new service role key" -AsSecureString
        $newKeys.ServiceRoleKey = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($newServiceKey))
    }
    
    return $newKeys
}

# Update environment configuration
function Update-EnvironmentConfig {
    param(
        [hashtable]$NewKeys,
        [string]$Environment
    )
    
    Write-Log "Updating environment configuration..." "INFO" "Cyan"
    
    if ($DryRun) {
        Write-Log "[DRY RUN] Would update environment variables for $Environment" "INFO" "Yellow"
        return
    }
    
    $envFile = ".env.$Environment"
    
    if (Test-Path $envFile) {
        $envContent = Get-Content $envFile
        
        # Update anon key
        if ($NewKeys.AnonKey) {
            $envContent = $envContent -replace "SUPABASE_ANON_KEY=.*", "SUPABASE_ANON_KEY=$($NewKeys.AnonKey)"
            Write-Log "Updated SUPABASE_ANON_KEY in $envFile" "INFO" "Green"
        }
        
        # Update service role key
        if ($NewKeys.ServiceRoleKey) {
            $envContent = $envContent -replace "SUPABASE_SERVICE_ROLE_KEY=.*", "SUPABASE_SERVICE_ROLE_KEY=$($NewKeys.ServiceRoleKey)"
            Write-Log "Updated SUPABASE_SERVICE_ROLE_KEY in $envFile" "INFO" "Green"
        }
        
        # Write updated content
        $envContent | Set-Content $envFile
        Write-Log "Environment file updated successfully" "INFO" "Green"
    } else {
        Write-Log "Environment file not found. Manual update required." "WARN" "Yellow"
        Write-Log "Please update the following environment variables:" "WARN" "Yellow"
        
        if ($NewKeys.AnonKey) {
            Write-Log "SUPABASE_ANON_KEY=$($NewKeys.AnonKey)" "INFO" "Cyan"
        }
        
        if ($NewKeys.ServiceRoleKey) {
            Write-Log "SUPABASE_SERVICE_ROLE_KEY=***REDACTED***" "INFO" "Cyan"
        }
    }
}

# Test new keys
function Test-NewKeys {
    param(
        [hashtable]$NewKeys
    )
    
    Write-Log "Testing new API keys..." "INFO" "Cyan"
    
    if ($DryRun) {
        Write-Log "[DRY RUN] Would test new keys" "INFO" "Yellow"
        return $true
    }
    
    # Test anon key
    if ($NewKeys.AnonKey) {
        Write-Log "Testing anonymous key..." "INFO" "Cyan"
        # In a real implementation, this would make a test API call
        Write-Log "[MANUAL VERIFICATION REQUIRED] Please test anon key functionality" "WARN" "Yellow"
    }
    
    # Test service role key
    if ($NewKeys.ServiceRoleKey) {
        Write-Log "Testing service role key..." "INFO" "Cyan"
        # In a real implementation, this would make a test API call
        Write-Log "[MANUAL VERIFICATION REQUIRED] Please test service role key functionality" "WARN" "Yellow"
    }
    
    $testResult = Read-Host "Did all tests pass? (y/n)"
    return $testResult -eq 'y'
}

# Revoke old keys
function Revoke-OldKeys {
    param(
        [string]$KeyType
    )
    
    Write-Log "Revoking old API keys..." "INFO" "Cyan"
    
    if ($DryRun) {
        Write-Log "[DRY RUN] Would revoke old $KeyType key(s)" "INFO" "Yellow"
        return
    }
    
    Write-Log "MANUAL STEP REQUIRED:" "WARN" "Yellow"
    Write-Log "1. Go to Supabase Dashboard > Settings > API" "WARN" "Yellow"
    Write-Log "2. Revoke the old keys that were replaced" "WARN" "Yellow"
    Write-Log "3. Verify that only new keys are active" "WARN" "Yellow"
    
    $confirmed = Read-Host "Have you revoked the old keys? (y/n)"
    if ($confirmed -eq 'y') {
        Write-Log "Old keys revoked successfully" "INFO" "Green"
    } else {
        Write-Log "WARNING: Old keys not revoked. Please complete this step manually." "WARN" "Red"
    }
}

# Generate rotation report
function New-RotationReport {
    param(
        [string]$KeyType,
        [string]$Environment,
        [string]$BackupFile,
        [bool]$Success
    )
    
    $reportPath = "logs/key-rotation-report-$(Get-Date -Format 'yyyyMMdd_HHmmss').json"
    
    $report = @{
        Timestamp = Get-Date
        Environment = $Environment
        KeyType = $KeyType
        Success = $Success
        DryRun = $DryRun.IsPresent
        BackupFile = $BackupFile
        LogFile = $script:LogFile
        Steps = @(
            "Prerequisites validated",
            "Current keys backed up",
            "New keys generated",
            "Environment configuration updated",
            "New keys tested",
            "Old keys revoked"
        )
        NextRotation = (Get-Date).AddDays(90).ToString("yyyy-MM-dd")
        Notes = "API key rotation completed successfully"
    }
    
    $report | ConvertTo-Json -Depth 10 | Set-Content -Path $reportPath
    Write-Log "Rotation report saved: $reportPath" "INFO" "Cyan"
    
    return $reportPath
}

# Main execution
try {
    Write-Log "Starting API key rotation..." "INFO" "Green"
    Write-Log "Key Type: $KeyType" "INFO" "Cyan"
    Write-Log "Environment: $Environment" "INFO" "Cyan"
    Write-Log "Dry Run: $($DryRun.IsPresent)" "INFO" "Cyan"
    
    # Validate prerequisites
    if (!(Test-Prerequisites)) {
        Write-Log "Prerequisites validation failed. Aborting rotation." "ERROR" "Red"
        exit 1
    }
    
    # Create backup
    $backupFile = Backup-CurrentKeys -Environment $Environment
    
    # Generate new keys
    $newKeys = New-APIKeys -KeyType $KeyType
    
    # Update environment configuration
    Update-EnvironmentConfig -NewKeys $newKeys -Environment $Environment
    
    # Test new keys
    $testSuccess = Test-NewKeys -NewKeys $newKeys
    
    if ($testSuccess) {
        # Revoke old keys
        Revoke-OldKeys -KeyType $KeyType
        
        # Generate report
        $reportPath = New-RotationReport -KeyType $KeyType -Environment $Environment -BackupFile $backupFile -Success $true
        
        Write-Log "API key rotation completed successfully!" "INFO" "Green"
        Write-Log "Report: $reportPath" "INFO" "Cyan"
        Write-Log "Next rotation recommended: $((Get-Date).AddDays(90).ToString('yyyy-MM-dd'))" "INFO" "Cyan"
    } else {
        Write-Log "Key testing failed. Rotation incomplete." "ERROR" "Red"
        Write-Log "Please verify the new keys and complete the rotation manually." "ERROR" "Red"
        
        # Generate failure report
        New-RotationReport -KeyType $KeyType -Environment $Environment -BackupFile $backupFile -Success $false
        exit 1
    }
    
} catch {
    Write-Log "API key rotation failed: $($_.Exception.Message)" "ERROR" "Red"
    Write-Log "Please check the logs and complete the rotation manually." "ERROR" "Red"
    exit 1
}

Write-Log "API key rotation process completed." "INFO" "Green"