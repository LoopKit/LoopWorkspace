# Tidepool → LoopKit DIY Sync — 2026-03-10

**Branch:** `tidepool-sync/2026-03-10` (all 18 repos)
**Build status:** ✅ Compiles clean (verified 2026-03-12)

This document describes the changes introduced by syncing the Tidepool fork of Loop
back into DIY, the conflicts encountered during that merge, and the
decisions made to resolve them.

> **Update (2026-05-20) — read before relying on the LoopAlgorithm decisions below.**
> A follow-up sync landed on 2026-05-11; see
> [`tidepool-sync-2026-05-11.md`](tidepool-sync-2026-05-11.md) for that round.
>
> One major decision recorded in this doc has since been **reversed**: §3 states that
> DIY keeps LoopAlgorithm embedded *inline* inside LoopKit and *omits* the
> `XCRemoteSwiftPackageReference "LoopAlgorithm"` (see "TidepoolService: import
> LoopAlgorithm — Removed" and the pbxproj rules table). As of the 2026-05-11 sync, DIY
> instead consumes the **`tidepool-org/LoopAlgorithm` Swift package** directly — pinned
> in the workspace `Package.resolved` — and the inline `LoopKit/LoopAlgorithm/` copies
> (`LoopAlgorithm.swift`, `LoopPredictionOutput.swift`, `ExponentialInsulinModel.swift`)
> were deleted (LOOP-4781). `import LoopAlgorithm` is therefore present again where this
> doc says it was removed. Where the two docs disagree on LoopAlgorithm packaging, the
> 2026-05-11 doc is authoritative.

---

## Table of Contents

1. [New Features from Tidepool](#1-new-features-from-tidepool)
2. [Conflicts Encountered](#2-conflicts-encountered)
3. [Conflict Resolution Decisions](#3-conflict-resolution-decisions)
4. [DIY Features Preserved](#4-diy-features-preserved)
5. [Post-Merge Fixes](#5-post-merge-fixes)
6. [Testing Notes](#6-testing-notes)

---

## 1. New Features from Tidepool

### LoopAlgorithm — A New Architecture for DIY

#### Background: What Changed and Why

DIY Loop previously embedded algorithm logic directly
inside `LoopKit` as an inline copy (`LoopKit/LoopKit/LoopAlgorithm/`), and effects
calculations were distributed across the data store layer — `CarbStore` computed carb
effects, `DoseStore` computed insulin effects, and `GlucoseStore` computed glucose momentum
and retrospective correction. `LoopDataManager` orchestrated these by calling each store
asynchronously and stitching the results together. The central `LoopAlgorithm` type was
a Swift `actor` — a stateful, async object.

This sync introduces the **LoopAlgorithm Swift Package** as an actual dependency, replacing
that architecture with something fundamentally different.

#### The New Design: Functional and Stateless

The package reconceives the algorithm as a **pure function**: given a complete snapshot of
the user's current state, produce a complete output. No stores, no CoreData, no HealthKit,
no async, no side effects.

```
AlgorithmOutput = LoopAlgorithm.run(input: AlgorithmInput)
```

`LoopAlgorithm` is now declared as a `caseless enum` — it cannot be instantiated. All
methods are static. There is no mutable state. The same input will always produce the
same output.

**Input (`AlgorithmInput` protocol)** is a value-type snapshot containing everything the
algorithm needs:

| Field | Description |
|-------|-------------|
| `glucoseHistory` | Recent CGM readings |
| `doses` | Insulin delivery history (basal + boluses) |
| `carbEntries` | Active carb entries |
| `basal` | Scheduled basal rate timeline |
| `sensitivity` | ISF timeline |
| `carbRatio` | ICR timeline |
| `target` | Glucose target range timeline |
| `suspendThreshold` | Low glucose suspend threshold |
| `maxBolus` | Safety limit |
| `maxBasalRate` | Safety limit |
| `maxActiveInsulinMultiplier` | Max IOB cap as multiple of maxBolus (default 2×) |
| `carbAbsorptionModel` | Parabolic, linear, or piecewise linear |
| `recommendationType` | Temp basal, automatic bolus, or manual |
| `useIntegralRetrospectiveCorrection` | IRC vs standard RC |
| `gradualTransitionsThreshold` | Threshold for gradual effect ramping |

**Output (`AlgorithmOutput`)** is a complete value type containing everything produced:

| Field | Description |
|-------|-------------|
| `recommendationResult` | `Result<LoopAlgorithmDoseRecommendation, Error>` — temp basal and/or bolus |
| `predictedGlucose` | Full glucose prediction curve |
| `effects` | Broken-out insulin, carb, momentum, RC, counteraction effects |
| `dosesRelativeToBasal` | Each dose expressed relative to scheduled basal |
| `activeInsulin` | Current IOB |
| `activeCarbs` | Current COB |

The `effects` field (`LoopAlgorithmEffects`) exposes every intermediate calculation —
insulin effect curve, carb effect curve, carb absorption status per entry, retrospective
correction, glucose momentum, insulin counteraction velocities, and retrospective glucose
discrepancies. Previously these intermediate values were scattered across store callbacks
and ephemeral local variables inside `LoopDataManager`.

#### Why This Matters for DIY

**Testability.** Because the algorithm is a pure function over value types, tests require
no mocks, no CoreData stack, no async machinery. A test is just:

```swift
let input = AlgorithmInputFixture(...)  // or decoded from JSON
let output = LoopAlgorithm.run(input: input)
XCTAssertEqual(output.predictedGlucose, expected)
```

Fixtures can be serialized to and from JSON, making it trivial to capture a real-world
scenario and turn it into a regression test. The package ships with JSON fixture files
for glucose math, carb math, and dosing scenarios.

**Portability.** Removing HealthKit and CoreData as dependencies means the algorithm can
run anywhere Swift runs — on a server, in a command-line tool, in a simulation, or in
tests — without needing a full iOS stack underneath it.

**Clarity.** Previously, understanding what went into a dosing decision required tracing
through multiple async callbacks across multiple store classes. Now the entire decision
lives in one call with explicit inputs and outputs.

#### What the Package Replaced vs. What Was Already There

| Aspect | Before (DIY inline) | After (LoopAlgorithm package) |
|--------|--------------------|-----------------------------|
| `LoopAlgorithm` type | `public actor` (stateful, async) | `public enum` (no state, static methods only) |
| Entry point | `generatePrediction(input:startDate:) throws` | `run(input:) -> AlgorithmOutput` (non-throwing; errors in Result) |
| Effects calculation | Distributed across `CarbStore`, `DoseStore`, `GlucoseStore` | All in `LoopAlgorithm.generatePrediction(...)` static methods |
| Error handling | `throws` propagated through async chain | `Result<_, Error>` in output struct |
| Effects exposed | 5 fields (insulin, carbs, RC, momentum, counteraction) | 8 fields (adds carbStatus, retrospective discrepancies, total RC magnitude) |
| Error cases | 2 (`missingGlucose`, `incompleteSchedules`) | 7 (granular: glucose too old, incomplete timeline, sensitivity window, etc.) |
| Unit types | `HKUnit` / `HKQuantity` (HealthKit) | `LoopUnit` / `LoopQuantity` (custom, no HealthKit import) |
| Dependencies | HealthKit, CoreData | None (pure Swift) |
| Testability | Required mocked async stores | Pure value types; JSON fixture files included |

#### Specific Changes in This Sync's LoopAlgorithm Version

On top of the architectural shift, the version of LoopAlgorithm synced here includes
several algorithmic and API improvements made by Tidepool since the package was established:

| Change | Details |
|--------|---------|
| **Gradual effect transitions** | Insulin and carb effects ramp up gradually at the start of absorption rather than stepping immediately to full effect, producing smoother prediction curves (PR #23) |
| **Configurable max active insulin multiplier** | `maxActiveInsulinMultiplier` on `AlgorithmInput` caps max IOB as a multiple of `maxBolus`; defaults to 2× (LOOP-5502, PR #22) |
| **Carb absorption model selection** | `carbAbsorptionModel` field on input allows runtime selection of parabolic, linear, or piecewise-linear absorption modeling (PR #21) |
| **AutomaticDoseRecommendation backward decode fix** | Decoding old stored recommendations without `basalAdjustment` field no longer crashes (PR #20) |
| **ISF fix during mid-absorption** | Corrects which ISF value is used during active carb absorption for more accurate corrections (PR #19) |
| **TempBasalRecommendation direction** | `.direction` field (increase / decrease / unchanged) added to `TempBasalRecommendation`; enables directional UI feedback (LOOP-5295, PR #18) |
| **Swift 6 Sendable conformances** | `AbsoluteScheduleValue` and other types marked `Sendable` throughout (PR #14) |
| **Glucose math tests moved here** | `GlucoseMathTests.swift` and JSON fixtures moved from LoopKit into this package where they belong (PR #24) |

### Loop (App) — Presets Overhaul

Presets have been substantially redesigned. The changes span the data model, safety
guardrails, manager architecture, UI, and Watch app. This is the most user-visible
change in this sync.

#### Before: Override Presets in DIY Loop

In prior DIY Loop, override presets were simple `TemporaryScheduleOverridePreset` objects
stored in `LoopSettings.overridePresets`. Each preset had a name, symbol, correction range,
insulin sensitivity multiplier, and duration. There was no preset type system — all presets
were generic overrides. Users could set a target range and/or an ISF multiplier, activate
a preset from the toolbar, and it would run until it expired or was manually cancelled.

DIY did have a limited scheduling concept: the UIKit `AddEditOverrideTableViewController`
exposed a **Start Time** row that allowed setting a future start time for an override.
If `startDate > Date()`, the override was queued as a one-shot future event and shown in
a "SCHEDULED PRESET" section in `OverrideSelectionViewController`. There was no
day-of-week recurrence, no system alert to prompt the user at the scheduled time, and
no persistence of the schedule on the preset definition itself — the delay was set
per-activation, not stored on the preset.

There were no guardrails specific to presets, no required training, and no safety
mitigations for extreme settings.

#### After: SelectablePreset Type System

Presets are now modeled as a typed enum, `SelectablePreset`, with three distinct cases:

```swift
enum SelectablePreset {
    case preMeal(range: ClosedRange<LoopQuantity>)
    case activity(ActivityPreset)
    case custom(TemporaryPreset)
}
```

Each case has different capabilities enforced at the type level:

| Capability | Pre-Meal | Activity | Custom |
|-----------|---------|----------|--------|
| Adjust correction range | ✅ | ✅ | ✅ |
| Adjust insulin needs (ISF multiplier) | ❌ | ✅ | ✅ |
| Set duration | ❌ (ends when carbs entered) | ✅ | ✅ |
| Indefinite duration | ❌ | ❌ | ✅ |
| Rename | ❌ | ❌ | ✅ |
| Schedule (day/time) | ❌ | ✅ | ✅ |
| Delete | ❌ | ❌ | ✅ |

#### Activity Presets — Evidence-Based Defaults

A new `.activity` case provides four pre-defined activity presets with evidence-based
default insulin reduction values. These appear in the Presets list for all users and
can be customized but not deleted:

| Activity | Default Target Range | Default Insulin Needs |
|----------|--------------------|-----------------------|
| Jogging | 150–170 mg/dL | 21% of normal |
| Biking | 150–170 mg/dL | 23% of normal |
| Walking | 150–170 mg/dL | 23% of normal |
| Strength Training | 150–170 mg/dL | 37% of normal |

The `insulinNeedsScaleFactor` (e.g. 0.21 for jogging) scales all three delivery parameters
simultaneously — basal rate, carb ratio, and ISF — so that "need 21% of normal insulin"
is expressed as a single unified control rather than three separate adjustments.

When a user modifies an activity preset from its defaults, a "modified" indicator is shown
in the UI (`isModifiedFromDefault`).

#### New Safety Feature: High Insulin Needs Mitigation (LOOP-5439)

When a preset's `insulinNeedsScaleFactor` exceeds 165% (the upper recommended guardrail
bound), a safety mitigation is automatically applied: the effective correction range is
clamped to a minimum of **110 mg/dL**, regardless of what the user set.

```swift
// TemporaryScheduleOverride.effectiveCorrectionRangeDuring(scheduledRange:)
if veryHighInsulinNeeds {
    return range.clampedTo(atLeast: highInsulinNeedsMitigationCorrectionRangeLimit) // 110 mg/dL
}
```

This prevents the dangerous combination of very high insulin delivery AND a very low
correction target. Even if a user sets a correction range of 80 mg/dL while also
setting insulin needs to 180%, the system will use 110 mg/dL as the effective floor.
The UI makes this behavior visible to the user.

#### Preset Guardrails

| Setting | Absolute Bounds | Warning | Recommended |
|---------|----------------|---------|-------------|
| Insulin Needs | 15%–200% | 15%–190% | 15%–165% |
| Custom preset correction range | Suspend threshold–250 mg/dL | Suspend threshold–180 mg/dL | — |
| Pre-meal correction range | Suspend threshold–130 mg/dL | Dynamic (based on scheduled range) | — |

The pre-meal guardrail is dynamic: the recommended upper bound is capped at the lower
bound of the user's current correction range schedule, encouraging a pre-meal target
that is meaningfully lower than their normal target. Pre-meal maximum is hard-capped
at 130 mg/dL absolute.

Guardrail violations are surfaced inline during editing with color-coded warnings
(yellow = outside recommended, red = outside absolute) and a `GuardrailWarning` view
shown before saving.

#### TemporaryPresetsManager — Separated from LoopDataManager

Preset lifecycle management has been extracted from `LoopDataManager` into a dedicated
`TemporaryPresetsManager` (`@MainActor @Observable`). It owns:

- The active `scheduleOverride` (with `didSet` observers for activation/deactivation events)
- `presetHistory` (a `TemporaryScheduleOverrideHistory` for IOB/ISF history reconstruction)
- Override intent observer (Siri shortcut handling)
- Preset scheduling and reminder alerts
- `basalRateScheduleApplyingOverrideHistory`, `insulinSensitivityScheduleApplyingOverrideHistory`,
  `carbRatioScheduleApplyingOverrideHistory` — used by the algorithm to reconstruct what
  the effective schedules were over the past few hours, accounting for any presets that were
  active during that window

#### Safety Alert: Indefinite Preset Reminder

When a custom preset is started with indefinite duration, a repeating alert fires every
24 hours reminding the user it is still active:

> *"[Preset Name] has been active for more than 24 hours. Make sure you still want it
> enabled, or turn it off."*

This alert is time-sensitive (interrupts Focus modes) and repeats until the preset is
deactivated. When the preset is deactivated, the alert is retracted.

#### Preset Scheduling — Significantly Expanded

DIY Loop already had a basic scheduling concept: a **one-shot future start time**
that could be set per-activation in the old UIKit override editor. That delayed the
activation of an override to a future time, but the schedule was not stored on the
preset, could not repeat, and generated no alert to remind the user.

The new scheduling system stores the schedule on the preset definition itself and adds
full day-of-week recurrence. Presets can now be scheduled to start at a specific time,
optionally repeating on selected days of the week (`PresetScheduleRepeatOptions`:
Sunday through Saturday as an `OptionSet`). When a scheduled preset's start time
approaches, a time-sensitive system alert fires asking the user whether to start it:

> *"Would you like to start your [Preset Name] preset? This will end any active preset."*

The alert offers "Don't Start" (dismiss) and "Yes, Start Now" (activates the preset).
The schedule is re-armed after each activation to fire again at the next scheduled time.

| Aspect | Old DIY | New (Tidepool) |
|--------|---------|----------------|
| Schedule stored on preset | ❌ (set per-activation) | ✅ |
| One-shot future start | ✅ | ✅ |
| Day-of-week recurrence | ❌ | ✅ (any combination of days) |
| System alert at scheduled time | ❌ | ✅ (time-sensitive) |
| User confirm/dismiss in alert | ❌ | ✅ |

#### Required Training Before Creating Presets

New users must complete a required in-app training sequence (`PresetsTraining`) before
they can create custom presets. The training is gated by `PresetsTrainingCompletion`,
which tracks progress through 5 chapters persisted in `UserDefaults`:

1. **Customizing Presets** — How overall insulin %, correction range, and duration work
2. **Illness** — How to use presets when sick (illness typically increases insulin needs)
3. **Daily Activities** — How to use presets for non-exercise activities
4. **Exercise** — How to use presets for exercise (aerobic vs. anaerobic differences)
5. **Training Complete** — Summary

If a user attempts to create a new preset without completing training, an alert blocks
the action and offers to start the training flow. The training can be reviewed at any
time from the Presets screen. (Debug builds allow skipping chapters via `allowDebugFeatures`.)

#### Presets UI

The Presets screen (`PresetsView`) is now a dedicated full-screen view accessible from
Settings, with:

- **Active preset card** — shown at the top when a preset is running, with expected end
  time and tap-to-manage
- **All Presets list** — sortable by name, last used, or date created (ascending/descending)
- **Training card** — shown until training is complete; blocks the "+" create button
- **Presets Performance History** — a history view showing past preset activations
- **Review Training** option in the Support section

Individual preset cards (`PresetCard`) display the preset's icon, name, duration, insulin
needs, and correction range, with guardrail-aware color coding.

#### Other Loop (App) Changes

| Feature | Details |
|---------|---------|
| **Active Preset Banner on CarbEntryView** | Shows the active override preset while entering carbs (LOOP-5432) |
| **DeeplinkView widget component** | Replaces `SystemActionLink.swift`; cleaner implementation of widget deep-link action buttons |
| **roundBasalRate utility** | `DeviceDataManager.roundBasalRate(unitsPerHour:)` added for consistent basal rate rounding (LOOP-5558) |
| **schedulePresets storage** | `NSUserDefaults` now persists schedule presets (LOOP-4754) |
| **defaultEnvironment key** | New `NSUserDefaults` key for Tidepool service environment selection (LOOP-5153) |
| **Granular alert permission warnings** | `AlertPermissionsChecker` (existing since 2021) updated: single "safety notifications off" alert replaced with 5 granular cases distinguishing `notificationsDisabled`, `criticalAlertsDisabled`, `timeSensitiveDisabled`, and combinations thereof — each with tailored messaging |
| **iOS 17+ onChange API** | `onChange(of:)` calls updated to the two-parameter form throughout views |
| **XCTest environment guard** | `AppDelegate` skips full initialization when running under XCTest |
| **Async/await in RemoteDataServicesManager** | `uploadCgmEventData` migrated from callback-based to `async/await Task` pattern |
| **"Save as Favorite" conditional display** | CarbEntryView only shows "Save as favorite" when no existing favorite food is selected |
| **GeometryReader removed from BolusEntryView** | Cleaner layout; fixes safe area issues |

### Pump Drivers (OmniKit / OmniBLE / MinimedKit)

| Feature | Details |
|---------|---------|
| **Decision ID on pump events** | `decisionId: UUID?` added to dose entries and pump events across OmniKit, OmniBLE, and MinimedKit — links pump commands to the algorithm decision that triggered them (LOOP-5295) |
| **Pump inoperable state** | `inSignalLoss` and `isInoperable` properties added to LibreTransmitter, OmniBLE, and OmniKit for consistent inoperable-device reporting (LOOP-4801) |
| **acknowledgeAlert async migration** | OmniBLE and OmniKit: `acknowledgeAlert` migrated from completion-handler to `async throws` |

### Services

| Feature | Details |
|---------|---------|
| **TidepoolService: decisionId** | `DoseEntry` now carries `decisionId` for Tidepool upload correlation |
| **NightscoutService: decisionId** | Same `decisionId` support added for Nightscout upload |

---

## 2. Conflicts Encountered

### LoopAlgorithm
**No conflicts.** Because DIY Loop had never incorporated this package before, there were
no diverging commits on the DIY side — the repo had been tracking `LoopKit/LoopAlgorithm`
main without any local modifications. The merge was a clean fast-forward: Tidepool was
29 commits ahead, all of which applied without conflict.

---

### LoopKit
**16 conflicts** across Swift source and project files.

| File | Conflict Type |
|------|--------------|
| `LoopKit.xcodeproj/project.pbxproj` | File references, deployment target, `.strings` vs `.xcstrings` |
| Multiple algorithm files in `LoopKit/LoopAlgorithm/` | HealthKit → LoopUnit type migration |
| Various type definition files | API additions on both sides |

---

### Loop (App)
**33 conflicts** across 30+ files — the most complex repo in the sync.

| Category | Count | Files |
|----------|-------|-------|
| Modify/delete | 3 | `SystemActionLink.swift`, `FavoriteFoodDetailView.swift`, `Main.strings` |
| Swift source | 22 | Managers, ViewControllers, ViewModels, Views, Core/Tests |
| xcschemes | 7 | All scheme files |
| project.pbxproj | 1 | Build settings, file references |

**Deepest conflict: `LoopDataManager.swift`** — 7 conflict hunks due to a fundamental architectural divergence:
- Tidepool migrated to Swift Concurrency (`@MainActor async/await`, `Task {}`)
- DIY added Live Activity support and retained `dataAccessQueue`-based threading

---

### Peripheral Repos (9 repos)
**pbxproj-only conflicts** — no Swift source conflicts.

| Repo | Conflict |
|------|----------|
| CGMBLEKit | project.pbxproj |
| G7SensorKit | project.pbxproj |
| dexcom-share-client-swift | project.pbxproj |
| NightscoutRemoteCGM | project.pbxproj |
| RileyLinkKit | project.pbxproj |
| LoopSupport | project.pbxproj |
| LoopOnboarding | project.pbxproj |
| AmplitudeService | project.pbxproj |
| LogglyService | project.pbxproj |

**Swift source conflicts in plugin repos:**

| Repo | Files | Conflict |
|------|-------|---------|
| OmniKit | `OmnipodPumpManager.swift`, `PodCommsSessionTests.swift` | decisionId, async acknowledgeAlert |
| OmniBLE | `OmniBLEPumpManager.swift`, `PodState.swift` | decisionId, slot6SuspendTimeExpired guard, async acknowledgeAlert |
| MinimedKit | `MinimedPumpManager.swift` | decisionId, async Task, updateLastEventDates |
| LibreTransmitter | `LibreTransmitterManagerV3.swift` | inSignalLoss/isInoperable properties |
| TidepoolService | `DoseEntry+Tidepool.swift` | decisionId, import LoopAlgorithm |
| NightscoutService | `NightscoutService.swift` | decisionId, RemoteNotificationResponseManager |

---

## 3. Conflict Resolution Decisions

### LoopAlgorithm: HealthKit → LoopUnit Migration

**Conflict:** Tidepool replaced `HKUnit`/`HKQuantity` HealthKit types throughout the algorithm
with custom `LoopUnit`/`LoopQuantity` types. LoopKit DIY's inline algorithm copy still used
HealthKit types.

**Decision:** Accept Tidepool's type migration in full. `LoopUnit` and `LoopQuantity` are
functionally equivalent and improve portability. The inline LoopKit algorithm code was updated
to match. The `HKUnit.swift` and `HKQuantity.swift` extensions were removed.

---

### Loop: `LoopDataManager.swift` — Concurrency Migration

**Conflict:** The deepest conflict in the sync. Tidepool restructured `LoopDataManager` around
Swift Concurrency — replacing `dataAccessQueue.async` blocks with `Task { @MainActor in }` and
`await`-based calls. DIY had added `LiveActivityManager` integration woven into the same
`dataAccessQueue` paths, and retained `lockedSettings`/`mutateSettings()`/`loop()`/`loopInternal()`/`finishLoop()`.

**Decision:**
- Adopt Tidepool's `Task { @MainActor in await updateDisplayState() }` pattern as the new
  threading model throughout
- Remove DIY's `dataAccessQueue`, `lockedSettings`, `mutateSettings()`, `loop()`,
  `loopInternal()`, and `finishLoop()` chain — Tidepool's async pattern replaces this
- Inject DIY's Live Activity calls into Tidepool's new `updateDisplayState()` call sites
  (hunks 3, 4, 5), so live activity updates fire from the same points the old queue callbacks did
- Adopt Tidepool's new init parameters (`analyticsServicesManager`, `carbAbsorptionModel`,
  `usePositiveMomentumAndRCForManualBoluses`, `dosingStrategySelectionEnabled`) and move
  all stored property assignments before the `overrideIntentObserver` closure to satisfy
  Swift's init-before-capture requirement

---

### Loop: `SystemActionLink.swift` — Deleted (replaced by DeeplinkView)

**Conflict:** Tidepool deleted `SystemActionLink.swift` and replaced it with `DeeplinkView.swift`.
DIY had made improvements to `SystemActionLink` (widget rendering mode, active preset colors).

**Decision:** Accept the deletion and take `DeeplinkView.swift`. It provides equivalent
deeplink functionality. DIY's widget tinting improvements should be ported to `DeeplinkView`
if verified missing.

---

### Loop: `FavoriteFoodDetailView.swift` — Deleted (moved)

**Conflict:** Tidepool moved the file to `Loop/Views/Favorite Foods/FavoriteFoodDetailView.swift`.
DIY had added `String(localized:)` annotations to the original location.

**Decision:** Accept the move. The `Favorite Foods/` subfolder version already exists in DIY's
tree. DIY's localization annotations should be verified against the new location.

---

### Loop: `Main.strings` — Keep Deleted

**Conflict:** DIY deleted `Main.strings` when migrating to `.xcstrings` string catalogs.
Tidepool modified `Main.strings` (never migrated).

**Decision:** Keep the deletion. DIY's `.xcstrings` format is the forward path.

---

### Loop: `AppDelegate.swift` — Keep Both

**Conflict:** DIY added diagnostic logging setup; Tidepool added an XCTest environment guard
(skips full initialization during unit tests).

**Decision:** Keep both — they are independent and complementary additions.

---

### Loop: `DeviceDataManager.swift` — Keep Both

**Conflict:** DIY added a diagnostic report function with submodule SHAs (`b6e88416`); Tidepool
added `roundBasalRate(unitsPerHour:)` (`184ea75a`). Both additions were at adjacent but
non-overlapping locations.

**Decision:** Keep both — distinct features, no overlap.

---

### Loop: `SettingsView.swift` — Keep Both

**Conflict:** DIY had a Favorite Foods sheet; Tidepool added a Presets sheet.

**Decision:** Keep both sheets — separate features serving different user needs.

---

### Loop: `NSUserDefaults.swift` — Keep Both

**Conflict:** DIY added `liveActivity` key (`LiveActivitySettings`); Tidepool added
`defaultEnvironment` key.

**Decision:** Keep both — entirely separate features (Live Activity vs Tidepool service config).

---

### Loop: `WidgetBackground.swift` — Take Tidepool's

**Conflict:** Tidepool uses `Color.widgetBackground` extension; DIY used `Color("WidgetBackground")`
string-based lookup.

**Decision:** Take Tidepool's — the extension is safer (compile-time vs. runtime string lookup).

---

### Loop: `ContentMargin.swift` — Keep DIY's

**Conflict:** Both sides had identical implementation; only the copyright year differed.

**Decision:** Keep DIY's copyright date.

---

### OmniBLE: `slot6SuspendTimeExpired` Guard — Keep DIY's

**Conflict:** Tidepool's version of OmniBLE removed the `slot6SuspendTimeExpired` safety check
that prevents acknowledging a pod alert when the pod is suspended.

**Decision:** Preserve DIY's guard. This is a safety-critical check: if the pod is suspended,
the pod should continue beeping until the user resumes it. Silently acknowledging in this state
could mask a dangerous condition.

---

### MinimedKit: `updateLastEventDates` — Keep DIY's

**Conflict:** Tidepool's MinimedKit removed `updateLastEventDates()`, a function DIY uses to
track cannula age and insulin age for display in the UI.

**Decision:** Preserve DIY's implementation. Cannula/insulin age tracking is a meaningful DIY
feature with no equivalent in Tidepool's version.

---

### NightscoutService: `RemoteNotificationResponseManager` — Keep DIY's

**Conflict:** Tidepool's NightscoutService version removed `RemoteNotificationResponseManager`,
which handles feedback notifications for remote commands sent via Nightscout.

**Decision:** Preserve DIY's implementation. Remote command feedback is a core DIY feature
(remote bolus, temp basal, etc.) that has no Tidepool equivalent.

---

### TidepoolService: `import LoopAlgorithm` — Removed

**Conflict:** Tidepool's `TidepoolService` imports `LoopAlgorithm` as a Swift package. DIY does
not include the `LoopAlgorithm` package in the workspace — the algorithm is embedded inline
inside `LoopKit`.

**Decision:** Remove `import LoopAlgorithm` from `TidepoolService`. In DIY, the types it
provided come from `LoopKit` which is already imported.

---

### All Repos: project.pbxproj

Applied consistent rules across all 18 repos:

| Setting | Decision | Rationale |
|---------|----------|-----------|
| `IPHONEOS_DEPLOYMENT_TARGET` | Take higher value (17.0) | Both sides are raising it; take the further-along value |
| `LOCALIZATION_PREFERS_STRING_CATALOGS` | Keep `YES` | DIY's xcstrings migration |
| `.strings` file references | Drop Tidepool's | DIY deleted these files; re-adding references causes build errors |
| `.xcstrings` references | Keep DIY's | Current localization format |
| `XCRemoteSwiftPackageReference "LoopAlgorithm"` | Omit | DIY embeds algorithm inline in LoopKit |
| New Swift file references | Keep both sides' additively | Both sides added files; all should be included |
| PBXGroup `children`/`files` duplicates | Deduplicate after merge | "Keep both" strategy on adjacent group entries can produce duplicates |
| Bundle IDs (`com.loopkit.*` / `com.tidepool.*`) | Keep both | Apply to different build targets |

---

## 4. DIY Features Preserved

| Feature | Repo | Notes |
|---------|------|-------|
| **Live Activity** (`LiveActivityManager`) | Loop | Woven into Tidepool's new `updateDisplayState()` async calls |
| **Diagnostic report with submodule SHAs** | Loop | Kept alongside Tidepool's `roundBasalRate` addition |
| **Favorite Foods sheet** | Loop | Kept alongside Tidepool's new Presets sheet |
| **liveActivity NSUserDefaults key** | Loop | Kept alongside Tidepool's `defaultEnvironment` key |
| **slot6SuspendTimeExpired safety guard** | OmniBLE | Safety-critical; not present in OmniKit (different pod hardware) |
| **updateLastEventDates** | MinimedKit | Cannula/insulin age tracking |
| **RemoteNotificationResponseManager** | NightscoutService | Remote command feedback |
| **`.xcstrings` localization** | All repos | DIY's Xcode 15+ string catalog format |
| **Community CGM integrations** | CGMBLEKit, LibreTransmitter, etc. | Open-source CGM drivers not in Tidepool |
| **Open-source pump drivers** | OmniKit, OmniBLE, MinimedKit, RileyLinkKit | All preserved |

---

## 5. Post-Merge Fixes

After the mechanical merge, the following additional fixes were required to achieve a
clean build:

### `LoopDataManager.swift` — Init Property Ordering (Loop)

**Problem:** Swift requires all stored properties to be initialized before `self` can be
captured in a closure. The `overrideIntentObserver` closure captured `self`, but several
stored properties (`analyticsServicesManager`, `carbAbsorptionModel`,
`usePositiveMomentumAndRCForManualBoluses`, `automationHistory`,
`publishedMostRecentGlucoseDataDate`, `dosingStrategySelectionEnabled`,
`publishedMostRecentPumpDataDate`) were assigned *after* the closure in the init.

**Fix:** Moved all stored property assignments before the `overrideIntentObserver` closure.

---

### `NSUserDefaults.swift` — Missing Closing Braces (Loop)

**Problem:** The merge introduced a structural artifact in the `liveActivity` computed property
— the closing `}}` for the `set {` block was missing.

**Fix:** Restored the two missing closing braces manually.

---

### `TidepoolServiceKit/Extensions/DoseEntry.swift` and `DeviceLogUploader.swift` — Missing `import LoopAlgorithm`

**Problem:** Both files use `AbsoluteScheduleValue` (DoseEntry.swift) and `TDeviceLogEntry`
(DeviceLogUploader.swift) from the LoopAlgorithm package, but `import LoopAlgorithm` was
incorrectly removed from both files during conflict resolution. All other ~10 files in
TidepoolServiceKit correctly import LoopAlgorithm. The omission caused build failures in
Xcode (though command-line builds may succeed due to implicit module visibility from
LoopKit.xcodeproj's LoopAlgorithm SPM dependency).

**Fix:** Restored `import LoopAlgorithm` in both files.

---

### `Loop.xcodeproj/project.pbxproj` — Structural Corruption (Loop)

**Problem:** The pbxproj resolver's "keep both" strategy on a `PBXVariantGroup` conflict
(conflict 36) produced a combined brace depth of +2 instead of 0, making the file
unparseable by Xcode.

**Root cause:** Both sides of the conflict had `brace_balance = +1`. Naively keeping both
produced `+2`, breaking the file's structure.

**Fix:**
1. Re-ran `git merge-file` on origin/dev vs merge-base vs tidepool/dev to get clean
   conflict markers
2. Applied improved resolver: checks `brace_count(ours) + brace_count(theirs)` before
   keeping both; takes OURS when the combined balance would be non-zero
3. Deduplicated 7 duplicate lines in PBXGroup `children`/`files` lists (artifact of
   "keep both" on adjacent group entries)
4. Validated with `xcodebuild -project Loop.xcodeproj -list` ✅

---

## 6. Testing Notes

### Critical paths to verify

- [ ] **Live Activity** — glucose, dosing, and carb update notifications all trigger live activity updates
- [ ] **Widget action buttons** — carbs, bolus, pre-meal, preset deeplinks work; colors correct in tinted/accented mode (DeeplinkView replaced SystemActionLink)
- [ ] **Favorite Foods** — detail view labels localized; "Save as favorite" only shown when no food selected
- [ ] **Settings** — both Favorite Foods and Presets sheets accessible
- [ ] **Bolus entry** — safe area layout correct (GeometryReader removed)
- [ ] **Presets training** — training flow completes; "+" button blocked until training done
- [ ] **Activity presets** — all 4 activity types appear; defaults are correct; "modified" indicator shows when changed
- [ ] **High insulin needs mitigation** — correction range clamped to ≥ 110 mg/dL when insulin needs > 165%
- [ ] **Indefinite preset reminder** — 24-hour alert fires when indefinite preset is active; retracts on deactivation
- [ ] **Preset scheduling** — scheduled presets alert at the correct time; "Yes, Start Now" activates correctly
- [ ] **Pre-meal guardrail** — max 130 mg/dL hard cap; recommended upper bound matches correction range lower bound
- [ ] **Active preset banner** — displays correctly on CarbEntryView when override active
- [ ] **Algorithm** — glucose predictions, ISF during carb absorption, max IOB multiplier
- [ ] **TempBasalRecommendation direction** — direction field populated in recommendations
- [ ] **Pump decision IDs** — OmniKit, OmniBLE, Minimed dose entries carry decisionId
- [ ] **Remote commands** — Nightscout remote bolus/basal feedback notifications work
- [ ] **Cannula/insulin age** — displays correctly for Minimed users (updateLastEventDates)
- [ ] **OmniBLE pod suspend safety** — suspended pod continues beeping; alert not silently acked
- [ ] **Diagnostic report** — support report includes submodule SHAs
- [ ] **App expiry alerts** — TestFlight and provisioning profile expiry handled correctly
- [ ] **Unit tests** — `LoopAlgorithmTests`, `LoopKitTests`, `LoopTests` suites pass
