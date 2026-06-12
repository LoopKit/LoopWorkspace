# LoopKit ↔ Tidepool Sync Process

**Purpose:** A repeatable process an developer can follow to merge changes from Tidepool's fork of the Loop
ecosystem back into the LoopKit DIY repos, resolving conflicts with full contextual understanding.

**Last updated:** 2026-03-10 (added Golden Rule; clarified .strings vs .xcstrings handling)

---

## Background & Architecture

The Loop ecosystem consists of two parallel development streams:

- **LoopKit (DIY/open source):** The community-maintained fork at `github.com/LoopKit/*`.
  Organized as a set of git submodules in `LoopWorkspace`.
- **Tidepool:** A company building a supported version of Loop at `github.com/tidepool-org/*`.
  Tidepool's repos are **forks** of the LoopKit repos, with additional clinical/regulatory features.

Changes flow in both directions over time, but syncing is typically done in the direction:
**tidepool-org → LoopKit**, bringing Tidepool's upstream improvements back to DIY, and then DIY -> Tidepool

---

## ⭐ Golden Rule: Prefer Tidepool, Protect DIY

**When in doubt about a conflict resolution, prefer Tidepool's version — but never at the cost of
breaking or removing DIY functionality.**

More specifically:

- **Tidepool changes win** for: algorithm improvements, bug fixes, new clinical features, API
  changes, architecture decisions, test coverage, Swift version upgrades.
- **LoopKit DIY wins** for: anything that is *exclusively* a DIY capability — community
  translations, open-source-only build paths, non-Tidepool signing/bundle IDs, features that
  only exist in DIY and would be silently deleted by taking Tidepool's version.
- **Keep both** when a DIY feature and a Tidepool feature occupy the same code area but serve
  different purposes and can coexist (e.g. an added Tidepool service upload alongside an existing
  Nightscout upload).
- **Never silently drop** a DIY feature. If Tidepool's version removes something DIY users
  depend on, document it explicitly in the per-repo sync log and flag it for human review (⚠️)
  rather than quietly taking Tidepool's side.

**Practical decision tree for any conflicting hunk:**

1. Is this a pure algorithm/logic change? → Take Tidepool's.
2. Does Tidepool's version remove a capability DIY users have? → Keep both if possible; if not,
   flag for human review.
3. Is this cosmetic (formatting, style, ordering)? → Take Tidepool's; not worth fighting over.
4. Is this a build/project setting (deployment target, signing, bundle ID)? → See the
   "project.pbxproj" section below for specific rules.
5. Is this a Tidepool-only backend integration (e.g. Coastal, Tidepool upload)? → Keep it;
   it doesn't harm DIY users and removing it creates future conflicts.

---

### ⚠️ Key Architectural Divergence: LoopAlgorithm

The most important structural difference between the two streams:

- **Tidepool** extracted the core Loop algorithm into a standalone Swift Package:
  `tidepool-org/LoopAlgorithm` (a fork of `LoopKit/LoopAlgorithm`).
  Tidepool's `LoopKit` repo declares it as a SwiftPM dependency (in `Package.resolved`).
- **LoopKit DIY** still embeds the algorithm code inline inside `LoopKit/LoopKit/LoopAlgorithm/`.

This means when syncing `LoopKit`:
- Algorithm changes Tidepool made via their `LoopAlgorithm` package need to be found by
  looking at `tidepool-org/LoopAlgorithm` commits AND `tidepool-org/LoopKit` commits.
- Conflicts in `LoopAlgorithm.swift`, `LoopPredictionOutput.swift`, etc. inside LoopKit
  may reflect changes that Tidepool now maintains in their separate package.
- **LoopAlgorithm must be synced first** (as a standalone package repo) before syncing LoopKit.

---

## Repository Map

All repos below are submodules of `LoopWorkspace`, except `LoopAlgorithm` which is standalone.

