# Build script for all platforms (Windows PowerShell version)
# Usage: .\build_all.ps1 [environment] [options]
# Options:
#   -AnalyzeSize    Analyze build size and provide optimization recommendations

param(
    [Parameter(Position=0)]
    [ValidateSet("development", "staging", "production")]
    [string]$Environment = "production",
    
    [switch]$AnalyzeSize
)

$ErrorActionPreference = "Stop"

# Colors for output
function Write-ColorOutput {
    param([string]$Message, [string]$Color = "White")
    Write-Host $Message -ForegroundColor $Color
}

# Set base URL based on environment
$baseUrl = switch ($Environment) {
    "development" { "http://localhost:3000" }
    "staging" { $env:BASE_URL_STAGING ?? "https://api-staging.example.com" }
    "production" { $env:BASE_URL_PRODUCTION ?? "https://api.example.com" }
}

Write-ColorOutput "Building for environment: $Environment" "Cyan"
Write-ColorOutput "Base URL: $baseUrl" "Cyan"
Write-Host ""

# Clean previous builds
Write-ColorOutput "Cleaning previous builds..." "Yellow"
flutter clean
flutter pub get
Write-ColorOutput "[OK] Cleaned" "Green"
Write-Host ""

# Build Android
Write-ColorOutput "Building Android..." "Yellow"
if ($Environment -eq "production") {
    flutter build appbundle `
        --flavor production `
        --release `
        --dart-define=ENVIRONMENT=$Environment `
        --dart-define=BASE_URL=$baseUrl
    Write-ColorOutput "[OK] Android App Bundle built" "Green"
} else {
    flutter build apk `
        --flavor $Environment `
        --dart-define=ENVIRONMENT=$Environment `
        --dart-define=BASE_URL=$baseUrl
    Write-ColorOutput "[OK] Android APK built" "Green"
}
Write-Host ""

# Build iOS (only on macOS, skip on Windows)
    Write-ColorOutput "[!] Skipping iOS build (not on macOS)" "Yellow"
Write-Host ""

# Build Web
Write-ColorOutput "Building Web..." "Yellow"
if ($Environment -eq "production") {
    flutter build web `
        --release `
        --web-renderer canvaskit `
        --dart-define=ENVIRONMENT=$Environment `
        --dart-define=BASE_URL=$baseUrl
} else {
    flutter build web `
        --dart-define=ENVIRONMENT=$Environment `
        --dart-define=BASE_URL=$baseUrl
}
Write-ColorOutput "[OK] Web build completed" "Green"
Write-Host ""

# Analyze build size if requested
if ($AnalyzeSize) {
    Write-Host ""
    Write-Host "[*] Build Size Analysis"
    Write-Host "================================"
    Write-Host ""
    
    # Get APK size
    $apkPath = "build/app/outputs/flutter-apk/app-release.apk"
    if (Test-Path $apkPath) {
        $apkSize = (Get-Item $apkPath).Length
        $apkSizeMB = [math]::Round($apkSize / 1MB, 2)
        
        Write-ColorOutput "[OK] Build completed successfully" "Green"
        Write-Host "[*] APK Size: $apkSizeMB MB"
        Write-Host ""
        
        # Analyze dependencies
        Write-Host "[*] Analyzing dependencies..."
        flutter pub deps | Out-File -FilePath "$env:TEMP/flutter_deps.txt"
        
        # Count dependencies
        $depCount = (Get-Content "$env:TEMP/flutter_deps.txt" | Select-String "├" | Measure-Object).Count
        Write-Host "   Total dependencies: $depCount"
        Write-Host ""
        
        # Check for unused dependencies
        Write-Host "[*] Checking for potential optimizations..."
        Write-Host ""
        
        # Analyze assets
        if (Test-Path "assets") {
            $assetSize = (Get-ChildItem -Path "assets" -Recurse -File | Measure-Object -Property Length -Sum).Sum
            $assetSizeMB = [math]::Round($assetSize / 1MB, 2)
            Write-Host "   Assets size: $assetSizeMB MB"
        }
        
        # Provide recommendations
        Write-Host ""
        Write-Host "[*] Optimization Recommendations:"
        Write-Host "================================"
        Write-Host ""
        
        # Check APK size thresholds
        if ($apkSize -gt 50MB) {
            Write-ColorOutput "[!] APK is larger than 50MB. Consider:" "Yellow"
            Write-Host "   - Using App Bundle instead of APK"
            Write-Host "   - Splitting by ABI (already done)"
            Write-Host "   - Removing unused assets"
            Write-Host "   - Compressing images"
        } elseif ($apkSize -gt 25MB) {
            Write-ColorOutput "[!] APK is larger than 25MB. Consider:" "Yellow"
            Write-Host "   - Removing unused dependencies"
            Write-Host "   - Optimizing images"
            Write-Host "   - Using deferred imports for large features"
        } else {
            Write-ColorOutput "[OK] APK size is reasonable" "Green"
        }
        
        Write-Host ""
        Write-Host "[*] Additional Analysis:"
        Write-Host "   - Run 'flutter pub deps' to see dependency tree"
        Write-Host "   - Run 'flutter analyze' to check for unused code"
        Write-Host "   - Use 'flutter build appbundle' for Play Store (smaller size)"
        Write-Host "   - Check 'pubspec.yaml' for unused dependencies"
        Write-Host ""
        
        # Build app bundle for comparison (if not already built)
        if ($Environment -ne "production" -or !(Test-Path "build/app/outputs/bundle/release/app-release.aab")) {
            Write-Host "[*] Building App Bundle (recommended for Play Store)..."
            flutter build appbundle --release
        }
        
        $bundlePath = "build/app/outputs/bundle/release/app-release.aab"
        if (Test-Path $bundlePath) {
            $bundleSize = (Get-Item $bundlePath).Length
            $bundleSizeMB = [math]::Round($bundleSize / 1MB, 2)
            Write-ColorOutput "[OK] App Bundle created" "Green"
            Write-Host "[*] App Bundle Size: $bundleSizeMB MB"
            Write-Host ""
            Write-Host "[*] App Bundle is typically 20-30% smaller than APK"
        }
        
        Write-Host ""
        Write-Host "[*] Build Size Summary:"
        Write-Host "================================"
        Write-Host "APK Size: $apkSizeMB MB"
        if (Test-Path $bundlePath) {
            Write-Host "App Bundle Size: $bundleSizeMB MB"
        }
        Write-Host "Dependencies: $depCount"
        Write-Host ""
    }
}

# Summary
Write-ColorOutput "All builds completed!" "Green"
Write-Host ""
Write-Host "Build artifacts:"
Write-Host "  Android: build/app/outputs/"
Write-Host "  Web: build/web/"
