AC8 - sticky coverage comment posted by the Tests workflow on PR #13
Run: https://github.com/koniz-dev/grex/actions/runs/31117255190 (conclusion: success)
Captured via: gh pr view 13 --json comments

## 📊 Test Coverage Report

**Coverage:** 32.6%
**Status:** ✅ Passing

| Layer | Coverage | Baseline | Target | Status |
|-------|----------|----------|--------|--------|
| **Total** | 32.6% | 32% | 80% | ✅ |
| **Domain** | 53.5% | 53% | 100% | ✅ |
| **Data** | 18.9% | 18% | 90% | ✅ |
| **Presentation** | 37.0% | 36% | 80% | ✅ |
| **Core** | 14.0% | 13% | 80% | ✅ |
| **Shared** | 60.2% | 47% | 80% | ✅ |

<sub>Baseline is the enforced gate and lives in `scripts/linux/testing/coverage_baseline.env`. Target is the long-term goal and is not enforced. 5078 of 15587 lines covered.</sub>

Full HTML report in the [workflow artifacts](https://github.com/koniz-dev/grex/actions/runs/31117255190).
<!-- Sticky Pull Request Comment -->

--- Note on CI vs local drift ---
CI reports total 32.6% over 15587 lines; the local macOS run reported
32.4% over 15685 lines. The instrumented line set differs by platform,
which is exactly why each baseline sits below its measured value.
