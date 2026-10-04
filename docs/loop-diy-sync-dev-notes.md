# Loop DIY — Sync & Developer Notes

*Development-level record of the Tidepool → DIY syncs (2026-03-10 and 2026-05-11),
the merge conflicts and how they were resolved, the DIY divergences that must be
defended on future syncs, data-migration internals, and the DIY-only work that has
landed on `next-dev` since.*

Last updated: 2026-07-14.

For the user-facing summary of these changes, see
[What's New](loop-diy-whats-new.md). This document is the "how and why" companion:
conflicts, resolutions, testing, and gotchas.

---

## 1. Sync history & headline numbers

| Sync | Branch | Scope |
|---|---|---|
| **2026-03-10** | `tidepool-sync/2026-03-10` | The large rebase: LoopAlgorithm package extraction, Swift Concurrency migration, HealthKit → LoopUnit migration, presets overhaul. 18 repos. |
| **2026-05-11** | `tidepool-sync/2026-05-11` | Follow-up absorbing ~2 months of incremental Tidepool work. 17 repos + LoopAlgorithm pin bump. ~660 Tidepool commits total. |

Commits absorbed in the 2026-05-11 sync (largest first): LoopKit 409, TidepoolService 45,
LoopOnboarding 28, NightscoutService 22, OmniBLE 20, OmniKit/MinimedKit 18 each,
G7SensorKit/dexcom-share-client-swift 15 each, Loop 14, LibreTransmitter 14,
CGMBLEKit/NightscoutRemoteCGM 13 each, LoopSupport 11, AmplitudeService/LogglyService 6
each, LoopAlgorithm 4 (test-only), RileyLinkKit 3, MixpanelService 0.

Both syncs originated from PR
[LoopKit/LoopWorkspace#450](https://github.com/LoopKit/LoopWorkspace/pull/450)
(supersedes #213). The original per-doc files this consolidates:
`docs/tidepool-sync-2026-03-10.md` and `docs/tidepool-sync-2026-05-11.md`.

---

## 2. LoopAlgorithm architecture change

**The single most important architectural fact.** DIY previously embedded algorithm
logic inline inside `LoopKit` (`LoopKit/LoopKit/LoopAlgorithm/`), with effects computed
across `CarbStore` / `DoseStore` / `GlucoseStore` and orchestrated by `LoopDataManager`.
`LoopAlgorithm` was a stateful `actor`.

It is now the **`tidepool-org/LoopAlgorithm` Swift package**, reconceived as a **pure
function**:

```
AlgorithmOutput = LoopAlgorithm.run(input: AlgorithmInput)   // caseless enum, static, no state
```

| Aspect | Before (DIY inline) | After (package) |
|---|---|---|
| Type | `public actor` (stateful, async) | `public enum` (static methods only) |
| Entry point | `generatePrediction(input:startDate:) throws` | `run(input:) -> AlgorithmOutput` (non-throwing; errors in `Result`) |
| Effects | Distributed across stores | All in `LoopAlgorithm` static methods, exposed as 8 fields |
| Error cases | 2 | 7 (granular) |
| Units | `HKUnit` / `HKQuantity` | `LoopUnit` / `LoopQuantity` (no HealthKit) |
| Dependencies | HealthKit, CoreData | None (pure Swift) |
| Testing | Mocked async stores | Pure value types + JSON fixtures |

> ⚠️ **Packaging decision was reversed between the two syncs.** The 2026-03-10 doc
> originally said DIY keeps LoopAlgorithm *inline* and *omits* the
> `XCRemoteSwiftPackageReference "LoopAlgorithm"`. **This is no longer true.** As of the
> 2026-05-11 sync (LOOP-4781), DIY consumes the `tidepool-org/LoopAlgorithm` **Swift
> package**, pinned in the workspace `Package.resolved`, and the inline copies
> (`LoopAlgorithm.swift`, `LoopPredictionOutput.swift`, `ExponentialInsulinModel.swift`)
> were **deleted**. `import LoopAlgorithm` is present again everywhere. **If `AGENTS.md`
> still says "keep LoopAlgorithm inline / omit the package reference," that guidance is
> stale and should be reconciled against this section.**

Algorithm-level improvements included in the synced package version: gradual effect
transitions (PR #23), configurable `maxActiveInsulinMultiplier` default 2× (LOOP-5502),
runtime `carbAbsorptionModel` selection (PR #21), `AutomaticDoseRecommendation` backward
decode fix (PR #20), mid-absorption ISF fix (PR #19), `TempBasalRecommendation.direction`
(LOOP-5295), Swift 6 `Sendable` conformances (PR #14), glucose-math tests moved into the
package (PR #24).

---

## 3. Merge conflicts & resolutions

### 3.1 Conflict volume by repo

| Repo | 2026-03-10 | 2026-05-11 |
|---|---|---|
| LoopAlgorithm | none (clean FF, 29 ahead) | pin bump only (4 test-only) |
| LoopKit | 16 (source + pbxproj) | 18 source + 19 pbxproj regions |
| Loop | 33 across 30+ files | 3 pbxproj regions only (no source) |
| Peripheral repos (9) | pbxproj-only | 11/15 plugins: only the `LOCALIZATION_PREFERS_STRING_CATALOGS` line |
| Plugin source conflicts | 6 repos | 5 repos |

### 3.2 Loop — the deepest conflict: `LoopDataManager.swift`

7 conflict hunks from a fundamental divergence: Tidepool migrated to Swift Concurrency
(`@MainActor async/await`, `Task {}`); DIY had `dataAccessQueue`-based threading plus
Live Activity integration.

**Resolution:** adopt Tidepool's `Task { @MainActor in await updateDisplayState() }`
model throughout; **remove** DIY's `dataAccessQueue`, `lockedSettings`, `mutateSettings()`,
`loop()`, `loopInternal()`, `finishLoop()` chain; inject DIY's Live Activity calls into
Tidepool's new `updateDisplayState()` call sites; adopt new init params
(`analyticsServicesManager`, `carbAbsorptionModel`,
`usePositiveMomentumAndRCForManualBoluses`, `dosingStrategySelectionEnabled`) and move all
stored-property assignments before the `overrideIntentObserver` closure.

### 3.3 Loop — file-level resolutions (2026-03-10)

| File | Resolution |
|---|---|
| `SystemActionLink.swift` | Deleted; replaced by Tidepool's `DeeplinkView.swift`. Port DIY widget tinting if verified missing. |
| `FavoriteFoodDetailView.swift` | Accept Tidepool's move to `Views/Favorite Foods/`. |
| `Main.strings` | Keep deleted — DIY is on `.xcstrings`. |
| `AppDelegate.swift` | Keep both (DIY logging + Tidepool XCTest guard). |
| `DeviceDataManager.swift` | Keep both (DIY diagnostic report + Tidepool `roundBasalRate`). |
| `SettingsView.swift` | Keep both sheets (Favorite Foods + Presets). |
| `NSUserDefaults.swift` | Keep both keys (`liveActivity` + `defaultEnvironment`). |
| `WidgetBackground.swift` | Take Tidepool's `Color.widgetBackground` extension. |
| `ContentMargin.swift` | Keep DIY (only copyright differed). |

### 3.4 Plugin source conflicts (2026-05-11)

| Repo / File | Resolution |
|---|---|
| OmniKit / `OmnipodPumpManager.swift` | Keep DIY `isSignalLost(...)` reentrant-lock fix (`924f10d`); take Tidepool `setState` → `mutateState`. |
| OmniBLE / `OmniBLEPumpManager.swift` | Keep DIY reentrant-lock fix (`e9425ad`) + `completion(.communication(error))` style; **manual merge** at line 2722 to preserve DIY suspend-time-expired special case (Pod Keep Alive #165) while adopting Tidepool's `withCheckedThrowingContinuation`; take Tidepool `mutateState`. |
| MinimedKit / `MinimedPumpManager.swift` | Keep DIY all 3 regions — preserves CAGE/IAGE tracking (`ff07802`); dropped Tidepool's duplicate `isInoperable`. |
| TidepoolService / `DoseEntry.swift` | Deduped duplicate `import LoopAlgorithm` (`5f6a064`). |
| NightscoutService / `NightscoutService.swift` | Keep DIY — preserves the 60-line APNS response feature (`RemoteNotificationResponseManager`, `0ca2c08`). |

### 3.5 Accepted Tidepool deletions

- Inline algorithm copies (LOOP-4781): `ExponentialInsulinModel.swift`,
  `LoopAlgorithm/LoopAlgorithm.swift`, `LoopAlgorithm/LoopPredictionOutput.swift`.
- `LoopKitUI/View Controllers/OverrideSelectionViewController.swift` — superseded by the
  new SwiftUI `EditPresetView` / `ReviewNewPresetView`; DIY crash-fix `3ce43ded` doesn't
  apply to the SwiftUI flow.

### 3.6 pbxproj merge rules (applied across all repos)

| Setting | Decision |
|---|---|
| `IPHONEOS_DEPLOYMENT_TARGET` | Take the higher value. |
| `LOCALIZATION_PREFERS_STRING_CATALOGS` | Keep `YES`. |
| `.strings` file references | Drop Tidepool's (DIY deleted the files; re-adding breaks the build). |
| `.xcstrings` references | Keep DIY's. |
| `XCRemoteSwiftPackageReference "LoopAlgorithm"` | **Keep** (post-4781; the pre-existing HEAD reference was left alone). |
| New Swift file references | Keep both additively, then dedup `children`/`files`. |
| Bundle IDs | Keep both (different targets). |

**Structural rule:** "keep both" is *wrong* across a `PBXVariantGroup` / `PBXGroup`
boundary. Always check `brace_count(ours) + brace_count(theirs)` before keeping both; if
non-zero, take OURS. After any pbxproj merge, verify brace depth == 0 and validate with
`xcodebuild -project <Name>.xcodeproj -list`. (Loop's conflict 36 produced a +2 depth and
had to be re-resolved; 7 duplicate group children were removed.)

---

## 4. DIY divergences (defend these on every future sync)

These are points where DIY intentionally rejects a Tidepool change. Auto-merge has
silently reverted some of them before — each carries an inline defending comment.

| Divergence | Repo | Why |
|---|---|---|
| **BasalRateScheduleEditor max-basal filtering** | LoopKit | DIY rejects Tidepool PR #734 (LOOP-5767) which passed `maximumBasalRate: nil` and let users set basal entries above their configured max. Restored `maximumBasalRatePerHour`; see `memory/divergence_basal_max_filter.md`. Silently reverted on 2026-05-11; manually restored. |
| **slot6SuspendTimeExpired guard** | OmniBLE | Safety-critical: a suspended pod must keep beeping; don't silently ack. Not present in OmniKit (different pod hardware). |
| **updateLastEventDates** | MinimedKit | Cannula-age / insulin-age tracking; no Tidepool equivalent. |
| **RemoteNotificationResponseManager** | NightscoutService | Remote-command feedback (remote bolus/basal); core DIY feature. |
| **Mock debug settings views** | LoopKit (MockKitUI) | `MockCGMManagerSettingsView` / `MockPumpManagerSettingsView` gated by `allowDebugFeatures`. |
| **Reentrant-lock fixes** | OmniKit / OmniBLE | `isSignalLost` reentrancy (`924f10d` / `e9425ad`). |
| **`.xcstrings` localization** | all | DIY uses Xcode 15+ string catalogs; do **not** re-add `.strings` refs. Tidepool doesn't maintain translations. |

---

## 5. Post-merge fixes (2026-03-10)

- **`LoopDataManager.swift`** — moved all stored-property assignments before the
  `overrideIntentObserver` closure (Swift init-before-capture).
- **`NSUserDefaults.swift`** — restored two missing closing braces in the `liveActivity`
  computed property.
- **`TidepoolServiceKit/Extensions/DoseEntry.swift`, `DeviceLogUploader.swift`** — restored
  `import LoopAlgorithm` (removed in error during conflict resolution; only CLI builds
  masked it via implicit module visibility).
- **`Loop.xcodeproj/project.pbxproj`** — re-resolved the `PBXVariantGroup` conflict that
  produced +2 brace depth; deduped 7 group children; validated with `xcodebuild -list`.

---

## 6. Core Data v4 → v6 migration & downgrade caveat

The shared LoopKit store (`Model.sqlite`, app group) migrates **Modelv4 → Modelv6** on
first launch of a sync build. `dev` only ships up to Modelv4.

- **Forward migration preserves insulin data.** `CachedInsulinDeliveryObjectMigrationPolicy`
  copies `value` → `deliveredUnits` (and `programmedUnits` for boluses); basal *rates*
  carry over via `scheduledBasalRate` / `programmedTempBasalRate`. Without this policy the
  v4→v6 mapping dropped the single `value` attribute and zeroed cached bolus/basal amounts
  (understating IOB). **Only the forward path is fixed** — installs that already migrated on
  a policy-less build have already-dropped values that read as 0 and can't be recovered.
- **Downgrading back to `dev` is data-dependent.** `dev` *can* open a v6 store via
  lightweight migration **immediately after upgrading** (v6-only attributes are optional
  and dropped; `deliveredUnits` shares the `ZVALUE` column with v4's `value` via
  `elementID="value"`). **But** `dev`'s `CachedInsulinDeliveryObject.value` is *mandatory*
  while v6's `deliveredUnits` is *optional* — once the sync build records a dose with a
  **null `deliveredUnits`** (in-progress/mutable or programmed-only), the downgrade throws
  `NSCocoaErrorDomain 134110` ("missing attribute values on mandatory destination
  attribute"), `addPersistentStore` fails, `PersistenceController` lands in `.error`, and
  `dev` is non-functional until delete + reinstall (which rebuilds the cache from HealthKit).
  The v6 data on disk is never wiped, so reinstalling the sync build always reads it again.

**Practical guidance:** in-place downgrade to `dev` is fine right after upgrading, gets
unreliable the longer the sync build runs. Don't rely on it for round-tripping.

---

## 7. Post-sync development on `next-dev` (since ~2026-05-20)

DIY-only work that landed after the two syncs. All on `LoopKit/Loop next-dev` unless
noted; workspace gitlinks bumped on `LoopKit/LoopWorkspace next-dev`.

### 7.1 Device driver re-organization

- **OmniKit + OmniBLE consolidated into `OmnipodKit`** (loop-and-learn's combined pod
  driver; wired via Loop #2426 `1f71ec4f`). OmniKit/OmniBLE are no longer separate
  workspace submodules.
- **`MedtrumKit`** added (Medtrum Nano / TouchCare pump). Fork: `LoopKit/MedtrumKit` off
  `jbr7rr/MedtrumKit`.
- **`EversenseKit`** added (Senseonics Eversense CGM); deployment target set to 17.0.
- **`LibreLoop` + `LibreCRKit`** added (native FreeStyle Libre 3). Substantial DIY work:
  BLE pairing/stability, reconnect backoff + re-scan prompt, backfill of missed readings
  (Libre 3 CCCD/data-plane arming — the `0xFD` fix, full-response-set re-arm), 5-minute
  backfill grid thinning, sensor-failure UI, mg/dL vs mmol/L display, module-scoped
  localization (String Catalogs), and a Glucose Streams debug view. `LibreCRKit` has since
  been replaced by the `RoundWhiteDiscKit` submodule (`airedev326/RoundWhiteDiscKit`), which
  ships without its lookup tables: LibreLoop downloads them from Arweave once and the package
  pins their digest, so bump the submodule and LibreLoop's Arweave txid together.

### 7.2 New user-facing features (see What's New for the user framing)

- **Statistics / AGP page** — new `GlucoseStatistics` model + `StatisticsView` /
  `AGPChartView` / `TimeInRangeBar` (Apple Swift Charts). Reads the 90-day glucose cache
  (`LOOP_LOCAL_CACHE_DURATION_DAYS = 90`). Per-zone percentile band painting; captūrAGP/IDC
  coloring; 7/14/30/90-day windows with an incomplete-data notice.
- **Glucose Alerts system** — `GlucoseAlertManager` + `GlucoseAlertSettingsView`. Per-profile
  Urgent Low / Low / High / Predicted Low thresholds; selectable alarm sounds; "Delay 1st
  Alert" for highs; issues only the most severe low-side alert; suppresses predicted-low when
  already at/below Low. **Thresholds stored canonically in mg/dL; display/entry convert to the
  user's unit** via `DisplayGlucosePreference` + `GlucoseValuePicker` (`a325b943`).
- **AlarmKit critical alerts (iOS 26+)** — critical alerts without the entitlement; fires an
  alarm at a near-future date with an audio fallback (`critical.caf`, MPVolumeView volume
  boost); Stop acknowledges the Loop alert; in-app Alerts FAQ for no-entitlement builds.
- **Watch** — fetch glucose on foreground; backfill from latest stored sample.
- **Manual temp basal** — pause looping while running; surface in `LoopStatusModalView` HUD.
- **Display forecast** — project ongoing suspends / temp basals into the forecast.
- **De-branding** — replace hardcoded "Tidepool Loop" with the host app name; Focus-mode
  imagesets; app version moved into the Support section.
- **Carb entry** honors `LoopConstants` for date-picker limits (`5f0686cf`).

### 7.3 Test / CI / build infrastructure

- Test fixes for the current LoopAlgorithm + DIY behavior: `LoopDataManagerTests`,
  `LoopKitTests` (guardrails 87/67, continuous decay, sorted `appendedUnion` input),
  full-scheme test isolation (`testOpenLoopCancelsTempBasal`),
  `isManualTempBasalRunning` on `MockDeliveryDelegate`.
- **CI moved to Xcode 26.4** (from 16.4), iPhone 17 simulator, dropped the simulator OS pin;
  `xcbeautify` instead of `xcpretty` so test failures surface.
- **Known flake:** `SettingsManagerTests` intermittently hangs (~23s timeout → retry →
  "Executed 0 tests"), producing sporadic red on otherwise-identical code. Re-run when seen.
- OmnipodKit CryptoSwift 1.9+ compatibility (`Data.bytes` → `Array(data)`);
  LoopOnboarding links `NightscoutServiceKitUI` to fix an explicit-modules build race.

---

## 8. Testing checklist (consolidated)

### Algorithm & dosing
- [ ] Glucose predictions; mid-absorption ISF (dose effect follows the ISF *timeline* as
      insulin absorbs, not a single ISF fixed at dose time); max-IOB multiplier (2×).
- [ ] `TempBasalRecommendation.direction` populated.
- [ ] Display forecast projects ongoing suspends / manual temp basals.
- [ ] Pump decision IDs on OmnipodKit / MinimedKit dose entries.

### Presets
- [ ] All 4 activity presets appear with correct defaults; "modified" indicator works.
- [ ] High-insulin-needs mitigation clamps correction range ≥ 110 mg/dL above ~165%.
- [ ] Indefinite-preset 24-hour reminder fires and retracts on deactivation.
- [ ] Scheduled presets alert at the correct time; "Yes, Start Now" activates.
- [ ] Pre-meal guardrail: 130 mg/dL hard cap; recommended upper bound = correction-range lower bound.
- [ ] Training gates the "+" create button; active-preset banner shows on CarbEntryView.

### Glucose alerts (DIY)
- [ ] Thresholds display and the picker steps correctly in **both** mg/dL and mmol/L.
- [ ] Only the most severe low-side alert fires; predicted-low suppressed at/below Low.
- [ ] Selectable sounds play; "Delay 1st Alert" honored for highs.
- [ ] AlarmKit critical alerts break through silent/Focus on iOS 26; Stop acks the Loop alert.

### Statistics
- [ ] AGP bands/median render; GMI/avg/CV/TIR populate; range selector reloads (7/14/30/90);
      incomplete-data notice shows; units follow the mg/dL ↔ mmol/L preference.

### Devices
- [ ] Add Pump lists Omnipod + Medtrum; Add CGM lists Eversense + Libre 3 (LibreLoop) + Dexcom.
- [ ] Libre 3 pairing, reconnect, and backfill (5-min grid) work; no `0xFD` on backfill.
- [ ] OmniBLE temp-basal error reporting surfaces; suspended-pod keeps beeping (slot6 guard).
- [ ] Minimed cannula/insulin age displays (updateLastEventDates).

### Cross-cutting
- [ ] Live Activity updates on glucose/dosing/carb changes; widget deeplink buttons + colors.
- [ ] Both Favorite Foods and Presets sheets accessible; bolus entry safe-area layout correct.
- [ ] Nightscout remote bolus/basal feedback notifications flow (RemoteNotificationResponseManager).
- [ ] Basal schedule editor (OmniBLE/Dash): entries above configured max are **not** selectable.
- [ ] Diagnostic support report includes submodule SHAs.
- [ ] Unit suites pass: `LoopAlgorithmTests`, `LoopKitTests`, `LoopTests`.
- [ ] Core Data v4→v6 migration preserves insulin amounts; downgrade caveat understood (§6).
