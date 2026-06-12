# Tidepool → LoopKit Sync Progress

**Sync branch:** `tidepool-sync/2026-05-11`
**Source:** `tidepool-org/<repo>/dev` (or `main`)
**Target:** `LoopKit/<repo>/dev` (or `main`)
**Started:** 2026-05-11
**Last updated:** 2026-05-11

**Process doc:** [LOOPKIT_SYNC_PROCESS.md](LOOPKIT_SYNC_PROCESS.md)
**Sync log:** [docs/tidepool-sync-2026-05-11.md](docs/tidepool-sync-2026-05-11.md)
**Previous sync:** [SYNC_PROGRESS history for 2026-03-10](#) — branch merged to dev across all 18 repos

---

## Status: ✅ ALL REPOS MERGED (build verification pending)

17 repos merged, 1 noop (MixpanelService already current). All conflicts resolved; build verification in progress.

---

## Full Repo Status

| # | Repo | Base | Tidepool commits | Conflicts | Submodule commit | Status |
|---|------|------|------------------|-----------|------------------|--------|
| — | **LoopAlgorithm** | `main` | 4 (test-only) | — (pin bump) | pin → `bd1a879` | ✅ Done |
| 1 | **LoopKit** | `dev` | 409 | 18 source + 19 pbxproj | `bd30c463` | ✅ Done |
| 2 | **Loop** | `dev` | 14 | 0 source + 3 pbxproj | `76b6b1e3` | ✅ Done |
| 3 | **CGMBLEKit** | `dev` | 13 | pbxproj only (4) | `69562e7` | ✅ Done |
| 4 | **G7SensorKit** | `main` | 15 | pbxproj only (2) | `d024513` | ✅ Done |
| 5 | **dexcom-share-client-swift** | `dev` | 15 | pbxproj only (3, + orphan cleanup) | `541de2f` | ✅ Done |
| 6 | **NightscoutRemoteCGM** | `dev` | 13 | pbxproj only (2) | `b1ea9ee` | ✅ Done |
| 7 | **LibreTransmitter** | `main` | 14 | pbxproj only (3) | `c99daf1` | ✅ Done |
| 8 | **RileyLinkKit** | `dev` | 3 | pbxproj only (2) | `19f5ae8` | ✅ Done |
| 9 | **OmniKit** | `main` | 18 | OmnipodPumpManager (6 regions) + pbxproj | `b3b6080` | ✅ Done |
| 10 | **OmniBLE** | `dev` | 20 | OmniBLEPumpManager (8 regions) + pbxproj | `645e0fc` | ✅ Done |
| 11 | **MinimedKit** | `main` | 18 | MinimedPumpManager + 1 trivial + pbxproj | `f994d6e` | ✅ Done |
| 12 | **TidepoolService** | `dev` | 45 | DoseEntry + pbxproj | `5f6a064` | ✅ Done |
| 13 | **NightscoutService** | `dev` | 22 | NightscoutService + pbxproj | `1b5cded` | ✅ Done |
| 14 | **AmplitudeService** | `dev` | 6 | pbxproj only (2) | `77dae3e` | ✅ Done |
| 15 | **LogglyService** | `dev` | 6 | pbxproj only (2) | `8e18081` | ✅ Done |
| 16 | **LoopSupport** | `dev` | 11 | pbxproj only (2) | `a312dfb` | ✅ Done |
| 17 | **LoopOnboarding** | `dev` | 28 | pbxproj only (2) | `fd7e410` | ✅ Done |
| — | **MixpanelService** | `main` | 0 | — | unchanged | ✅ Noop |

LoopWorkspace superproject commit: `3d4432c` ("Bump submodule pins to tidepool-sync/2026-05-11 heads").

---

## Next Steps

1. **Compile test** — `xcodebuild build -workspace LoopWorkspace.xcworkspace -scheme Loop -destination 'platform=iOS Simulator,name=iPhone 17'`
2. **Fix any compile errors** that surface
3. **Push branches** to `loopkitdev/<repo>`
4. **Open PRs** — one per repo, `tidepool-sync/2026-05-11` → `dev` (or `main`)

---

## DIY Divergences Established This Sync

| Decision | Detail |
|---|---|
| `BasalRateScheduleEditor` enforces max basal | DIY rejects tidepool/LoopKit PR #734 (LOOP-5767). Keep `maximumBasalRate: therapySettings.maximumBasalRatePerHour`, not `nil`. See [`memory/divergence_basal_max_filter.md`](../memory/divergence_basal_max_filter.md). The DIY user-reported bug (max basal not respected on OmniBLE/Dash) is what surfaced this. |
| OmniBLE/OmniKit reentrant-lock fix | DIY's `isSignalLost(at:lastPumpDataReportDate:)` signature is preserved over Tidepool's `isSignalLost(at: Date = Date())` to avoid reentrant lock crashes under rapid status polling. |
| OmniBLE Pod Keep Alive suspend special case | DIY's `slot6SuspendTimeExpired` skip-ack guard preserved during the migration to `mutateState`. |
| MinimedKit CAGE/IAGE | DIY's `updateLastEventDates(from:)` for cannula and insulin age tracking preserved; Tidepool has no equivalent. |
| NightscoutService APNS response feature | DIY's `RemoteNotificationResponseManager` + JWT-managed return notifications preserved; Tidepool's simpler version dropped. |
| OmniBLE temp basal error handling | Kept DIY's `completion(.communication(error))` style; did not adopt Tidepool's `do { ... } catch` refactor because it cannot be cleanly applied to the conflict region alone. decisionId tracking already present in DIY. |
| CachedInsulinDeliveryObject bolus-without-units | Dropped the `assertionFailure` in `CachedInsulinDeliveryObject.dose` for a `.bolus` with neither programmedUnits nor deliveredUnits — legacy rows from an upgraded DIY install can have neither and trapped debug builds on read. Falls back to 0 (release behavior). Upstream keeps the assertion (fresh installs only); re-remove on future LoopKit syncs. |

---

## Key Patterns Carried Forward from 2026-03-10

| Decision | Detail |
|---|---|
| LoopAlgorithm as Swift Package | DIY pulls `tidepool-org/LoopAlgorithm` via workspace `Package.resolved`. Do not re-add `XCRemoteSwiftPackageReference "LoopAlgorithm"` to per-repo `.pbxproj` files. |
| `.xcstrings` over `.strings` | DIY uses Xcode 15+ string catalogs; always drop Tidepool's `.strings` PBXFileReferences and variant-group children during pbxproj conflict resolution. |
| Preserve `LOCALIZATION_PREFERS_STRING_CATALOGS = YES` | Always keep DIY side of this XCBuildConfiguration setting. |
