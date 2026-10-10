# Decisions & Gotchas

Technical choices, the reasons for them, and mistakes not to repeat. Add to this whenever something non-obvious is learned.

## Working with the user
- Not a software engineer: explain jargon in plain language, moderate detail.
- **Plan first** for anything non-trivial, wait for a go-ahead. **Never commit unless asked.**
- Visual things (animations, windows, menu bar) can't be checked from the terminal: Terminal has no Screen Recording permission, so `screencapture` fails. Give the user a numbered check list and let them verify.
- **But views can be rendered to PNGs from a throwaway test** (no permission needed): SwiftUI-only views with `ImageRenderer`; Forms and other AppKit-backed views by putting an `NSHostingView` in an off-screen borderless `NSWindow` and using `cacheDisplay(in:to:)`. Liquid Glass buttons and toggle tints don't draw this way, but layout, text and charts do. Good for catching overlaps before the user looks. Don't commit the test.
- Keep `docs/` up to date (PROGRESS, PLAN, PROBLEMS, this file) so work survives conversation compaction.
- Git identity is `domino-jockey <hayden.tus@gmail.com>`; the user hasn't said whether that's right. Ask before changing anything.

## Project setup
- **XcodeGen**, not hand-made Xcode projects. `project.yml` is the source of truth; `*.xcodeproj` is gitignored. Run `xcodegen` after adding/removing files or changing settings.
- Xcode 27's welcome-window "App" button makes an unusable draft in `~/Library/Developer/Xcode/UntitledProjects/` (multi-platform, placeholder bundle ID). Don't use it.
- Screenshot filenames from macOS contain a **narrow no-break space** (U+202F) before "AM/PM". Typing the name fails; use globs (`Screenshot*9.02.14*`).
- Red "Cannot find X in scope" diagnostics from SourceKit (the editor's checker) are false alarms in this project. Trust `xcodebuild`.

## Timer
- `BreakScheduler` has **no clock**; everything goes through `tick(now:idleSeconds:)`. Keeps it fully testable with `FakeClock` (in `CanopyTests/BreakSchedulerTests.swift`).
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
- The menu bar icon is an SVG in `Assets.xcassets/MenuBarIcon` (template image), plain black/white like other menu bar icons. It's the app icon's two leaves in one colour (back leaf trimmed with a gap where the front one covers it), made by `design/make-icon.swift` and cropped so it fills the menu bar height. Icon Composer takes the SVG layers directly (no PNG needed); a see-through front layer shows the back leaf's edge, so the front leaf's translucency is off. **Change the icon and the glyph together** by editing and re-running the script.
- Live Status settings (`showLiveStatus`, `menuBarDisplay`, `timerStyle`) live in `TimerSettings`, so `MenuBarLabel` (which already watches the scheduler) updates by itself. The General page's preview strip is just another `MenuBarLabel`.

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
- Sidebar rows are plain `Button`s in a `List` (no `selection:`), with the selected row's pill drawn by `.listRowBackground`. Why: `List` selection always uses the accent colour; the user wants LookAway's soft pill. The ‹ › buttons use a small history list in `SettingsView`.
- Controls take their colour from `.tint(Mocha.mauve)` on the detail pane. Custom views that should match use `.foregroundStyle(.tint)`, not `Color.accentColor` (`.tint` doesn't change `Color.accentColor`).

## Alerts
- Each pill is an `AlertPanel`: a borderless, non-activating `NSPanel` at `.statusBar` level on all Spaces. It never takes the keyboard. `FirstClickHostingView` (`acceptsFirstMouse` → true) makes the first click on an unfocused pill press its button.
- `AlertsController.update()` runs every tick, right after `scheduler.tick`, and decides what's shown from the scheduler's state. No separate timers, except a 60 fps one that moves the countdown pill with the mouse while it's up.
- The pills read an `AlertModel` the controller fills in, not the scheduler directly, so Preview can show sample values (`0:10`, `5`, `45 minutes`).
- Overtime uses `BreakScheduler.timeSinceBreak` (reset only by a break that ends normally or via End Break, and by long idle) and `overtimeStep` (0 past the interval, +1 every 15 min). `endBreak(taken:)` marks skips so they don't reset it. Each step shows the nudge once.
- Heads-up and overtime share the top spot; the heads-up wins, the nudge waits until it's gone.

## Performance
- **`@Observable` notifies on every set, even with the same value.** Anything set once per tick redraws every view that reads it, hidden windows included. Set only when different (`AlertsController.assign`, `BreakScheduler.tick`). This took idle CPU from ~10% to ~1%.
- Measure with `ps -o %cpu=,rss= -p $(pgrep -x Canopy)` over a minute, and `sample Canopy 5` to see where time goes. After `pkill`, wait a second before `open`, or launch fails with error -600.
- **Break screen: SwiftUI draws it on the CPU, all of it, every animation frame** (`CGDrawingLayer` in `sample`). So any animation that never stops costs a lot: `.numericText` on the timer (spring longer than a tick, digit blur on the CPU) was ~50% of a core; a `.linear(duration: 1)` bar refreshed every tick does the same. Even a 0.3 s SwiftUI animation each second stayed ~50%. `.drawingGroup()` (Metal) only brought `.numericText` to ~18%.
- **Fix: anything that moves on the break screen is a Core Animation layer**, not a SwiftUI animation. The timer (`RollingTime.swift`) is one `CATextLayer` per digit, rolled up + faded like the menu bar clock; the bar and skip ring glide via `glide()` in `BreakView.swift`, re-aimed each tick from the on-screen value, at 20 fps (`preferredFrameRateRange`; 30 → 20 made no measurable difference). Break CPU: 58% → ~1% (Canopy), WindowServer ~39% → ~18%. WindowServer numbers vary ±4 between runs.
- The live behind-window blur is switched off (`state = .inactive`) once the wallpaper covers it, back on for the fade-out: small WindowServer saving. Marking the window opaque made no difference.
- How to measure a break: start one via the menu with `osascript` (System Events → menu bar 2 of process Canopy → "Start break now"), then `top -l 2 -s 1 -pid …` for Canopy and WindowServer from second 3 to 18 of a 20 s break.

## Smart Pause
- Detection lives in `SmartPauseMonitor` (hardware/app checks, not testable); the rules (hold, cooldown, typing hold, welcome back) live in `BreakScheduler.tick`, which gets the detected reason as a parameter. Tests pass fake reasons.
- Mic: Core Audio `kAudioDevicePropertyDeviceIsRunningSomewhere` on every device with input streams. Camera: CoreMediaIO `kCMIODevicePropertyDeviceIsRunningSomewhere`. Neither needs a permission prompt.
- **macOS Focus can't be read directly.** `INFocusStatusCenter` needs the Communication Notifications entitlement, which needs a paid developer provisioning profile (the build fails with "requires a provisioning profile"). Without it, it says "authorized" but always reports not focused. The DoNotDisturb database in `~/Library/DoNotDisturb/DB/` has no "active" record on macOS 27. So: Shortcuts automations open `breakreminder://focus-on/off` (URL scheme in `Canopy/App/Info.plist`, merged into the generated Info.plist via `INFOPLIST_FILE`).
- Typing idle = the smallest of `secondsSinceLastEventType` for keyDown, left- and right-mouse-dragged.
- `returnsFromIdle` is a counter, not a flag: the alerts controller compares it with the last value it saw, so it can't miss or double-show a return.

## Scheduling
- Times of day are saved as **minutes after midnight** (`Int`), in the Mac's time zone. Settings pickers convert with `DaySchedule.date(forMinutes:)` / `minutes(of:)`.
- "Has 12:30 just passed?" = `DaySchedule.passed(minute, from: lastTick, to: now)`: true exactly once across consecutive ticks. Skipped when the tick gap is > 10 s (asleep), so waking up at 1 PM doesn't start lunch.
- `checkClockTimes` runs in a `defer` after the countdown in `tick`, so a planned break starting this tick isn't counted down by a second at once. (Swift runs `defer`s in reverse order, so it still sees the old `lastTick`.)
- `clockOuts` is a counter for the same reason as `returnsFromIdle`.

## Onboarding
- The welcome window is shown once (`hasSeenWelcome` in UserDefaults) and **skipped under tests** (`XCTestConfigurationFilePath` is set): tests run inside the real app with the real UserDefaults, so they'd use it up otherwise. To see it again: `defaults delete com.jammyjellyfish.BreakReminder hasSeenWelcome`.

## Keyboard shortcuts
- Swift packages go in `project.yml` under `packages:` plus `dependencies: - package: Name` on the target. Xcode downloads them into `build/SourcePackages/` (gitignored with `build/`).
- `KeyboardShortcuts.Recorder` stores shortcuts in `UserDefaults` itself, so they're not part of `TimerSettings`.

## Look & theme
- **All colours come from `Theme/Mocha.swift`** (Catppuccin Mocha). No hard-coded colours elsewhere, so a future Themes feature only has to swap that palette. The settings window is forced dark (`.preferredColorScheme(.dark)`, window background *base*).
- Tried and dropped (user's call): following the system accent colour, "minimal mono" greys, LookAway's purple-pink gradients, gradient-coloured enforcement cards.
- **App icon** is an Icon Composer document, `Canopy/Resources/AppIcon.icon` (a folder: `icon.json` + SVG layers in `Assets/`). Xcode compiles it; `ASSETCATALOG_COMPILER_APPICON_NAME: AppIcon` in `project.yml` points at it. Open it in Icon Composer (inside Xcode) to tweak by hand.
  - In `icon.json`, the **first group is drawn in front**. `fill` is the background (`solid` or `linear-gradient`); each group has `translucency`, `specular`, `shadow`.
  - Preview without building: `"/Applications/Xcode.app/Contents/Applications/Icon Composer.app/Contents/Executables/ictool" Canopy/Resources/AppIcon.icon --export-image --output-file preview.png --platform macOS --rendition Default --width 512 --height 512 --scale 2`
  - **SF Symbols are not allowed in app icons** (Apple's licence), so the leaf is drawn as SVG by a script. SF Symbols are fine elsewhere in the UI.
- macOS caches app icons. After changing the icon, refresh it: `/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f /Applications/Canopy.app && touch /Applications/Canopy.app && killall Dock`

## Assets & licensing
- BreakTimer (github.com/tom-james-watson/breaktimer-app) is **GPL-3.0**. OK to use its sounds/icons in this personal app. Sharing or selling the app would require publishing its source under GPL.
- Visual style: Catppuccin Mocha (catppuccin.com/palette, MIT licence). LookAway is still the reference for layout, not colours.
- Stretchly's sounds (from freesound.org): crystal glass is **CC BY 3.0 (credit required)**, wind chime and tic-toc CC0. "reverie" was left out: no licence listed. Credits live in `Sounds/CREDITS.md` and the About page.
- Sounds are stored as AAC `.m4a` (`afconvert -f m4af -d aac -b 128000`), ~10× smaller than WAV. `NSSound(named:)` finds them without the extension.

## Canopy look
- Colours: system colours and the accent colour everywhere. No palette file, no brand colours.
- **macOS can't tint an app's own icon to the accent colour.** Finder keeps the fixed (green) icon; `AccentIcon` sets `NSApp.applicationIconImage` to a flat redraw with the leaf in `controlAccentColor`, and redraws on `NSColor.systemColorsDidChangeNotification`. That covers the Dock, About, Welcome and the flash reminder.
- **In Swift Charts, `.foregroundStyle(.secondary)` means "secondary of the chart's accent", so labels came out tinted.** Use `Color.secondary` for grey chart text and lines.
- The selected sidebar row stays a soft grey pill, not the accent colour (the user asked for LookAway's look earlier).
- **Two copies exist:** `build/…/Debug` (what the restart command opens) and `/Applications` (what you open yourself / Launch at login). After a change the user should see, install to `/Applications` too, or they may be looking at the old copy.

## Rename to Canopy
- Only `PRODUCT_NAME` changed; the **bundle ID stayed** `com.jammyjellyfish.BreakReminder`. Settings, stats, shortcuts, notification permission and even the **Launch at login item** follow the bundle ID, so they all carried over (login item checked with `sfltool dumpbtm`: it moved to `/Applications/Canopy.app` by itself).
- Later the project, target, scheme and folders were renamed too (source reorganised into `Canopy/App`, `Core`, `Features`, `Shared`, `Resources`; see `CLAUDE.md` → Source layout).

## Settings window
- **`navigationSplitViewColumnWidth` alone is ignored in this AppKit-hosted window** (the sidebar stayed ~145 pt and cut off labels). Adding `.frame(minWidth:idealWidth:)` on the sidebar `List` makes it stick. Checked with a screenshot.

## Floating windows
- **Never let SwiftUI resize a window we move or size ourselves.** `NSHostingView` resizes its window to fit by default. The alert pills (moved 60×/s for the countdown) then fought our `setFrame` calls: pills jumped sideways, and AppKit got stuck in a layout loop and crashed ("more Update Constraints passes than views"). Fix in `AlertPanel`: the hosting view sits inside a plain container view, so it reports its size (`fittingSize`, after `layoutSubtreeIfNeeded()` so it reflects changes made just now) but can't resize the window. (`sizingOptions = []` alone made `fittingSize` near zero: pills too small for their text.) Crash reports are in `~/Library/Logs/DiagnosticReports/Canopy-*.ips` (`BreakReminder-*.ips` before the rename).
- Wellness reminders due within a minute of each other show as one flash (`WellnessTimer.mergeWindow`); their counts drift apart when intervals change.
- Smart Pause cooldown = "no break within N of Smart Pause ending": on end, `workRemaining` is raised to at least the cooldown. The countdown never freezes for it.
