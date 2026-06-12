# Tidepool → LoopKit DIY Sync — 2026-05-11

**Branch:** `tidepool-sync/2026-05-11` (17 repos merged + LoopAlgorithm pin bump)
**Build status:** pending verification (in progress at time of writing)
**Previous sync:** 2026-03-10 (see [`tidepool-sync-2026-03-10.md`](tidepool-sync-2026-03-10.md))

This is the smaller, follow-up sync after the large 2026-03-10 rebase.
Most of the heavy architectural integration (LoopAlgorithm package extraction,
Swift Concurrency migration, HK→LoopUnit migration) landed last time. This sync
absorbs roughly 2 months of incremental Tidepool development.

---

## Headline numbers

| Repo (Tier 1+2) | Tidepool commits absorbed |
|---|---|
| LoopKit | 409 |
| Loop | 14 |

| Repo (Tier 3) | Tidepool commits absorbed |
|---|---|
| TidepoolService | 45 |
| LoopOnboarding | 28 |
| NightscoutService | 22 |
| OmniBLE | 20 |
| OmniKit / MinimedKit | 18 each |
| G7SensorKit / dexcom-share-client-swift | 15 each |
| LibreTransmitter | 14 |
| CGMBLEKit / NightscoutRemoteCGM | 13 each |
| LoopSupport | 11 |
| AmplitudeService / LogglyService | 6 each |
| RileyLinkKit | 3 |
| MixpanelService | 0 (already up to date) |
| LoopAlgorithm (package pin) | 4 (test-only) |

Total: ~660 Tidepool commits across the ecosystem.

---

## 1. New features from Tidepool

Most of these are completed by Tidepool in the LoopKit/Loop repos themselves.
The plugins primarily got matching protocol/API updates.

### LoopKit

- **Required version-update flow** (LOOP-1114) — new `LoopNotificationCategory.requiredUpdate`
  and a `SupportProviding` protocol with `MockSupport` UI.
- **`isMutable` dose detection** (LOOP-5843) — `DoseStore` now uses `isMutable` rather
  than time-based heuristics to determine unfinished doses.
- **Activity preset insulin-scale tuning** (LOOP-5807) — biking 0.22→0.23, strength
  training 0.39→0.37 in `TemporaryScheduleOverride.defaultInsulinNeedsScaleFactor`.
- **Correction range overrides guardrail** (LOOP-5878) — `CorrectionRangeOverridesEditor`
  now actually passes `viewModel.guardrail` (was always `nil`).
- **New preset UI infrastructure** — `EditPresetView`, `ReviewNewPresetView`,
  `InsulinNeedsAdjustmentPreview`, and supporting types.
- **Media/Transcript support** — 7 new files under `LoopKit/Media/` (captions, transcripts,
  metadata) — likely for in-app support/training video infrastructure.
- **QuantityFormatter API simplification** — removed unused `rule:` parameter from
  `doubleValue()`.

### Loop

- **Required version-update view** — `RequiredVersionUpdateView`, paired with the LoopKit
  notification category above.
- **Preset performance history** — `PresetPerformanceHistoryView` and `PresetsPerformanceHistoryViewModel`.
- **Automation history tracking** — `AutomationHistoryEntry`, `AutomationHistoryEntryTests`.
- **Media/Transcript player infrastructure** — `AudioPlayer`, `CaptionsView`, `MediaPlayerView`,
  `PlayerControls`, `TranscriptView`, `VideoView` under `Loop/Views/Presets/Media Player/`.

### Plugins

- **OmniBLE / OmniKit** — `mutateState` API migration (replacing `setState`); `decisionId`
  carried through the temp-basal path; pod-inoperable refinements.
- **MinimedKit** — same `decisionId` + protocol updates as the other pump drivers.
- **TidepoolService / NightscoutService** — `decisionId` on `DoseEntry` and
  `PersistedPumpEvent`; misc protocol updates.

---

## 2. Conflicts encountered & resolutions

### LoopKit — 18 source conflicts + 19 pbxproj regions

**Mechanical "take Tidepool" (low risk):**
DoseStore, LoopNotificationCategory, QuantityFormatter, TemporaryScheduleOverride,
LoopKitUI/SupportUI, GlucoseTherapySettingInformationView, CorrectionRangeOverridesEditor,
InsulinType (loses Lokalise detailed insulin descriptions — translations will repopulate
on next Lokalise run).

**Keep DIY (DIY-only debug features):**
`MockKitUI/Views/MockCGMManagerSettingsView.swift` and `MockPumpManagerSettingsView.swift`
— simulator settings gated by `allowDebugFeatures`. Tidepool doesn't have these.

**Accept Tidepool deletions (LoopAlgorithm package extraction, LOOP-4781):**
- `LoopKit/InsulinKit/ExponentialInsulinModel.swift`
- `LoopKit/LoopAlgorithm/LoopAlgorithm.swift`
- `LoopKit/LoopAlgorithm/LoopPredictionOutput.swift`

