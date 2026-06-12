# Loop Sync Log

**Repo:** https://github.com/LoopKit/Loop
**Tidepool fork:** https://github.com/tidepool-org/Loop
**Sync date:** 2026-03-10
**Sync branch:** `tidepool-sync/2026-03-10`
**Base branch:** `dev`

---

## Merge Summary

- Merge base: `55cf35a9`
- 33 conflicts across 30+ files
- Categories: 3 modify/delete, 22 Swift source, 7 xcschemes, 1 pbxproj

---

## Modify/Delete Resolutions

### `Loop Widget Extension/Components/SystemActionLink.swift` — DELETED
- **Tidepool** deleted it in commit `c22b37f4` ("Code cleanup"), replacing with `DeeplinkView.swift`
- **DIY** had improved it: added `@available(iOS 16.1, *)`, `widgetRenderingMode`, fixed active preset colors
- **Resolution:** Take deletion. `DeeplinkView.swift` auto-merged cleanly and provides the same
  deeplink functionality. DIY's widget tinting improvements should be ported to `DeeplinkView`
  if they're missing.
- ⚠️ **Test:** Widget action buttons (carbs, bolus, pre-meal, preset) — verify colors in accented/tinted mode

### `Loop/Views/FavoriteFoodDetailView.swift` — DELETED (moved)
- **Tidepool** moved it to `Loop/Views/Favorite Foods/FavoriteFoodDetailView.swift` in commit
  `2c914f87` ("Renaming/organizing favorite foods")
- **DIY** had updated it with `String(localized:)` annotations on the same fields
- **Resolution:** Take deletion. The `Favorite Foods/` subfolder version already exists in DIY's
  tree and `FavoriteFoodsView.swift` references it correctly. DIY's localization updates need
  to be checked against the Favorite Foods subfolder version.
- ⚠️ **Test:** Favorite Foods detail view — verify all field labels are localized

### `Loop/en.lproj/Main.strings` — KEPT DELETED
- DIY deleted it in `cfff59a5` (migrated to `.xcstrings` format)
- Tidepool modified it (never migrated to xcstrings)
- **Resolution:** Keep deleted per the standard .strings policy

---

## Swift Source Resolutions

### Widget Files

| File | Resolution | Notes |
|------|-----------|-------|
| `ContentMargin.swift` | Kept DIY's copyright date | Same impl, only date differed |
| `WidgetBackground.swift` | Took Tidepool's | `Color.widgetBackground` extension cleaner than `Color("WidgetBackground")` |
| `SystemStatusWidget.swift` | Took Tidepool's | Uses `DeeplinkView` + `.containerRelativeBackground()`; removed `@available(iOS 16.1, *)` guard (no longer needed) |

### Managers

| File | Hunks | Resolution | Notes |
|------|-------|-----------|-------|
| `AppDelegate.swift` | 1 | Kept both | DIY: logging; Tidepool: XCTest environment guard (skip full init in unit tests) |
| `StoredAlert.swift` | 2 | Took Tidepool's | Whitespace/empty hunks only |
| `AppExpirationAlerter.swift` | 2 | Took Tidepool's | Indentation of `#if targetEnvironment(simulator)` only |
| `DeviceDataManager.swift` | 1 | Kept both | DIY: diagnostic report with submodule SHAs (`b6e88416`); Tidepool: `roundBasalRate(unitsPerHour:)` function (`184ea75a`) — different code at adjacent location |
| `RemoteDataServicesManager.swift` | 1 | Took Tidepool's | Migrated `uploadCgmEventData` from callback to `async/await Task` |

### LoopDataManager ⚠️ NEEDS COMPILE TEST

This file has the deepest architectural conflict. Tidepool migrated to Swift Concurrency
(`@MainActor async/await`) while DIY added Live Activity support and kept `dataAccessQueue`.

| Hunk | DIY | Tidepool | Resolution |
|------|-----|---------|-----------|
| 1 | `liveActivityManager: LiveActivityManagerProxy?` property | `lastReservoirValue` computed property | **Kept both** |
| 2 | LiveActivityManager init + overrideIntentObserver setup | Different init params (`analyticsServicesManager`, `carbAbsorptionModel`, etc.) | **Kept both** — ⚠️ likely compile errors; needs human review |
| 3 | `dataAccessQueue.async` + cache invalidation + liveActivity update | `Task { @MainActor in await updateDisplayState() }` | **Tidepool's Task + liveActivity injected** |
| 4 | `dataAccessQueue.async` + glucose effect clear + liveActivity | `Task { @MainActor }` + `restartGlucoseValueStalenessTimer()` | **Tidepool's Task + liveActivity injected** |
| 5 | `dataAccessQueue.async` + insulin effect clear + liveActivity | `Task { @MainActor in await updateDisplayState() }` | **Tidepool's Task + liveActivity injected** |
| 6 | `lockedSettings`, `settings`, `mutateSettings()` + liveActivity calls | `Task { await updateDisplayState() }` | **Kept both** — ⚠️ structural divergence; needs human review |
| 7 | Complete `loop()`→`loopInternal()`→`finishLoop()`→`update()` chain | `await dosingDecisionStore.storeDosingDecision()` (async) | **Kept both** — ⚠️ DIY loop chain critical; Tidepool async store; needs human review |