| Repo | LoopKit branch | Tidepool fork | Notes |
|------|---------------|---------------|-------|
| **LoopAlgorithm** | `main` | `tidepool-org/LoopAlgorithm` | ⚠️ Standalone Swift Package. Sync FIRST. Not in sync.swift. |
| LoopKit | `dev` | `tidepool-org/LoopKit` | ⚠️ Complex. References LoopAlgorithm as package (Tidepool) vs inline (DIY). |
| Loop | `dev` | `tidepool-org/Loop` | Most complex. Many source conflicts. Sync LAST. |
| TidepoolService | `dev` | `tidepool-org/TidepoolService` | Tidepool-specific service; sync carefully |
| OmniBLE | `dev` | `tidepool-org/OmniBLE` | Pump driver; test after merge |
| OmniKit | `main` | `tidepool-org/OmniKit` | Pump driver; test after merge |
| MinimedKit | `main` | `tidepool-org/MinimedKit` | Pump driver; test after merge |
| NightscoutService | `dev` | `tidepool-org/NightscoutService` | Service layer |
| LibreTransmitter | `main` | `tidepool-org/LibreTransmitter` | CGM driver |
| G7SensorKit | `main` | `tidepool-org/G7SensorKit` | CGM driver |
| CGMBLEKit | `dev` | `tidepool-org/CGMBLEKit` | CGM driver |
| dexcom-share-client-swift | `dev` | `tidepool-org/dexcom-share-client-swift` | CGM client |
| RileyLinkKit | `dev` | `tidepool-org/RileyLinkKit` | Radio hardware |
| LoopOnboarding | `dev` | `tidepool-org/LoopOnboarding` | Onboarding UI |
| LoopSupport | `dev` | `tidepool-org/LoopSupport` | Support utilities |
| AmplitudeService | `dev` | `tidepool-org/AmplitudeService` | Analytics service |
| LogglyService | `dev` | `tidepool-org/LogglyService` | Logging service |
| NightscoutRemoteCGM | `dev` | `tidepool-org/NightscoutRemoteCGM` | CGM source |
| MixpanelService | `main` | `tidepool-org/MixpanelService` | Analytics service |

**Not synced:** `Minizip`, `TrueTime.swift` (third-party libs, no Tidepool fork)

---

## Recommended Sync Order

**Core → App → Plugins (Peripheral)**

The correct order is *not* simply "foundational to dependent" in a build-graph sense.
It is **core architectural decisions first**, so that by the time you reach the peripheral
plugins you already understand what the core changed — making those conflicts easier to
read and resolve coherently.

In practice, a conflict in a pump driver that looks like "Tidepool changed the DoseEntry
type" only makes sense once you've already seen that LoopKit changed `DoseEntry` in the
core repo. If you do plugins first, you're resolving conflicts blind.

### Tier 1 — Core (do these first)
1. **LoopAlgorithm** — standalone package; establishes the algorithm API everything else uses
2. **LoopKit** — foundational types (`DoseEntry`, `GlucoseValue`, `Guardrail`, etc.); all plugins depend on it

### Tier 2 — App (do before plugins)
3. **Loop** — the top-level app; resolving this *before* plugins means you understand which
   app-level API changes the plugins are expected to match, rather than discovering surprises later

### Tier 3 — Plugins / Peripheral (do last, in any order)
4. **CGM drivers**: CGMBLEKit, G7SensorKit, dexcom-share-client-swift, NightscoutRemoteCGM, LibreTransmitter
5. **Pump drivers**: RileyLinkKit, OmniKit, OmniBLE, MinimedKit
6. **Services**: TidepoolService, NightscoutService, AmplitudeService, LogglyService, MixpanelService
7. **Support/Onboarding**: LoopSupport, LoopOnboarding

> **Note:** pbxproj-only conflicts in peripheral repos can be batched and resolved
> mechanically at any point since they don't require architectural context. Swift source
> conflicts in peripheral repos should wait until Tier 1 + 2 are done.

---

## Setup (One-Time Per Workspace Clone)

For each repo in the sync list, add the Tidepool remote if not already present:

```bash
cd LoopWorkspace/<repo>
git remote add tidepool https://github.com/tidepool-org/<repo>.git
git fetch tidepool
```