These types now live in `tidepool-org/LoopAlgorithm` (the Swift Package DIY already
pulls via workspace `Package.resolved`). Deleting the inline copies makes DIY match
Tidepool's architecture.

**Accept Tidepool deletion (preset UI replaced):**
`LoopKitUI/View Controllers/OverrideSelectionViewController.swift` — superseded by
Tidepool's new SwiftUI `EditPresetView` / `ReviewNewPresetView`. DIY's crash-fix
commit `3ce43ded` does not apply to the new SwiftUI flow.

**Add/add — both sides added the same files:**
Took Tidepool's content for the new preset infrastructure
(`InsulinNeedsAdjustmentPreview`, `EditPresetView`, `ReviewNewPresetView`).

**DIY divergence — BasalRateScheduleEditor max-basal filtering (see Section 4):**
The auto-merge silently dropped this fix; restored manually with a comment pointing
at the divergence memory.

**pbxproj (19 regions):**
- Dropped all Tidepool `.strings` PBXFileReferences and PBXBuildFiles
- Kept DIY's `.xcstrings` references and `LOCALIZATION_PREFERS_STRING_CATALOGS = YES`
- Kept Tidepool's new Media/Transcript and `TimeInterval+Timecode.swift` references
- Dropped references to the 4 source files deleted in this merge
- Pre-existing `XCRemoteSwiftPackageReference "LoopAlgorithm"` in HEAD was left alone
  (not part of this merge; same as 2026-03-10)
- Final state: 1898 `{` / 1898 `}`, `xcodebuild -list` parses

### Loop — 3 pbxproj regions only (no source conflicts)

- Regions 1 + 2: both sides added a Swift file at the same insertion point —
  kept both `ContentMargin.swift` (DIY) and `PresetPerformanceHistoryView.swift` (Tidepool).
- Region 3: dropped Tidepool's `.strings` refs (ru/de InfoPlist/Localizable/ckcomplication);
  kept Tidepool's new Swift files (`RequiredVersionUpdateView`, `AutomationHistoryEntry`,
  `AutomationHistoryEntryTests`, `LoopCircleView`).
- Cleaned up 3 orphaned variant-group children at lines ~4088, 4147, 4166 that
  referenced the dropped `.strings` FileReferences.

### Plugins (Tier 3) — pbxproj patterns

For 11 of the 15 plugin merges, the *only* conflict was the standard
`LOCALIZATION_PREFERS_STRING_CATALOGS = YES` line in the Debug+Release
XCBuildConfiguration blocks. All resolved by keeping DIY's setting.

Notable plugin-specific cleanup:
- **CGMBLEKit**: dropped a duplicate array-form `LD_RUNPATH_SEARCH_PATHS` entry
  (string form remains below).
- **dexcom-share-client-swift**: cleaned up an orphaned `Localizable.strings`
  children-reference in the `ShareClient` PBXGroup that had no PBXFileReference
  declaration.
- **TidepoolService**: 4 conflict regions — kept DIY's `.xcstrings` PBXBuildFiles
  and PBXFileReferences (the 4 IDs are properly wired into PBXGroup children
  and PBXResourcesBuildPhase); dropped 10 Tidepool `.strings` FileReferences.

### Plugin source conflicts (the 5 repos that had them)

| Repo / File | Resolution |
|---|---|
| OmniKit / `OmnipodPumpManager.swift` | 3 regions keep DIY (`isSignalLost(at:lastPumpDataReportDate:)` reentrant-lock fix from commit `924f10d`); 3 regions take Tidepool (`setState` → `mutateState` Swift 6 migration). |
| OmniBLE / `OmniBLEPumpManager.swift` | 3 regions keep DIY (reentrant-lock fix `e9425ad`); region at line 2221 keep DIY (`completion(.communication(error))` error style — Tidepool's do/catch refactor cannot be cleanly applied to the conflict region alone; `decisionId` tracking already present in DIY's `setTempBasal` call); region at line 2722 **manual merge** (preserve DIY suspend-time-expired special case from Pod Keep Alive #165 + adopt Tidepool's properly-indented `try await withCheckedThrowingContinuation`); 3 regions take Tidepool (`mutateState`). |
| MinimedKit / `MinimedPumpManager.swift` | All 3 regions keep DIY — preserves CAGE/IAGE tracking (commit `ff07802`); the third region was Tidepool adding a duplicate `isInoperable` property that DIY already had elsewhere in the file. |
| MinimedKit / `MinimedKitUI/Views/MinimedPumpSettingsViewModel.swift` | Take Tidepool (trivial whitespace). |
| TidepoolService / `TidepoolServiceKit/Extensions/DoseEntry.swift` | Both sides changed import ordering; pre-staged resolution kept both → duplicate `import LoopAlgorithm`. Follow-up commit `5f6a064` deduped. |
| NightscoutService / `NightscoutServiceKit/NightscoutService.swift` | Keep DIY — preserves the 60-line APNS response feature (`RemoteNotificationResponseManager`, JWT-managed return notifications) from commit `0ca2c08`. Tidepool's version is a simpler switch with no response handling. |

---

## 3. DIY divergences

See `SYNC_PROGRESS.md` "DIY Divergences" section for the canonical list. New as of this sync:

### BasalRateScheduleEditor max-basal filtering

A DIY user (OmniBLE/Dash) reported being able to set basal schedule entries above
their configured `maximumBasalRatePerHour`. The cause was that DIY had inherited
Tidepool's PR #734 (LOOP-5767, "Basal schedule editor should ignore max basal rate",
merged 2026-02-27) in the 2026-03-10 sync, which changed the convenience initializer
in `BasalRateScheduleEditor` to pass `maximumBasalRate: nil`, disabling the picker-side
filter.

