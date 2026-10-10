# BreakReminder (break reminder for macOS)

A personal, Mac-only break reminder modelled on LookAway (and DeskRest). Swift + SwiftUI + AppKit, macOS 27+.

## Read these first
- `docs/PROGRESS.md`: what's been built so far, phase by phase.
- `docs/PLAN.md`: the current plan (Canopy redesign). Unticked steps are what's next.
- `docs/DECISIONS.md`: why things are built this way, and gotchas not to repeat.
- `docs/FEATURES.md` §3: what we're building and what was cut.
- `docs/PROBLEMS.md`: the user's latest feedback list.
- `resources/`: LookAway screenshots and recordings, named after what they show. Use them as the visual reference.

## Commands (from the project root)
- `xcodegen generate --spec project.yaml`: recreate `BreakReminder.xcodeproj` from `project.yaml` (after adding files or changing settings).
- `xcodebuild test -project BreakReminder.xcodeproj -scheme BreakReminder -derivedDataPath build`: build and run all tests.
- Install and restart the app (do this before the user checks anything; they only use the `/Applications` copy):
  `xcodebuild -project BreakReminder.xcodeproj -scheme BreakReminder -configuration Release -derivedDataPath build/release build && pkill -x BreakReminder; sleep 1; ditto build/release/Build/Products/Release/BreakReminder.app /Applications/BreakReminder.app && open /Applications/BreakReminder.app`

## How we work
- Each phase: short plan → user's go-ahead → build + tests → user checks visuals by eye → update docs → commit when the user asks.
- Keep `docs/` updated as work happens; it's what survives conversation compaction.

## Screenshots
- Claude can take screenshots of the screen (`screencapture`); screen recording permission is on.
- **Always ask the user first.** After they say yes, open the app (or whatever is being tested), then take the screenshot.