For LoopAlgorithm (standalone — clone separately):
```bash
cd LoopWorkspace  # or wherever you keep it
git clone https://github.com/LoopKit/LoopAlgorithm.git
cd LoopAlgorithm
git remote add tidepool https://github.com/tidepool-org/LoopAlgorithm.git
git fetch tidepool
```

---

## Per-Repo Sync Process

Repeat these steps for each repo, in the order listed above.

### Step 1 — Choose a sync branch name

Use a consistent name across all repos for this sync run, e.g.:
```
tidepool-sync/YYYY-MM-DD
```

### Step 2 — Create sync branch

```bash
cd LoopWorkspace/<repo>
git checkout origin/<base-branch>    # e.g. origin/dev or origin/main
git checkout -b tidepool-sync/YYYY-MM-DD
```

### Step 3 — Attempt merge

```bash
git merge --no-edit tidepool/<base-branch>
```

If the merge succeeds with no conflicts → commit and move to Step 9.
If there are conflicts → continue to Step 4.

### Step 4 — Identify conflict files

```bash
git diff --name-only --diff-filter=U
```

Categorize conflicts:
- **project.pbxproj** → See "Xcode Project File Conflicts" section below
- **Swift source files** → See "Source Code Conflicts" section below
- **Other** (yml, strings, etc.) → Research case by case

### Step 5 — Research each conflict (Source Files)

For each conflicting Swift file:

**a) Understand what each side changed:**
```bash
MERGE_BASE=$(git merge-base HEAD tidepool/<branch>)

# What did LoopKit change in this file since the merge base?
git log --oneline $MERGE_BASE..origin/<branch> -- <file>
git diff $MERGE_BASE..origin/<branch> -- <file>

# What did Tidepool change?
git log --oneline $MERGE_BASE..tidepool/<branch> -- <file>
git diff $MERGE_BASE..tidepool/<branch> -- <file>
```

**b) Find related GitHub issues and PRs:**

For each commit hash found above, search for it on GitHub:
- `https://github.com/LoopKit/<repo>/commit/<hash>`
- Look at the PR that merged it (GitHub shows "merged via PR #NNN")
- Read the PR description and linked issues
- Also search for the LOOP-XXXX ticket numbers in commit messages at:
  `https://github.com/LoopKit/<repo>/issues` and
  `https://github.com/tidepool-org/<repo>/issues`

**c) For LoopAlgorithm-related conflicts in LoopKit:**
- Check if the same change exists in `tidepool-org/LoopAlgorithm`
- The Tidepool version of a function in LoopKit may be forwarding to their package;
  the DIY version keeps it inline. Preserve the inline version while incorporating
  any algorithmic improvements from the package version.

### Step 6 — Resolve conflicts

**General principles:** Follow the ⭐ Golden Rule (see top of document) — prefer Tidepool's
version, but never silently remove DIY functionality.

**For algorithm changes:** Take Tidepool's. Their test coverage is usually more thorough
and the algorithmic direction is the right one. Check the `LoopAlgorithm` sync doc to
understand if a conflict here is related to the HealthKit→LoopUnit migration.

**For UI changes:** Take Tidepool's unless it removes a DIY-only UI path. Regulatory/clinical
UI additions from Tidepool are fine to include — they add capability without breaking DIY.

**For Tidepool-specific features** (Tidepool Service uploads, Coastal integration, etc.):
Keep them — they don't break DIY users, and removing them creates future conflicts.

**For DIY-only features** (e.g. community CGM integrations, Nightscout, open-source pump
drivers not supported by Tidepool): Protect these. They are the reason DIY exists.

**Never silently drop** either side's work without a note in the sync doc.

After resolving each file:
```bash
git add <resolved-file>
```

### Step 7 — Resolve Xcode Project File Conflicts (project.pbxproj)

