# Canopy (break reminder for macOS)

A personal, Mac-only break reminder modelled on LookAway (and DeskRest). Swift + SwiftUI + AppKit, macOS 27+.

## Read these first
- `docs/PROGRESS.md`: what's been built so far, phase by phase.
- `docs/PLAN.md`: design rules and what's next (unticked steps).
- `docs/DECISIONS.md`: why things are built this way, and gotchas not to repeat.
- `docs/FEATURES.md` §3: what we're building and what was cut.
- `docs/PROBLEMS.md`: the user's latest feedback list.
- `docs/ARCHITECTURE.md`: how the parts fit, what's portable vs Mac-only.
- `docs/TEST-CHECKLIST.md`: the user's printable by-hand test of every feature. Keep it in sync when features change.
- `docs/HOW-TO-BUILD.md`: the `make` commands, explained for the user. Keep it in sync with the `Makefile`.
- `resources/`: LookAway screenshots and recordings, named after what they show. Use them as the visual reference.

## Commands (from the project root)
- `make test`: build and run all tests (summary only; full log in `build/test.log`).
- `make install`: Release build, copy to `/Applications`, restart the app. Do this before the user checks anything; they only use the `/Applications` copy.
- `make` lists the rest (`build`, `run`, `stop`, `clean`, `xcode`, `icon`, `project`). Every target runs `xcodegen` first, so new files are picked up.
- Everything is named **Canopy** (project, target, scheme, `Canopy.app`, process `Canopy`) except the bundle ID, still `com.jammyjellyfish.BreakReminder` so settings carry over.

## Source layout
- `Canopy/App/`: entry point, `AppDelegate`, `Info.plist`.
- `Canopy/Core/`: plain-Swift logic (Foundation only, no AppKit/SwiftUI): scheduler, settings, stats, schedule rules, wellness timer, messages. Keep it that way.
- `Canopy/Features/<Feature>/`: one folder per feature (MenuBar, BreakScreen, Alerts, Wellness, SmartPause, ClockOut, Onboarding, Shortcuts, Settings + `Pages/`).
- `Canopy/Shared/`: used by several features (accent colour/icon, sound player). `Canopy/Resources/`: assets, app icon, sounds.
- `CanopyTests/`: tests. `design/`: icon script. `resources/`: reference screenshots.

## How we work
- Each phase: short plan → user's go-ahead → build + tests → user checks visuals by eye → update docs → commit when the user asks.
- Keep `docs/` updated as work happens; it's what survives conversation compaction.

## Screenshots
- Claude can take screenshots of the screen (`screencapture`); screen recording permission is on.
- **Always ask the user first.** After they say yes, open the app (or whatever is being tested), then take the screenshot.
