# Progress So Far

A short record of what's built. For *why* things are built this way (and mistakes not to repeat), see [`DECISIONS.md`](DECISIONS.md). For what's next, see [`PLAN.md`](PLAN.md). Older detail is in git history.

**Current status:** the app is feature-complete (Phases 0–15), redesigned as **Canopy** (native look, leaf icon), source reorganised and optimised. Next: the user runs `TEST-CHECKLIST.md`; then fixes from it. The app icon redo is under "Later" in `PLAN.md`.

---

## What the app does (where the code is)

- **Scheduler** (`Core/BreakScheduler.swift`, `Core/TimerSettings.swift`): a state machine (stopped / working / on break / paused) with **no clock of its own**. `AppDelegate` calls `tick(now:idleSeconds:)` once a second, so tests can fake "20 minutes later". Counts active screen time only; a gap of more than 10 s between ticks means the Mac slept. Settings are saved in `UserDefaults`; settings saved by an older version keep their values.
- **Break rules:** Casual / Balanced (Skip unlocks halfway) / Hardcore. Snooze limit per break, daily skip limit, Skip next break, double-Esc action, End Break early, hold until End Break, lock on break start. Typing **"emergency"** skips any break.
- **Menu bar** (`Features/MenuBar/`): leaf + rolling `19:42` countdown (`NSStatusItem` with a SwiftUI label; `MenuBarExtra` can't animate its label). Live Status, timer style `19:42` / `20m`. The leaf dims while paused, smart-paused, off hours or idle.
- **Break screen** (`Features/BreakScreen/`): one window per display, above everything. Live blur fades in, then the blurred wallpaper (or a picture / gradient) and the text. Big rolling timer (`Shared/RollingTime.swift`, also used by the heads-up and stats), thin accent bar of time left (drains to empty), message; glass Skip / snooze stack / End Break / Lock buttons at the bottom. Takes the keyboard back if another app comes forward; ⌘Q is refused during a break. Displays plugged in mid-break get covered.
- **Messages & exercises** (`Core/BreakMessages.swift`): built-in exercises and plain messages for short and long breaks, each with an on/off switch in Settings, plus your own for each kind of break (title + instructions).
- **Alerts & nudges** (`Features/Alerts/`): heads-up before a break (Start now / +1/+5/+15 min, a bar that drains to the break), pointer countdown, overtime nudge, Smart Pause and welcome back pills. Can be shown as macOS notifications instead (except the pointer countdown).
- **Smart Pause** (`Features/SmartPause/`): holds the timer when the mic/camera is in use, a focus app is in front, or a macOS Focus is on (via Shortcuts automations calling `canopy://focus-on` / `focus-off`; the old `breakreminder://` links still work). Typing hold, cooldown, "pause when away" (30 s / 1 / 2 min), welcome back.
- **Wellness reminders** (`Features/Wellness/`, `Core/WellnessTimer.swift`): posture and blink as a short screen flash. Due within a minute of each other → one flash.
- **Sounds** (`Shared/SoundPlayer.swift`, `Core/SoundChoice.swift`): 9 choices each for break start, break end, reminders and alerts (reminders and alerts have separate toggles; optional pitch-down for one-file end sounds) (`.m4a`, from BreakTimer GPL-3.0 and Stretchly; credits in `Resources/Sounds/CREDITS.md` and About).
- **Keyboard shortcuts** (`Features/Shortcuts/`): Pause/resume, Start break now, Snooze 5 min, via the KeyboardShortcuts package (MIT).
- **Schedule** (`Core/DaySchedule.swift`, `Features/ClockOut/`): office hours per weekday, planned breaks (e.g. Lunch 12:30, 45 min), Clock Out screen.
- **Stats** (`Core/StatsLog.swift`): taken / skipped / snoozed per day; 7-day chart of % skipped + snoozed; streak = days in a row with no skip or snooze. Clear History resets it.
- **Settings** (`Features/Settings/`): `NavigationSplitView` like System Settings, sidebar icons coloured by group, one page per feature, Preview buttons. **Welcome** window on first launch (`Features/Onboarding/`). **About** page with credits.
- **Icon** (`design/make-icon.swift`): two see-through gold glass leaves on near-black, no vein (Icon Composer file in `Resources/AppIcon.icon`, menu bar leaf in `Assets.xcassets/MenuBarIcon`). The same icon everywhere, Dock included.

## History

- **Planning:** studied LookAway and DeskRest (`resources/`). [`FEATURES.md`](FEATURES.md) §3 is what we build and what was cut.
- **Phases 0–15** (October 2026): XcodeGen project, scheduler, menu bar, break screen, break rules, settings window, Catppuccin Mocha look, alerts, Smart Pause, wellness, sounds, shortcuts, schedule, break screen customisation, stats, polish, Release build. Named Glance, then BreakReminder.
- **Canopy redesign** (`PLAN.md` steps 1–6): system colours and accent everywhere (Mocha removed), native settings window, bug fixes (alert windows resized while moving caused three crashes; see `DECISIONS.md` → Floating windows), flash-only wellness, sound choices, own exercises, notifications option, new stats, motion, new break screen layout, leaf icon, rename to **Canopy**. The bundle ID stays `com.jammyjellyfish.BreakReminder` so settings and stats carry over.
- **Organize source** into `Canopy/App`, `Core` (Foundation only), `Features/<Feature>`, `Shared`, `Resources`; tests in `CanopyTests/`.
- **Optimize:**
  - Break screen 58% → ~1% CPU (WindowServer 39% → ~18%): the timer, bar and skip ring are Core Animation layers, not SwiftUI animations; live blur turned off once covered. Earlier (Phase 14): idle ~10% → ~1% by only setting `@Observable` values when they change.
  - Measured, nothing left worth fixing: idle ~0.4%; flash reminder ~10% for one second (mostly macOS starting the sound); memory ~75–82 MB idle, ~190 MB during a break (blurred wallpapers, freed afterwards); `leaks` finds nothing of ours.
- **Test checklist:** [`TEST-CHECKLIST.md`](TEST-CHECKLIST.md), a printable by-hand test of every feature, grouped into 12 sessions.
- **Architecture notes:** [`ARCHITECTURE.md`](ARCHITECTURE.md): how the parts fit, which code is portable, Linux equivalents for the Mac-only parts, licences.
- **Makefile:** `make` commands for build, run, test, install, clean, icon; explained for beginners in [`HOW-TO-BUILD.md`](HOW-TO-BUILD.md).
- **Clean out:** removed unused code (`Accent.gradient`), the original brief (`PROMPT.md`) and the v1 history archive, and shortened these docs.
- **Clean out 2:** `RollingTime` back to fixed-width digits (every user is monospaced now), test-only `allExercises` moved into the test, icon script writes `AppIcon.icon` directly (no `design/icon-mockups` copy).
- **Alerts without colour:** pill symbols on grey circles, overtime text plain; the heads-up bar keeps the accent colour. The break screen bar now drains from full to empty, like the heads-up's.
- **October list, Phase D:** icon redone (gold, see-through, no vein); the accent-coloured in-app icon removed.
- **October list, Phase C:** your own messages split into short-break and long-break lists (old ones copied into both); built-in messages listed in Settings with switches, like exercises.
- **October list, Phase B:** heads-up without the clock badge, with a bar that drains to the break; one fade roll (`Shared/RollingTime.swift`) for changing numbers.
- **October list, Phase A:** flash without the icon, separate reminder/alert sounds, Reverie sound, leaf dims while idle, Clear History in Stats.

---

## How to build, test and run

`make install`, `make test`, `make run`, `make clean` and more: see [`HOW-TO-BUILD.md`](HOW-TO-BUILD.md). Launch at login must be turned on from the `/Applications` copy.

## Commits

| Commit    | What                                                            |
|-----------|-----------------------------------------------------------------|
| `9b28dde` | Project setup + planning docs                                   |
| `f47af9a` | Phase 1: scheduler + tests                                      |
| `60eae15` | Phase 2: menu bar countdown                                     |
| `01587bf` | Phase 3: break screen                                           |
| `d3fb44a` | Phase 4: break rules + docs moved into `docs/`                  |
| `ed7dd05` | Cleanup: rename to BreakReminder, archive v1 history            |
| `467926b` | Phase 5: settings window                                        |
| `063d6ad` | Fixes after Phase 5: ⌘Q during a break, frozen fade-out         |
| `48804da` | Look & feel: Catppuccin Mocha, mug icon, Live Status            |
| `8c3dc5d` | Phase 6: alerts & nudges                                        |
| `5c06b76` | Heads-up redesign (LookAway layout)                             |
| `02323bf` | Phase 7: Smart Pause, typing hold, welcome back                 |
| `1523472` | Phase 8: wellness reminders                                     |
| `44645e5` | Phase 9: sounds                                                 |
| `dcdd0c7` | Phase 10: keyboard shortcuts                                    |
| `fedc35a` | Phase 11: office hours, planned breaks, Clock Out               |
| `79029c7` | Phase 12: break screen customization, exercises                 |
| `d2fe14e` | Phase 13: stats                                                 |
| `86a822f` | Phase 14: polish                                                |
| `a996349` | Phase 15: Release build for `/Applications`                     |
| `4aae3fe` | Canopy steps 1–3: native look, leaf icon, bug fixes             |
| `632210c` | Canopy steps 4–5: features and appearance                       |
| `f27206e` | Rename the app to Canopy (step 6)                               |
| `5af3f95` | Organize source into App, Core, Features, Shared, Resources     |
| `2bde437` | Optimize break screen (58% → ~1% CPU)                           |
| `7b6be95` | Optimize part 2: measure flash, idle, memory                    |
| `1d8358a` | Clean out: unused code, old brief and archive, shorter docs     |