DIY explicitly rejects this Tidepool change. Restored
`maximumBasalRate: therapySettingsViewModel.therapySettings.maximumBasalRatePerHour`
with an inline comment pointing at `memory/divergence_basal_max_filter.md`. On
2026-05-11 sync, auto-merge silently reverted this fix; manual restoration was needed
and a divergence comment was added to defend it on future syncs.

---

## 4. Items to verify post-build

- **OmniBLE temp basal error reporting:** kept DIY's `completion(.communication(error))`
  pattern; verify error messages still surface correctly to Loop on temp basal failures.
- **Mock simulator features:** ensure simulator pump/CGM settings still render under
  `allowDebugFeatures` flag in debug builds.
- **APNS responses (NightscoutService):** verify remote command feedback notifications
  still flow end-to-end.
- **Basal schedule editor (OmniBLE / Dash):** verify the originally reported bug is
  resolved — entries above the configured max basal should not be selectable.
- **Lokalise translations:** `InsulinType.swift` lost DIY's detailed insulin
  descriptions in favor of Tidepool's simpler combined Fiasp/Lyumjev case. Next
  Lokalise pull should repopulate.

---

## 5. Reverting to `dev` after upgrading (Core Data) — usually works, but data-dependent

The shared LoopKit Core Data store (glucose, dose, carb, dosing decisions — all in one
`Model.sqlite` in the app group) is migrated forward from **Modelv4** to **Modelv6** on
first launch of the sync build. `dev` only ships model versions up to **Modelv4**.

Contrary to an earlier "forward-only / can't go back" assumption, **`dev` can open the
v6 store in place**: Core Data's automatic lightweight migration *downgrades* it back to
`dev`'s Modelv4. The v6→v4 changes are inferrable — the v6-only attributes (`programmedUnits`,
`decisionId`, `id`, …) are optional and simply dropped, and `deliveredUnits` shares the
underlying `ZVALUE` column with v4's `value` via `elementID="value"`. (Verified with a
Core Data round-trip: create a v4 store → migrate to v6 with the sync model → open with the
dev model — succeeds.)

**The catch — it's data-dependent.** `dev`'s `CachedInsulinDeliveryObject.value` is
**mandatory**; v6's `deliveredUnits` is **optional**. The inferred downgrade maps
`deliveredUnits → value`, so:
- A store that was **just upgraded** (every row migrated from v4, where `value` was required
  and non-null) downgrades cleanly — `dev` opens it. *This is why a tester who upgraded and
  immediately went back to `dev` in place saw it "just work."*
- Once the sync build **records a dose with a null `deliveredUnits`** (e.g. in-progress/mutable
  or programmed-only entries), the downgrade fails: Core Data throws `NSCocoaErrorDomain`
  **134110** — *"missing attribute values on mandatory destination attribute"* —
  `addPersistentStore` fails and `PersistenceController` lands in `.error`, leaving the app
  non-functional. You then must **delete + reinstall** `dev`, which wipes the local cache; it
  rebuilds from HealthKit (the long-term history lives there, not in this store).

So going back to `dev` in place is fine right after upgrading, but gets unreliable the longer
the sync build runs (more chance of a null-`deliveredUnits` row). The v6 data is never wiped
from disk, so reinstalling the sync build always reads it again.

**Forward migration preserves insulin data.** The v4→v6 mapping originally dropped the
old single `value` attribute (auto-generated, name-based mappings had no destination),
zeroing cached bolus/basal amounts and understating IOB. `CachedInsulinDeliveryObjectMigrationPolicy`
now copies `value` → `deliveredUnits` (and `programmedUnits` for boluses); basal *rates*
already carry over via `scheduledBasalRate`/`programmedTempBasalRate`. Note this only fixes
the forward path — installs that already migrated on a build *without* the policy have
already-dropped values that this cannot recover (they read as 0).