The `.pbxproj` is a structured text file. Conflicts here are almost always about:
- **Object version** (LoopKit likely bumped for newer Xcode)
- **File references** (new Swift files added by either side)
- **Build settings** (deployment targets, signing, feature flags)
- **Localization** (LoopKit uses `.xcstrings`; Tidepool may still use `.strings`)

**Approach:**
```bash
# See what LoopKit changed in the project file since merge base
git diff $MERGE_BASE..origin/<branch> -- <repo>.xcodeproj/project.pbxproj

# See what Tidepool changed
git diff $MERGE_BASE..tidepool/<branch> -- <repo>.xcodeproj/project.pbxproj
```

Then look at the actual conflict markers in the file:
```bash
grep -n "<<<<<<\|=======\|>>>>>>>" <repo>.xcodeproj/project.pbxproj
```

**Common resolutions:**
- `objectVersion`: Keep LoopKit's (higher = newer Xcode format)
- `IPHONEOS_DEPLOYMENT_TARGET`: Take the *higher* of the two values (both are raising it)
- New file references added by LoopKit (e.g. `.xcstrings`): Keep them
- New file references added by Tidepool (new Swift files, mapping models, etc.): Keep them
- Tidepool's `.strings` localization file references: **Drop them** (DIY deleted these; see Pattern below)
- Tidepool's `XCRemoteSwiftPackageReference "LoopAlgorithm"`: **Omit from DIY** (DIY embeds it inline)
- LoopKit bundle IDs (`com.loopkit.*`): Keep LoopKit's
- Tidepool bundle IDs (`com.tidepool.*`): Keep Tidepool's (they're for different targets)
- Signing/provisioning settings: Keep LoopKit's for shared targets

After resolving:
```bash
git add <repo>.xcodeproj/project.pbxproj
```

### Step 8 — Commit

```bash
git commit -m "Merge tidepool/dev into tidepool-sync/YYYY-MM-DD

Resolved conflicts:
- <file1>: <brief description of resolution>
- <file2>: <brief description of resolution>

See sync-docs/<repo>.md for full context."
```

### Step 9 — Document in per-repo log

Update `sync-docs/<repo>.md` with:
- Merge base commit hash
- LoopKit and Tidepool tip commit hashes
- For each resolved conflict:
  - The file path
  - Relevant commit hashes from each side
  - Links to GitHub PRs/issues
  - What each side was trying to do
  - How it was resolved and why
  - Any features that need testing as a result
- Any open questions or items requiring human review

### Step 10 — Update SYNC_PROGRESS.md

Mark the repo as done (✅) or blocked (❌) in the progress table.
Note any cross-repo dependencies discovered (e.g. "LoopKit change requires matching Loop change").

### Step 11 — Push and create PR (when ready)

```bash
git push origin tidepool-sync/YYYY-MM-DD
# Then open a PR on GitHub: tidepool-sync/YYYY-MM-DD → <base-branch>
```

---

## Special Case: LoopAlgorithm

LoopAlgorithm lives at `LoopKit/LoopAlgorithm` (not a submodule of LoopWorkspace) and
`tidepool-org/LoopAlgorithm` is a fork of it.

**Key questions before syncing:**
1. Is the DIY `LoopAlgorithm` used as a package by Loop/LoopKit, or still embedded inline?
   - If package: sync just like any other repo
   - If inline (current DIY state): sync algorithm changes need to flow into LoopKit's
     `LoopKit/LoopAlgorithm/` subdirectory AND the standalone LoopAlgorithm package

2. What is the current pinned version of `tidepool-org/LoopAlgorithm` in Tidepool's LoopKit?
   Check `LoopKit.xcodeproj/.../Package.resolved` on `tidepool/dev`.

3. Clone LoopAlgorithm separately:
   ```bash
   git clone https://github.com/LoopKit/LoopAlgorithm.git
   cd LoopAlgorithm
   git remote add tidepool https://github.com/tidepool-org/LoopAlgorithm.git
   git fetch tidepool
   ```

