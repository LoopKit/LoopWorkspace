# LoopAlgorithm Sync Log

**Repo:** https://github.com/LoopKit/LoopAlgorithm
**Tidepool fork:** https://github.com/tidepool-org/LoopAlgorithm
**Sync date:** 2026-03-10
**Sync branch:** `tidepool-sync/2026-03-10`
**Base branch:** `main`

---

## Merge Summary

**Type:** ✅ Clean fast-forward — no conflicts

- Merge base (LoopKit/main tip): `9d24054`
- Tidepool/main tip: `13cb4b4`
- LoopKit has 0 commits not in Tidepool
- Tidepool has 29 commits not in LoopKit (across multiple PRs)

```
git checkout -b tidepool-sync/2026-03-10
git merge --no-edit tidepool/main
# Result: Fast-forward, 67 files changed, 2237 insertions(+), 442 deletions(-)
```

---

## What Was Merged

### PR #24 — Move glucose math tests from LoopKit to LoopAlgorithm
- Commit: `13cb4b4`
- https://github.com/tidepool-org/LoopAlgorithm/pull/24
- Adds `GlucoseMathTests.swift` (435 lines) and associated fixtures
- Moves test coverage that was previously in LoopKit into this package
- **Testing impact:** Run `LoopAlgorithmTests` test suite

### PR #23 — Gradual transitions support
- Commit: `8093b57`
- https://github.com/tidepool-org/LoopAlgorithm/pull/23
- Adds support for gradual insulin/carb effect transitions in algorithm
- **Testing impact:** Verify glucose prediction curves match expected shapes

### PR #22 — LOOP-5502: Allow setting of max active insulin multiplier
- Commit: `89dd58a`
- https://github.com/tidepool-org/LoopAlgorithm/pull/22
- Adds configurable `maxActiveInsulinMultiplier` to algorithm input
- **Testing impact:** Verify max IOB calculations respect the multiplier

### PR #21 — Carb absorption model selection updates
- Commit: `29c7b52`
- https://github.com/tidepool-org/LoopAlgorithm/pull/21
- Updates how carb absorption model is selected/configured
- **Testing impact:** CarbMathTests; verify carb absorption curves

### PR #20 — Fix decoding of old AutomaticDoseRecommendation structures
- Commit: `7ba61e1`
- https://github.com/tidepool-org/LoopAlgorithm/pull/20
- Fixes backward compatibility for `AutomaticDoseRecommendation` without `basalAdjustment`
- **Testing impact:** Data migration; old stored recommendations should decode without crashing

### PR #19 — Fix issue with mid-absorption ISF calculation
- Commit: `84a099f`
- https://github.com/tidepool-org/LoopAlgorithm/pull/19
- Fixes insulin sensitivity factor calculation during active carb absorption
- **Testing impact:** CorrectionDosingTests; verify ISF used correctly during meal absorption

### LOOP-5295 — Add directionality to TempBasalRecommendation
- PR: https://github.com/tidepool-org/LoopAlgorithm/pull/18
- Adds `.direction` property to `TempBasalRecommendation` (increase/decrease/unchanged)
- Enables Loop UI to show directional feedback on temp basal changes
- **Testing impact:** Verify temp basal recommendations include direction field

### LOOP-5280 — Display Glucose Preference by InternationalUnit
- Adds `LoopUnit` and `LoopQuantity` types to replace HealthKit dependency for glucose units
- **Testing impact:** New `LoopUnitTests.swift` added

### Remove HealthKit Dependency & Upgrade to Swift 6
- Removes `HKUnit.swift` and `HKQuantity.swift` extensions
- Replaces with `LoopUnit` and `LoopQuantity` (custom, no HealthKit import)
- Upgrades Swift concurrency to Swift 6 (`Sendable` annotations throughout)
- **Testing impact:** ⚠️ HIGH IMPACT — changes the unit/quantity types used in algorithm API.
  Any caller of the algorithm API that used `HKUnit`/`HKQuantity` needs to be updated
  to use `LoopUnit`/`LoopQuantity`. This is a breaking API change.
  In LoopKit DIY: the inline `LoopKit/LoopAlgorithm/` code will need these types added,
  OR LoopKit should adopt this package.

### Remove CoreData Import
- Removed CoreData framework dependency from the package
- Package is now more portable and framework-independent

### PR #14 — Mark AbsoluteScheduleValue as Sendable
- Adds Swift 6 `Sendable` conformance to `AbsoluteScheduleValue`

---

## ⚠️ Breaking API Change: HealthKit Removal

The most significant change is the replacement of `HKUnit`/`HKQuantity` with `LoopUnit`/`LoopQuantity`.

**Impact on LoopKit DIY's inline algorithm code (`LoopKit/LoopKit/LoopAlgorithm/`):**
- The inline code still uses HealthKit types
- When syncing LoopKit, these new types need to either:
  1. Be introduced inline in `LoopKit/LoopAlgorithm/` as well, OR
  2. Prompt a decision to adopt the `LoopAlgorithm` package in LoopKit DIY

This is a cross-repo dependency: **LoopAlgorithm sync must be reviewed before LoopKit sync**.
Specifically, any LoopKit conflict in `LoopAlgorithm/*.swift` files likely involves
these same HealthKit→LoopKit unit type changes.

---

## Files Changed

| Change | Files |
|--------|-------|
| Deleted | `Extensions/HKQuantity.swift`, `Extensions/HKUnit.swift` |
| Added | `LoopQuantity.swift`, `LoopUnit.swift`, `Tests/GlucoseMathTests.swift`, `Tests/LoopUnitTests.swift` |
| Added fixtures | 13 JSON test fixture files for glucose/carb math tests |
| Modified | `LoopAlgorithm.swift`, `DoseMath.swift`, `GlucoseMath.swift`, `CarbMath.swift`, `InsulinMath.swift`, `LoopPredictionInput.swift`, `AlgorithmInput.swift`, `TempBasalRecommendation.swift`, `AutomaticDoseRecommendation.swift`, and others |

---

## Status

✅ **Merged cleanly** — fast-forward, no conflicts.

⚠️ **Action required before LoopKit sync:**
- Review the `LoopUnit`/`LoopQuantity` API change impact on LoopKit's inline algorithm code
- Decide: adopt LoopAlgorithm as a package in DIY, or update inline code to match?
- Consider whether PR needs to be opened on `LoopKit/LoopAlgorithm` → `main`

---

## Testing Notes

After this sync is pushed and integrated:
- [ ] Run full `LoopAlgorithmTests` test suite
- [ ] Verify glucose prediction accuracy (GlucoseMathTests)
- [ ] Verify ISF handling during carb absorption (CorrectionDosingTests)
- [ ] Verify carb absorption model selection
- [ ] Verify `AutomaticDoseRecommendation` backward decode compatibility
- [ ] Verify `TempBasalRecommendation` direction field populated
- [ ] Check for any callers of algorithm API still using `HKUnit`/`HKQuantity`
