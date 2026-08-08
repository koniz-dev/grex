AC8 (pre-merge half) - Tests run on PR #16
Run: https://github.com/koniz-dev/grex/actions/runs/31261074153 (conclusion: success)
Gate steps: 8. Run tests: success | 12. Coverage gate: success | 16. Enforce coverage baseline: skipped

## 📊 Test Coverage Report

**Coverage:** 32.6%
**Status:** ✅ Passing

| Layer | Coverage | Baseline | Target | Status |
|-------|----------|----------|--------|--------|
| **Total** | 32.6% | 31% | 80% | ✅ |
| **Domain** | 53.5% | 52% | 100% | ✅ |
| **Data** | 18.9% | 17% | 90% | ✅ |
| **Presentation** | 37.0% | 36% | 80% | ✅ |
| **Core** | 14.0% | 13% | 80% | ✅ |
| **Shared** | 60.2% | 46% | 80% | ✅ |

<sub>Baseline is the enforced gate and lives in `scripts/linux/testing/coverage_baseline.env`. Target is the long-term goal and is not enforced. 5078 of 15587 lines covered.</sub>

Full HTML report in the [workflow artifacts](https://github.com/koniz-dev/grex/actions/runs/31261074153).
<!-- Sticky Pull Request Comment -->

--- CI margins against the new baselines ---
total 32.6 vs 31 = 1.6 | domain 53.5 vs 52 = 1.5 | data 18.9 vs 17 = 1.9
presentation 37.0 vs 36 = 1.0 | core 14.0 vs 13 = 1.0 | shared 60.2 vs 46 = 14.2

The merge-commit half of criterion 8 is recorded in the issue #14 close comment,
since a post-merge run cannot be committed to a branch that no longer exists.