**Key questions for human review:**
- Did Tidepool replace `lockedSettings`/`mutateSettings()` with a different pattern? If so, all callers need updating.
- Does Tidepool's `updateDisplayState()` need to also call `liveActivityManager?.update()`?
- Is the DIY `loop()`/`loopInternal()` chain still intact or did Tidepool restructure it?

### View Controllers

| File | Resolution | Notes |
|------|-----------|-------|
| `CarbAbsorptionViewController.swift` | Took Tidepool's | Cleaner async do/catch pattern for carb review |
| `InsulinDeliveryTableViewController.swift` | Took Tidepool's | `pumpEvent.dose` + `String(describing:)` format |
| `StatusTableViewController.swift` | Took Tidepool's | More complete `.inProgress` switch handling |

### View Models

| File | Resolution | Notes |
|------|-----------|-------|
| `CarbEntryViewModel.swift` | Took Tidepool's | `CarbMath.dateAdjustmentPast` (from LoopAlgorithm pkg) vs `LoopConstants.maxCarbEntryPastTime` — same value, different source |
| `SimpleBolusViewModel.swift` | Took Tidepool's | Explicit `NSLocalizedString("–", comment:...)` |

### Views

| File | Resolution | Notes |
|------|-----------|-------|
| `BolusEntryView.swift` | Took Tidepool's | Removed `GeometryReader` wrapper; updated `onChange(of:)` to iOS 17+ two-param API |
| `CarbEntryView.swift` | Took Tidepool's | "Save as favorite" button only shown when `selectedFavoriteFood == nil` |
| `ManualEntryDoseView.swift` | Took Tidepool's | Minor indentation + iOS 17+ `onChange` API |
| `SettingsView.swift` | Kept both | DIY's `favoriteFoods` sheet + Tidepool's `presets` sheet added |

### Core / Tests

| File | Resolution | Notes |
|------|-----------|-------|
| `NSUserDefaults.swift` | Kept both | DIY: `liveActivity` key (`LiveActivitySettings`); Tidepool: `defaultEnvironment` key — separate features |
| `AlertStoreTests.swift` | Took Tidepool's | Updated JSON encoding assertions for new Alert format |
| `StoredAlertTests.swift` | Took Tidepool's | Updated JSON expectations |

### xcschemes (all 7)

Took Tidepool's — updated Xcode scheme versions.

---

## project.pbxproj

- Standard resolver applied: merged both sides' file references, dropped Tidepool's `.strings` refs, kept DIY's `.xcstrings`, took Tidepool's deployment target

---

## Features Added by This Merge (Tidepool → DIY)

- **Active Preset Banner** on CarbEntryView (LOOP-5432)
- **DeeplinkView** widget component (replaces SystemActionLink)
- **roundBasalRate** in DeviceDataManager (LOOP-5558)
- **schedulePresets** storage in NSUserDefaults (LOOP-4754)
- **defaultEnvironment** key for Tidepool service (LOOP-5153)
- **iOS 17+ onChange API** updates throughout views
- **XCTest environment guard** in AppDelegate (skip full init when testing)
- **Async Task pattern** in RemoteDataServicesManager

## DIY Features Preserved

- **Live Activity** (`LiveActivityManager`, `liveActivityManager?.update()` calls woven into Tidepool's Task blocks)
- **Diagnostic report with submodule SHAs** in DeviceDataManager
- **FavoriteFoods** sheet in SettingsView
- **liveActivity** NSUserDefaults key + `LiveActivitySettings`

---

## Testing Notes

- [ ] ⚠️ **Build** — `LoopDataManager.swift` hunks 2/6/7 kept both sides and will very likely need manual fixup to compile
- [ ] **Live Activity** — verify glucose, dosing, and carb notifications all trigger liveActivity updates (hunks 3/4/5)
- [ ] **Widget action buttons** — carbs, bolus, pre-meal, preset deeplinks work; colors correct in tinted mode
- [ ] **Favorite Foods** — detail view labels localized; "Save as favorite" only shown when no food selected
- [ ] **Settings** — both Favorite Foods and Presets sheets accessible
- [ ] **Bolus entry** — recommendation clears on edit; safe area layout correct (GeometryReader removed)
- [ ] **App expiry alerting** — TestFlight and profile expiry both handled independently
- [ ] **Diagnostic report** — includes submodule SHAs in support report
