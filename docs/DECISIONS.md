# Decisions & Gotchas

Technical choices, the reasons for them, and mistakes not to repeat. Add to this whenever something non-obvious is learned.

## Working with the user
- Not a software engineer: explain jargon in plain language, moderate detail.
- **Plan first** for anything non-trivial, wait for a go-ahead. **Never commit unless asked.**
- Visual things (animations, windows, menu bar) can't be checked from the terminal: Terminal has no Screen Recording permission, so `screencapture` fails. Give the user a numbered check list and let them verify.
- Keep `docs/` up to date (PROGRESS, CHECKLIST, this file) so work survives conversation compaction.
- Git identity is `domino-jockey <hayden.tus@gmail.com>`; the user hasn't said whether that's right. Ask before changing anything.

## Project setup
- **XcodeGen**, not hand-made Xcode projects. `project.yml` is the source of truth; `*.xcodeproj` is gitignored. Run `xcodegen generate` after adding/removing files or changing settings.
- Xcode 27's welcome-window "App" button makes an unusable draft in `~/Library/Developer/Xcode/UntitledProjects/` (multi-platform, placeholder bundle ID). Don't use it.
- Screenshot filenames from macOS contain a **narrow no-break space** (U+202F) before "AM/PM". Typing the name fails; use globs (`Screenshot*9.02.14*`).
- Red "Cannot find X in scope" diagnostics from SourceKit (the editor's checker) are false alarms in this project. Trust `xcodebuild`.

## Timer
- `BreakScheduler` has **no clock**; everything goes through `tick(now:idleSeconds:)`. Keeps it fully testable with `FakeClock` (in `BreakReminderTests/BreakSchedulerTests.swift`).
- Don't reset `lastTick` on pause/resume/start: ticks keep arriving while paused, and resetting dropped a second each time.
- A tick gap > 10 s = the Mac slept; treated as idle time. No sleep/wake notifications needed.
- Idle time comes from `CGEventSource.secondsSinceLastEventType(.combinedSessionState, eventType: ~0)`. No permission needed. Keeps growing while the screen is locked.
- **Display rounding:** `TimeFormat.clock` rounds to the **nearest** second. Rounding up made the countdown freeze then skip, because tick timing wobbles slightly around whole seconds.

## Menu bar
- `MenuBarExtra` can't animate its label → `NSStatusItem` + `NSHostingView` inside the button.
- The hosting view must pass clicks through (`hitTest` returns nil) or the menu never opens.
- The status item doesn't size itself to the SwiftUI label: call `refreshWidth()` after changes.
- The 1 s `Timer` is added in `.common` run-loop mode so it keeps firing while a menu is open.
- The break screen covers the menu bar, so the menu bar doesn't need any break-time behaviour.

## Break screen
- Windows are **non-activating `NSPanel`s** (`.nonactivatingPanel`, `hidesOnDeactivate = false`, `canBecomeKey = true`), level `.screenSaver`, `canJoinAllSpaces` + `fullScreenAuxiliary`.
  - Why: asking macOS to make the app active (`NSApp.activate()`) can be refused, e.g. right after unlocking. A non-activating panel takes the keyboard without activating the app.
  - On `NSWorkspace.didActivateApplicationNotification` (any app comes forward), call `makeKey()` on the panel again. Covers unlock and ⌘-Tab.
- The blur needs **no Screen Recording permission**: `NSVisualEffectView` with `.behindWindow` blurs whatever is behind, live. Then the blurred wallpaper fades in on top.
- Wallpaper: `NSWorkspace.desktopImageURL(for:)` → `CGImageSourceCreateThumbnailAtIndex` at 480 px (fast decode) → Core Image blur + 25% black tint. The user's wallpaper is dark, so breaks look dark.
- The scheduler's `state` is watched with `withObservationTracking`, re-registered after every change, so breaks started from the menu show instantly.
- Esc is key code 53. Ignore `isARepeat`: holding a key sends repeats, which otherwise look like a double-tap.
- SwiftUI animations: `.animation(_:value:)` on a parent overrides the animation of everything inside it. Use the scoped form `.animation(_:body:)` to animate just one property.
- Views placed outside their parent's frame (via `.background` + `.offset`) don't reliably get clicks or hover. Build things like the snooze stack as a real layout instead.
- `BreakView` doesn't read the scheduler directly. It reads `BreakDisplay`, a copy the overlay controller refreshes (via `withObservationTracking`) only **while on a break**. Why: when a break ends the scheduler is already back to "working" during the fade-out, and live reads made Skip, the timer and the footer change mid-fade.
  - Don't set `model.display` inside the tracking closure (it would re-trigger itself). Compute the value inside, assign outside.
  - The switch to "Break's over" is animated by wrapping that one update in `withAnimation`; Texts use `.contentTransition(.opacity)` to cross-fade.
- ⌘Q during a break is refused in `applicationShouldTerminate`. Logout/shutdown send an Apple event (`NSAppleEventManager.shared().currentAppleEvent` is non-nil), so those still quit. `pkill` (SIGTERM) bypasses this, so the restart command still works.

## Lock Screen
- The user's Mac requires the password **5 min** after display sleep (`sysadminctl -screenLock status` → 300 s), so `pmset displaysleepnow` doesn't lock.
- Uses `SACLockScreenImmediate` from `/System/Library/PrivateFrameworks/login.framework` via `dlopen`/`dlsym` (undocumented; the same as ⌃⌘Q). Falls back to `pmset displaysleepnow` if it's ever removed. Never call it in tests or scripts: it really locks the screen.

## Settings
- `TimerSettings` is saved as one JSON blob. It has a hand-written `init(from:)` that reads each field on its own, so old saved data missing a newer field keeps its other values. **When adding a field, add a `read(...)` line for it**, or it will never load.
- `nil` ("No limit") is saved by leaving the key out (Swift's default), so for optional fields a missing key means `nil`, not the default. A new optional field with a non-nil default would need different handling.
- Settings change only through `BreakScheduler.apply(_:)`, which saves and applies them (e.g. restarts the countdown when the interval changes). The settings UI binds to it with a custom `Binding`.
- Launch at login uses `SMAppService.mainApp`. Its state lives in macOS, so it's read back after every change instead of being saved by us. While running from `build/`, the login item points at that copy.
- The settings window is an `NSWindow` + `NSHostingController`, not a SwiftUI `Settings` scene: it's opened from the AppKit status menu, and needs `NSApp.activate()` because the app is menu-bar-only.
- **Stage Manager** floats windows of menu-bar-only (`.accessory`) apps over the current stage. So the app switches to `.regular` (Dock icon) while settings are open and back to `.accessory` in `windowWillClose`.
- Slider tick labels are placed by estimate (track inset ~10 pt each side); they matched by eye.

## Assets & licensing
- BreakTimer (github.com/tom-james-watson/breaktimer-app) is **GPL-3.0**. OK to use its sounds/icons in this personal app. Sharing or selling the app would require publishing its source under GPL.
- Visual style target: LookAway's gradient (purplish-pink → orange). Check colours against `resources/lookaway-free-trial-screenshots/app_icon.png`.
