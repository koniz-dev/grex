# Testing Scripts

Scripts for testing, coverage analysis, and quality assurance.

## Scripts

### test_coverage.sh
Comprehensive test coverage analysis with multiple reporting options.

**Usage:**
```bash
# Basic coverage
./test_coverage.sh

# Generate HTML report
./test_coverage.sh --html

# Open HTML report automatically
./test_coverage.sh --open

# Set minimum coverage threshold
./test_coverage.sh --min=85

# Analyze coverage by architectural layer
./test_coverage.sh --analyze

# Skip running tests (use existing coverage)
./test_coverage.sh --no-test --analyze
```

**Features:**
- HTML coverage reports with detailed breakdowns
- Minimum coverage threshold validation
- Architecture layer analysis
- Low coverage file identification
- Cross-platform support

### calculate_layer_coverage.sh
Calculates test coverage by architectural layer (Domain, Data, Presentation, Core).

**Usage:**
```bash
./calculate_layer_coverage.sh [path/to/lcov.info]
```

**Features:**
- Layer-specific coverage calculation
- Clean Architecture compliance checking
- Detailed coverage breakdown
- Integration with CI/CD pipelines

## Coverage Analysis

### Overall Coverage
- Minimum threshold: 80% (configurable)
- Includes all source files except generated code
- Excludes test files and mock files

### Layer Coverage
- **Domain Layer**: Business logic and entities
- **Data Layer**: Repositories and data sources
- **Presentation Layer**: UI components and state management
- **Core Layer**: Shared utilities and configurations

### Coverage Reports

#### Console Output
- Overall coverage percentage
- Total and covered line counts
- Pass/fail status based on threshold

#### HTML Reports
- File-by-file coverage details
- Line-by-line coverage highlighting
- Interactive navigation
- Generated in coverage/html/

#### Layer Analysis
- Coverage percentage per layer
- Identification of low-coverage areas
- Recommendations for improvement

## Integration

### CI/CD Integration
```yaml
# GitHub Actions example
- name: Run tests with coverage
  run: ./scripts/testing/test_coverage.sh --min=80

- name: Upload coverage reports
  uses: codecov/codecov-action@v3
  with:
    file: coverage/lcov.info
```

### Pre-push Hook
The development scripts automatically configure pre-push hooks to run tests before pushing code.

## Troubleshooting

### Common Issues
1. **lcov not found**: Install with rew install lcov (macOS) or pt-get install lcov (Linux)
2. **Permission denied**: Make scripts executable with chmod +x
3. **No coverage data**: Ensure tests are run with --coverage flag
4. **Low coverage**: Use --analyze flag to identify specific areas needing tests
