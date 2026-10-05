# BreakReminder (break reminder for macOS)

A personal, Mac-only break reminder modelled on LookAway (and DeskRest). Swift + SwiftUI + AppKit, macOS 27+.

## Read these first
- `docs/PROGRESS.md`: what's been built so far, phase by phase.
- `docs/CHECKLIST.md`: the plan. Unticked items are what's next.
- `docs/DECISIONS.md`: why things are built this way, and gotchas not to repeat.
- `docs/FEATURES.md` §3: what we're building and what was cut.
- `docs/PROBLEMS.md`: the user's latest feedback list.
- `resources/`: LookAway screenshots and recordings, named after what they show. Use them as the visual reference.

## Commands (from the project root)
- `xcodegen generate`: recreate `BreakReminder.xcodeproj` from `project.yml` (after adding files or changing settings).
- `xcodebuild test -project BreakReminder.xcodeproj -scheme BreakReminder -derivedDataPath build`: build and run all tests.
- `pkill -x BreakReminder; open build/Build/Products/Debug/BreakReminder.app`: restart the app.

## How we work
- Each phase: short plan → user's go-ahead → build + tests → user checks visuals by eye → update docs → commit when the user asks.
- Keep `docs/` updated as work happens; it's what survives conversation compaction.