4. Follow the same per-repo sync process above.
5. After resolving LoopAlgorithm, **also check** whether any of the same changes need to be
   applied to the inline copy in `LoopKit/LoopKit/LoopAlgorithm/` (if DIY hasn't adopted the package yet).

---

## Common Patterns to Watch For

### Pattern: Tidepool adds LoopAlgorithm package dependency
In Tidepool's `LoopKit`, the `project.pbxproj` will have:
```
XCRemoteSwiftPackageReference "LoopAlgorithm"
repositoryURL = "https://github.com/tidepool-org/LoopAlgorithm";
```
**Resolution for DIY:** Omit this package reference. Keep the inline `LoopAlgorithm/` code.
However, DO bring in any algorithmic logic changes from the inline vs. package versions.

### Pattern: Deployment target bumps
Tidepool regularly bumps `IPHONEOS_DEPLOYMENT_TARGET`. DIY follows at its own pace.
**Resolution:** Take the higher value unless there's a specific reason not to.
Check LoopKit's own dev branch to see what they've already committed to.

### Pattern: Localization format migration
LoopKit DIY migrated from `.strings` files to `.xcstrings` (Xcode 15+ string catalogs).
Tidepool does not maintain translations and remains on `.strings`.

**Resolution:** Keep LoopKit's `.xcstrings` format. **Never re-add Tidepool's `.strings`
file references** — Tidepool's `.strings` references belong to files that DIY deliberately
deleted when migrating to string catalogs. Re-adding them would cause build errors
("file not found") because the actual `.strings` files no longer exist in DIY's tree.

In practice, when resolving `project.pbxproj` conflicts:
- Drop any `PBXFileReference` entries for `*.strings` that came from Tidepool's side
- Drop any `PBXBuildFile` entries referencing those same `.strings` files
- Drop any group `children = (...)` entries pointing to `.strings` files from Tidepool
- Keep DIY's `*.xcstrings` references
- Keep all of Tidepool's non-translation additions (new Swift files, mapping models, etc.)

### Pattern: Tidepool-specific regulatory features
Features like Coastal integration, FDA submission mode, specific clinical guardrails.
**Resolution:** Keep them. They add capability without breaking DIY. Only omit if they
require Tidepool backend infrastructure that simply won't exist in DIY.

### Pattern: Bundle identifier differences
`com.loopkit.*` (LoopKit) vs `com.tidepool.*` (Tidepool).
**Resolution:** Keep both — they apply to different build targets/schemes.

### Pattern: HKUnit.swift removal
Both sides removed the `HKUnit.swift` extension file (HealthKit unit helpers were moved).
This should auto-merge or be a trivially clean conflict. If not, take the removal.

---

## Testing Checklist After Merge

After completing all repos, test these critical paths before opening PRs:

- [ ] **Glucose display:** CGM data flows and displays correctly
- [ ] **Insulin delivery:** Bolus and basal commands work (OmniBLE/OmniKit/Minimed)
- [ ] **Loop algorithm:** Closed loop prediction and dosing recommendations
- [ ] **Remote services:** Nightscout upload/download, Tidepool service
- [ ] **Onboarding:** Fresh install and therapy settings configuration
- [ ] **Watch app:** Complication and status display (if applicable)
- [ ] **Widgets:** Lock screen / home screen widgets (if applicable)
- [ ] **Build:** All targets compile cleanly with no warnings promoted to errors

---

## Tracking Files

| File | Purpose |
|------|---------|
| `SYNC_PROGRESS.md` | Master status table, notes on blocked items |
| `sync-docs/<repo>.md` | Per-repo conflict log with full context and links |
| `LOOPKIT_SYNC_PROCESS.md` | This file — the process itself |

---

## Reference Links

- LoopKit org: https://github.com/LoopKit
- Tidepool org: https://github.com/tidepool-org
- LoopAlgorithm (LoopKit): https://github.com/LoopKit/LoopAlgorithm
- LoopAlgorithm (Tidepool): https://github.com/tidepool-org/LoopAlgorithm
- LoopWorkspace: https://github.com/LoopKit/LoopWorkspace
- Original sync script: `LoopWorkspace/Scripts/sync.swift`
