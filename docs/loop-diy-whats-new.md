# Loop DIY — What's New

*User-facing guide to the changes on the `next-dev` line, from the two Tidepool → DIY
syncs (2026-03-10 and 2026-05-11) plus everything DIY has added since.*

Last updated: 2026-07-14.

This document explains **what changed for you as a user**. For merge mechanics,
conflict resolutions, testing checklists, and data-migration internals, see the
companion [Developer / Sync Notes](loop-diy-sync-dev-notes.md).

---

## The short version

DIY Loop absorbed roughly two years of Tidepool's work on Loop, then kept going with
DIY-only features on top. The headline user-visible changes:

- **Presets are completely redesigned** — typed presets (Pre-Meal / Activity / Custom),
  evidence-based activity presets, day-of-week scheduling, safety guardrails, and a
  short required training before you can create custom presets.
- **A new Glucose Alerts system** — your own high/low/urgent-low/predicted-low
  thresholds with selectable alert sounds, shown and edited in **your** glucose unit
  (mg/dL *or* mmol/L), plus true critical alerts on iOS 26 without a special entitlement.
- **A Statistics page** — a standard Ambulatory Glucose Profile (AGP) report with
  time-in-range, GMI, and glucose variability over 7–90 days.
- **More devices** — Omnipod, Medtrum, Eversense, and FreeStyle Libre 3 are all
  supported alongside the existing pumps and CGMs.
- **A smarter forecast and a cleaner algorithm** under the hood.
- **A redesigned main screen**, plus Apple Watch, HUD, and history improvements.

---

## Presets — a full redesign

This is the biggest change you'll notice day-to-day.

### Preset types

Presets are now one of three kinds, each with its own abilities:

| | Pre-Meal | Activity | Custom |
|---|---|---|---|
| Adjust correction range | ✅ | ✅ | ✅ |
| Adjust insulin needs | — | ✅ | ✅ |
| Set a duration | ends when carbs entered | ✅ | ✅ |
| Run indefinitely | — | — | ✅ |
| Rename / delete | — | — | ✅ |
| Schedule by day & time | — | ✅ | ✅ |

### Activity presets with evidence-based defaults

Four ready-made activity presets ship for everyone (customizable, not deletable):

| Activity | Target range | Insulin needs |
|---|---|---|
| Jogging | 150–170 mg/dL | 21% of normal |
| Biking | 150–170 mg/dL | 23% of normal |
| Walking | 150–170 mg/dL | 23% of normal |
| Strength Training | 150–170 mg/dL | 37% of normal |

"Insulin needs" is a single control that scales basal, carb ratio, and ISF together —
so *"give me 21% of normal insulin"* is one number instead of three. If you change a
preset from its defaults, it's marked as **modified**.

### New safety behavior

- **High insulin-needs mitigation** — if you push a preset's insulin needs above ~165%,
  the correction target is automatically floored at **110 mg/dL**. This prevents the
  dangerous combination of a lot of insulin *and* a very low target. The app shows you
  when this is in effect.
- **Guardrails while editing** — settings outside the recommended range are flagged in
  yellow, and outside the safe range in red, before you can save.
- **Indefinite-preset reminder** — a custom preset with no end time reminds you every
  24 hours that it's still running, so you don't leave one on by accident.

### Scheduling

Presets can be scheduled to start at a specific time, optionally repeating on any
combination of days of the week. When a scheduled start time arrives, a time-sensitive
alert asks whether to start it ("Yes, Start Now" / "Don't Start").

### Required training

Before creating your first custom preset, you complete a short in-app training covering
how presets work, illness, daily activities, and exercise. You can review it any time
from the Presets screen.

### The Presets screen

A dedicated full-screen view with an active-preset card (showing expected end time),
a sortable list of all presets, and a **Performance History** view of past activations.
While entering carbs, a banner now shows any active preset.

---

## Glucose Alerts (DIY, new since the sync)

A new glucose-alert system, styled after standalone-receiver alerts:

- **Your own thresholds** for **Urgent Low**, **Low**, **High**, and **Predicted Low**.
- **Displayed and edited in your glucose unit** — mg/dL or mmol/L, matching every other
  screen. The picker steps by 1 mg/dL or 0.1 mmol/L as appropriate.
- **Selectable alert sounds** per alert, and a **"Delay 1st Alert"** option for highs so
  you aren't nagged the moment you cross the line.
- **Only the most severe low-side alert fires** — you won't get a Low and an Urgent Low
  buzzing at the same time, and a predicted-low alert is suppressed if you're already
  at or below your Low threshold.

### Critical alerts on iOS 26 without an entitlement

DIY builds don't have Apple's official critical-alert entitlement. On **iOS 26 and
later**, Loop now uses Apple's **AlarmKit** to deliver true critical alerts that break
through silent mode and Focus — no entitlement required. When it can't, it falls back to
boosting system volume and playing a bundled critical sound. Tapping **Stop** on the
alarm acknowledges the underlying Loop alert. Builds without the entitlement include an
in-app FAQ explaining how alerts behave.

---

## Statistics — Ambulatory Glucose Profile (DIY, new since the sync)

**Settings → Statistics** opens a standard **AGP report**:

