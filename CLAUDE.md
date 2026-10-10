# Canopy (break reminder for macOS)

A personal, Mac-only break reminder modelled on LookAway (and DeskRest). Swift + SwiftUI + AppKit, macOS 27+.

## Read these first
- `docs/PROGRESS.md`: what's been built so far, phase by phase.
- `docs/PLAN.md`: the current plan (Canopy redesign). Unticked steps are what's next.
- `docs/DECISIONS.md`: why things are built this way, and gotchas not to repeat.
- `docs/FEATURES.md` §3: what we're building and what was cut.
- `docs/PROBLEMS.md`: the user's latest feedback list.
- `resources/`: LookAway screenshots and recordings, named after what they show. Use them as the visual reference.

## Commands (from the project root)
- `xcodegen`: recreate `Canopy.xcodeproj` from `project.yml` (after adding files or changing settings).
- `xcodebuild test -project Canopy.xcodeproj -scheme Canopy -derivedDataPath build`: build and run all tests.
- Install and restart the app (do this before the user checks anything; they only use the `/Applications` copy):
  `xcodebuild -project Canopy.xcodeproj -scheme Canopy -configuration Release -derivedDataPath build/release build && pkill -x Canopy; sleep 1; ditto build/release/Build/Products/Release/Canopy.app /Applications/Canopy.app && open /Applications/Canopy.app`
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
