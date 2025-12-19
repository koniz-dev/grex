# Git Hooks Setup Script for Grex
# This script sets up Git hooks for code quality checks

$ErrorActionPreference = "Stop"

Write-Host "[*] Setting up Git hooks..." -ForegroundColor Cyan

# Create .githooks directory if it doesn't exist
if (-not (Test-Path ".githooks")) {
    New-Item -ItemType Directory -Path ".githooks" | Out-Null
}

# Create pre-commit hook
$preCommitHook = @'
#!/bin/bash

echo "Running pre-commit checks..."

# Check if Flutter is available
if ! command -v flutter &> /dev/null; then
  echo "[!] Flutter not found. Skipping checks."
  exit 0
fi

# Run dart format
echo "[*] Checking code formatting..."
dart format --set-exit-if-changed . || {
  echo "[FAIL] Code formatting check failed!"
  echo "Please run: dart format ."
  exit 1
}

# Run flutter analyze
echo "[*] Running code analysis..."
flutter analyze || {
  echo "[FAIL] Code analysis failed!"
  exit 1
}

echo "[OK] Pre-commit checks passed!"
exit 0
'@

Set-Content -Path ".githooks/pre-commit" -Value $preCommitHook

# Create commit-msg hook
$commitMsgHook = @'
#!/bin/bash

commit_msg=$(cat "$1")

# Skip merge commits
if echo "$commit_msg" | grep -qE "^Merge "; then
  exit 0
fi

# Check Conventional Commits format
if ! echo "$commit_msg" | grep -qE "^(feat|fix|docs|style|refactor|test|chore|perf|ci)(\(.+\))?: .+"; then
  echo "[FAIL] Commit message does not follow Conventional Commits format!"
  echo ""
  echo "Format: <type>(<scope>): <subject>"
  echo ""
  echo "Types:"
  echo "  feat     - New feature"
  echo "  fix      - Bug fix"
  echo "  docs     - Documentation"
  echo "  style    - Code style"
  echo "  refactor - Code refactoring"
  echo "  test     - Tests"
  echo "  chore    - Maintenance"
  echo "  perf     - Performance"
  echo "  ci       - CI/CD"
  echo ""
  echo "Examples:"
  echo "  feat(auth): add login functionality"
  echo "  fix(network): handle timeout errors"
  echo "  docs(readme): update installation guide"
  exit 1
fi

exit 0
'@

Set-Content -Path ".githooks/commit-msg" -Value $commitMsgHook

# Create pre-push hook
$prePushHook = @'
#!/bin/bash

echo "Running pre-push checks..."

# Check if Flutter is available
if ! command -v flutter &> /dev/null; then
  echo "[!] Flutter not found. Skipping tests."
  exit 0
fi

# Run tests
echo "[*] Running tests..."
flutter test || {
  echo "[FAIL] Tests failed!"
  exit 1
}

echo "[OK] Pre-push checks passed!"
exit 0
'@

Set-Content -Path ".githooks/pre-push" -Value $prePushHook

# Install hooks
if (Test-Path ".git/hooks") {
    Copy-Item ".githooks/*" ".git/hooks/" -Force
    
    # Make hooks executable (if using Git Bash or WSL)
    if (Get-Command bash -ErrorAction SilentlyContinue) {
        bash -c "chmod +x .git/hooks/*"
    }
    
    Write-Host "[OK] Git hooks installed successfully!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Hooks installed:"
    Write-Host "  - pre-commit: Format check + code analysis"
    Write-Host "  - commit-msg: Conventional Commits validation"
    Write-Host "  - pre-push: Run tests"
    Write-Host ""
    Write-Host "To skip hooks (when needed):"
    Write-Host "  git commit --no-verify"
    Write-Host "  git push --no-verify"
} else {
    Write-Host "[FAIL] .git/hooks directory not found. Are you in a Git repository?" -ForegroundColor Red
    exit 1
}