- Time-in-range across the consensus bands (very low / low / in-range / high / very high).
- **GMI** (Glucose Management Indicator), **average glucose**, and **glucose variability**
  (coefficient of variation).
- The AGP percentile curves (median with 25–75% and 5–95% bands) by time of day, colored
  to match the clinical captūrAGP / IDC report style.
- Selectable window of **7, 14, 30, or 90 days**, with a notice when a window doesn't have
  complete data.

This is powered by a longer on-device glucose history (now kept for **90 days**), so the
report has enough data to be meaningful without waiting on slow HealthKit queries.

---

## More devices

Device support expanded well beyond the original sync set.

### Pumps
- **Omnipod** (Eros, DASH, and **Omnipod 5**) — now via the consolidated **OmnipodKit**
  driver, which adds Omnipod 5 support.
- **Medtrum** (Nano / TouchCare) — **new**.
- **Medtronic (Minimed)** — retained, including DIY's cannula-age / insulin-age tracking.

### CGMs
- **FreeStyle Libre 3** — **new**, via the native **LibreLoop** integration (direct BLE
  pairing, backfill of missed readings, and sensor-failure guidance UI). Readings and
  settings respect your mg/dL vs mmol/L preference.
- **Eversense** (Senseonics E3 / 365) — **new**, via **EversenseKit**.
- **Dexcom G6/G7**, **older Libre (via LibreTransmitter)**, and **Nightscout-as-CGM** —
  all retained.

Every pump command is now tagged with the algorithm **decision** that produced it, which
improves troubleshooting and the accuracy of what's uploaded to Nightscout/Tidepool.

---

## Under the hood: a cleaner, smarter algorithm

The dosing math moved into a dedicated **LoopAlgorithm** package. For you, that mostly
means faster, more predictable behavior and some concrete improvements Tidepool made:

- **Smoother forecasts** — insulin and carb effects now ramp up gradually at the start of
  absorption instead of jumping to full effect.
- **Selectable carb-absorption model** (parabolic / linear / piecewise-linear).
- **A max-active-insulin cap** expressed as a multiple of your max bolus (default 2×).
- **Insulin dose effects now follow your ISF schedule as the dose absorbs** — a bolus or
  basal keeps acting for hours. Previously Loop valued that whole absorption with a single
  ISF: the one in effect at the moment the dose was delivered. Now it uses your insulin
  sensitivity *timeline*, so if your ISF changes while an earlier dose is still absorbing,
  the remaining effect of that dose is recalculated at the new sensitivity — more accurate
  insulin-effect and IOB accounting across ISF changes.
- **A "gradual transitions" guard against noisy CGM data** — if your glucose readings jump
  sharply from one reading to the next (more than ~40 mg/dL between consecutive readings),
  the algorithm skips **glucose momentum and retrospective correction** for that cycle.
  Those two effects extrapolate your recent short-term trend, so on a big jump — a sensor
  glitch, a compression low, or a one-off spike — they'd amplify the noise instead of
  reflecting a real trend. Skipping them keeps dosing steadier through jumpy data.
- **The display forecast now projects ongoing suspends and manual temp basals**, so the
  prediction curve reflects what the pump is actually doing.

---

## Main screen, Watch, HUD, and everyday UI

### A redesigned main screen
- **A single insulin delivery chart** replaces the previous two-chart layout (a separate
  delivery chart and Active Insulin chart), for a cleaner status view.
- **Time since last loop** is shown, so you can tell at a glance how recently Loop ran.
- **An updated loop-status dialog** appears when you tap the loop-status icon, with clearer
  detail about the current loop state.
- **A redesigned Insulin Delivery Log** — tapping the Active Insulin chart opens a new log
  showing the day's total insulin delivery, with a filter to show *all* delivery or just
  your *user-initiated* doses (hiding automated temp basals). Tap any dose to see its
  details, including the dosing decision that produced it, and log a manual (non-pump) dose
  from the same screen. (When no pump is set up, the classic event-history screen is shown
  instead, since the new log relies on live pump state.)

### Watch, HUD, and history
- **Watch** refreshes glucose the moment you raise your wrist / open the app, and backfills
  from the latest stored reading.
- **Manual temp basal** now pauses looping while it runs and is clearly surfaced in the
  status HUD, so it's obvious when the loop is intentionally paused.
- **Longer history** — the app keeps 90 days of glucose locally (up from a shorter window),
  feeding the new Statistics page.
- **App version** moved into the Settings → Support section.
- **Clearer alert-permission warnings** — instead of one generic "notifications off"
  message, the app tells you specifically which permission (notifications, critical
  alerts, or time-sensitive) is disabled.
- **Required app-update flow** — the app can prompt you when a mandatory update is needed.

---

## If you're moving between DIY `dev` and this build

Upgrading to a `next-dev` build migrates your local data store forward automatically.
**Going back to a `dev` build in place is not guaranteed** — it works right after
upgrading, but becomes unreliable the longer you run the newer build, and can leave `dev`
unable to open the store (requiring a delete-and-reinstall). Your long-term history lives
in Apple Health and is rebuilt on reinstall, but **if you plan to switch back and forth,
don't rely on an in-place downgrade.** See the Developer / Sync Notes for the exact
mechanism.
