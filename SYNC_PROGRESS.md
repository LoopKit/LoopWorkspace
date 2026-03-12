# Tidepool → LoopKit Sync Progress

**Sync branch:** `tidepool-sync/2026-03-10`
**Source:** `tidepool-org/<repo>/dev` (or `main`)
**Target:** `LoopKit/<repo>/dev` (or `main`)
**Started:** 2026-03-10
**Completed:** 2026-03-10
**Last updated:** 2026-03-10

**Process doc:** [LOOPKIT_SYNC_PROCESS.md](LOOPKIT_SYNC_PROCESS.md)

---

## Status: ✅ ALL REPOS COMPLETE

18 repos synced, 0 conflicts remaining, ready for compile test & PR.

---

## Full Repo Status

Work proceeded in **Core → App → Plugins** order (see process doc for rationale).

| # | Repo | Base | Key Conflicts | Status | Doc |
|---|------|------|---------------|--------|-----|
| 1 | **LoopAlgorithm** | `main` | none (fast-forward) | ✅ Done | [doc](sync-docs/LoopAlgorithm.md) |
| 2 | **LoopKit** | `dev` | 16 conflicts: HK→LoopUnit types, pbxproj, .strings cleanup | ✅ Done | [doc](sync-docs/LoopKit.md) |
| 3 | **Loop** | `dev` | 33 conflicts + Swift Concurrency migration | ✅ Done | [doc](sync-docs/Loop.md) |
| 4 | **TidepoolService** | `dev` | pbxproj + DoseEntry (`import LoopAlgorithm` removed, `decisionId`) | ✅ Done | — |
| 5 | **NightscoutService** | `dev` | pbxproj + NightscoutService (RemoteNotificationResponseManager preserved, `decisionId` added) | ✅ Done | — |
| 6 | **MinimedKit** | `main` | pbxproj + MinimedPumpManager (`decisionId`, async Task, `updateLastEventDates` preserved) | ✅ Done | — |
| 7 | **LibreTransmitter** | `main` | pbxproj + `inSignalLoss`/`isInoperable` properties added | ✅ Done | — |
| 8 | **OmniBLE** | `dev` | pbxproj + OmniBLEPumpManager (6 hunks) + PodState | ✅ Done | — |
| 9 | **OmniKit** | `main` | pbxproj + OmnipodPumpManager (4 hunks) + PodCommsSessionTests | ✅ Done | — |
| 10 | **CGMBLEKit** | `dev` | pbxproj only | ✅ Done | — |
| 11 | **G7SensorKit** | `main` | pbxproj only | ✅ Done | — |
| 12 | **dexcom-share-client-swift** | `dev` | pbxproj only | ✅ Done | — |
| 13 | **NightscoutRemoteCGM** | `dev` | pbxproj only | ✅ Done | — |
| 14 | **RileyLinkKit** | `dev` | pbxproj only | ✅ Done | — |
| 15 | **LoopSupport** | `dev` | pbxproj only | ✅ Done | — |
| 16 | **LoopOnboarding** | `dev` | pbxproj only | ✅ Done | — |
| 17 | **AmplitudeService** | `dev` | pbxproj only | ✅ Done | — |
| 18 | **LogglyService** | `dev` | pbxproj only | ✅ Done | — |
| — | **MixpanelService** | `main` | already in sync, noop | ✅ Noop | — |

---

## Next Steps

1. **Compile test** — open `LoopWorkspace.xcworkspace` in Xcode and build
2. **Fix any compile errors** that surface (type mismatches, missing parameters, etc.)
3. **Push branches** — requires `GH_TOKEN` with repo write access
4. **Open PRs** — one per repo, `tidepool-sync/2026-03-10` → `dev` (or `main`)

---

## Key Architectural Decisions

See [LOOPKIT_SYNC_PROCESS.md](LOOPKIT_SYNC_PROCESS.md) for the full Golden Rule and process.

| Decision | Detail |
|---|---|
| No `import LoopAlgorithm` in TidepoolService | DIY gets types from LoopKit; LoopAlgorithm not in workspace |
| `decisionId: UUID?` added everywhere | LOOP-5295: pump events now carry a decision ID |
| `pumpInoperable` state | LOOP-4801: LibreTransmitter, OmniBLE, OmniKit all got `inSignalLoss`/`isInoperable` |
| `acknowledgeAlert` → `async throws` | OmniBLE + OmniKit: migrated from completion to async |
| OmniBLE `slot6SuspendTimeExpired` guard | DIY safety: don't ack if pod suspended; pod beeps until resumed |
| `updateLastEventDates` preserved in MinimedKit | DIY cannula/insulin age tracking |
| `RemoteNotificationResponseManager` preserved | DIY feature: remote command feedback notifications |
| Live Activity wired via `updateDisplayState()` | LoopDataManager Concurrency migration complete |
| `.strings` refs stripped from all pbxprojs | Tidepool doesn't maintain translations; DIY uses `.xcstrings` |
