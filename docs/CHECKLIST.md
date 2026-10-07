# Build Checklist

What we're building is described in [`FEATURES.md`](FEATURES.md) §3. LookAway is the main reference. DeskRest-only features come later.

**Tech stack** (what LookAway uses):
- **Swift**: Apple's programming language for Mac apps.
- **SwiftUI**: Apple's newer way to build screens. You describe the UI and it draws it. We'll use it for the settings window and most visuals.
- **AppKit**: Apple's older Mac UI toolkit. We need it for things SwiftUI can't do: the menu bar item, full-screen overlay windows above everything, and global keyboard shortcuts.
- **Target: macOS 27+.** This is a personal app for your Mac only, so we can use the newest APIs, including Liquid Glass (Apple's frosted-glass style).

Docs live in `docs/`: progress so far in [`PROGRESS.md`](PROGRESS.md), technical decisions and gotchas in [`DECISIONS.md`](DECISIONS.md). Keep them updated as work happens.

Each phase ends with a **✅ Done when** line. A phase isn't finished until that check passes on your Mac.

---

## Phase 0: Project setup
- [x] Point Terminal at full Xcode (`sudo xcode-select -s /Applications/Xcode.app/Contents/Developer`) and run `sudo xcodebuild -runFirstLaunch`.
- [x] Create the project with **XcodeGen**: `project.yml` is the recipe. Run `xcodegen` to (re)create `BreakReminder.xcodeproj`. App name **BreakReminder**, bundle ID `com.jammyjellyfish.BreakReminder`.
- [x] Set deployment target to macOS 27.
- [x] Make it a **menu-bar-only app**: no Dock icon (`INFOPLIST_KEY_LSUIElement = YES` in `project.yml`).
- [ ] Folders inside `BreakReminder/` (`Timer/`, `Break/`, `Alerts/`, …): created as each phase adds its first file.
- [x] `git init` and add a `.gitignore` for Xcode.
- [x] ✅ **Done when:** the app builds, launches, shows no Dock icon, and quits cleanly.

## Phase 1: Timer engine (the brain)
- [x] Create a `TimerSettings` store that saves preferences to disk (`UserDefaults`, Apple's built-in key-value storage).
- [x] Create a `BreakScheduler`, a state machine (a thing that is always in exactly one state). States: *stopped · working · on break (short/long) · paused*. Heads-up/countdown are "working with little time left", not separate states.
- [x] Count **active screen time**, not clock time. Stops counting after 2 min without input. 5 min idle counts as a break taken and resets the cycle.
- [x] Defaults: break after 20 min, break length 20 s, every 4th break is long (3 min).
- [x] Actions: start, stop, pause/resume, start break now, skip next break, end break, snooze +1/+5/+15 min.
- [x] Sleep/wake: a long gap between ticks counts as time away (no special code). Screen lock relies on idle time growing while locked (confirmed in Phase 2).
- [x] Unit tests for the scheduler using a fake clock, so tests don't wait 20 real minutes.
- [x] ✅ **Done when:** tests pass for normal cycle, long-break cycle, snooze, pause/resume, and sleep/wake. (15/15 passing)

## Phase 2: Menu bar
- [x] Menu bar item showing **icon + `m:ss`**, matching `resources/macos-timer-menu-bar-appearance/` (timer glyph + `0:38`). One fixed style, no display options. Built with AppKit `NSStatusItem` + a SwiftUI label, because `MenuBarExtra` can't animate.
- [x] **Rolling digit animation** when the number changes (SwiftUI `.contentTransition(.numericText())`), like the recording.
- [x] SF Symbols icons (adapt to light/dark menu bars): ⏱ working, ☕ on break, ⏸ paused. Custom glyph comes in Phase 14.
- [x] Dropdown menu: time to next break, Pause/Resume, Start break now, Snooze ▸ (1/5/15 min), Skip next break, End break (during a break), Quit.
- [x] "Settings…" menu item (Phase 5).
- [x] ✅ **Done when:** the menu bar countdown ticks smoothly with rolling digits and every menu action works. (All 8 manual checks passed.)

## Phase 3: Break screen (the signature look)
- [x] Borderless full-screen window **on every display**, above all apps and full-screen spaces (window level + `canJoinAllSpaces`, `fullScreenAuxiliary`).
- [x] **Blur-into-wallpaper background**:
  - [x] Get each screen's wallpaper (`NSWorkspace.desktopImageURL(for:)`), shrink it, apply a heavy blur (Core Image), plus a slight dark tint so text is readable.
  - [x] Entry animation in two stages, no permissions needed: live blur of the screen behind (`NSVisualEffectView`) fades in (0.4 s), then the blurred wallpaper + text fade in (0.6 s). Exit reverses it.
  - [x] Fall back to a gradient if the wallpaper can't be read.
- [x] Layout (from `lookaway-website-screenshots/`): small clock at top · big title · subtitle · thin divider · large rolling countdown · Liquid Glass buttons **Skip Break** / **Lock Screen** · "Press esc twice to skip" hint. ("N snoozes left" comes with Phase 4.)
- [x] SF Pro font, Liquid Glass buttons. (No rounded corners: the screenshot's corners are the MacBook screen itself.)
- [x] Rotating break messages: 5 short-break, 3 long-break.
- [x] Mouse and keyboard input go to the overlay. Windows are non-activating panels that take the keyboard back whenever another app comes to the front (e.g. after unlocking, or ⌘-Tab).
- [x] **Lock Screen** uses macOS's undocumented `SACLockScreenImmediate` (same as ⌃⌘Q). Falls back to `pmset displaysleepnow` if it's ever removed.
- [x] ✅ **Done when:** a test break covers all monitors with a smooth blur-in, counts down, and blurs out. Compare side by side with the LookAway screenshot. (All checks passed.)

## Phase 4: Break rules
- [x] Enforcement modes (Casual / Balanced / Hardcore). The 3 visual cards for picking one are on the Screen Breaks settings page (Phase 5).
  - [x] *Casual*: Skip works anytime.
  - [x] *Balanced*: Skip button shows a filling ring and unlocks **halfway through the break** (was a fixed 5 s).
  - [x] *Hardcore*: no Skip button, no "Skip next break", no snoozing a break that's on screen.
- [x] **Max snoozes per break** (default 2, or No limit). Snooze options disappear once used up.
- [x] **Snooze stack** like LookAway (`resources/break_screen_recording/extended_snooze_options.png`): `+1 min` / `+5 min` pills tucked behind Skip, float up on hover. One hover zone covering the whole column. Pills must be clickable.
- [x] **Daily skip limit** (default 3): counts on-screen skips + "Skip next break". Survives app restarts, resets at midnight. Emergency skips don't count.
- [x] Double-Esc action (skip / snooze / nothing). Ignores key-repeat from holding Esc.
- [x] **Emergency skip: type "emergency"** on the break screen, any mode. Typed letters show in the footer. (Replaces hold-Esc.)
- [x] "Let me End Break early if nearly done" (last 25%).
- [x] "Keep break screen up until I press End Break". Hold the next cycle until pressed.
- [x] "Lock my Mac when a break starts" + working **Lock Screen** button.
- [x] Long breaks: every Nth break, own duration (from Phase 1).
- [x] Simplify the menu bar: no break-time label or menu items (the break screen covers the menu bar anyway).
- [x] ✅ **Done when:** tests pass for every rule, and by eye: snooze stack opens/clicks correctly, Balanced unlocks at half time, typing "emergency" skips, skips stop after 3 in a day.

## Cleanup (between Phase 4 and 5)
- [x] Move all docs into `docs/`, add `docs/PROGRESS.md`, `docs/DECISIONS.md`, and a root `CLAUDE.md` pointing at them.
- [x] Rename leftover screenshots (`alerts.png`, `alerts_2.png`, `lock_screen.png`).
- [x] Rename the app **Glance → BreakReminder** (bundle ID `com.jammyjellyfish.BreakReminder`).
- [x] Zip v1's git history into `docs/archive/breakreminder-v1-history.zip`, delete `~/Projects/breakreminder`, rename this folder to `~/Projects/breakreminder`.
- [x] Start a fresh Claude Code session in the renamed folder.

## Phase 5: Settings window
- [x] Sidebar window like LookAway/System Settings (`NavigationSplitView` in an AppKit window), opened from "Settings…" in the menu.
  - Only pages with real settings are shown. Now: **General** · *Focus & Wellbeing:* Screen Breaks. Planned order for later pages: *Focus & Wellbeing:* Smart Pause, Wellness Reminders, Stats · *Behavior & Feedback:* Alerts/Nudges, Sounds, Keyboard Shortcuts · About.
- [x] Coloured sidebar icons, grouped "card" rows, accent colour for toggles (now Catppuccin Mocha, see Look & feel).
- [x] General: Launch at login (`SMAppService`).
- [x] Screen Breaks: interval, break length, long breaks, enforcement cards, skip/snooze limits, double-Esc, End Break early, hold, lock on start.
- [x] Durations use **DeskRest-style sliders** with fixed stops (big number above, clickable labels under each stop).
- [x] Settings loading tolerates missing fields (old saved data keeps its values).
- [x] Changes apply right away. A new break interval restarts the countdown; a new break length applies from the next break.
- [ ] Each later phase adds its own page here.
- [x] Follows system light/dark mode. (Replaced by always-dark Mocha in Look & feel.)
- [x] ✅ **Done when:** every page opens, every setting saves and survives an app restart. (36 tests passing, all 9 by-eye checks passed.)

## Look & feel (after Phase 5, from `PROBLEMS.md`)
- [x] Slim System Settings-style title bar with ‹ › back/forward.
- [x] Catppuccin Mocha palette for the whole app (`Theme/Mocha.swift`): settings window, sidebar icons, break screen.
- [x] Sidebar selection: soft pill like LookAway, not the accent colour.
- [x] Our own enforcement cards: tiny break screens.
- [x] General: Menu bar section with Live Status, Display, Timer style, and a live preview strip.
- [x] App icon in Icon Composer format: Mocha gradient tea mug, Liquid Glass.
- [x] Menu bar icon: the same mug, monochrome.
- [x] ✅ **Done when:** checked by eye; 38 tests passing.

## Phase 6: Alerts & nudges
- [x] Alert position: top left / top center / top right.
- [ ] ~~"Progressive blur" edge style for alert pills.~~ Left out for now (plain glass). Add later if missed.
- [x] **Heads-up before break**: appears N s before (default 10) and stays until the break starts (user's call: one setting). Shows countdown + friendly line + buttons *Start this break now · +1m · +5m · +15m*.
- [x] **Cursor-following countdown pill** ("Short break in 5") during the last N seconds. Pill follows the mouse and ignores clicks. Shows alongside the heads-up.
- [x] **Overtime nudge** ("45 minutes without a break") when breaks are being dodged, repeating every 15 min. **Click to dismiss**. Option to show even when paused.
- [ ] Smart-pause alerts: moved to Phase 7.
- [x] Preview button for each alert on the settings page.
- [x] ✅ **Done when:** all three alert types appear at the right time, in the chosen position, and their buttons work.

## Phase 7: Idle detection & Smart Pause
- [x] Idle detection (seconds since last input, via `CGEventSource`). (Already in Phase 1.)
- [x] Idle mode *Automatic*: short idle pauses the timer. Long idle counts as a break and resets the timer. "Count as a break when away for" picker on the Smart Pause page.
- [x] "Welcome back" heads-up after idle.
- [x] Hold off breaks while **typing or dragging** (wait for a 2 s pause in input, at most 30 s).
- [x] Triggers (each toggleable):
  - [x] **Meetings/calls**: microphone or camera in use (Core Audio / CoreMediaIO).
  - [x] **Deep focus apps**: user-picked apps in front (Zoom, OBS, games…).
  - [x] **macOS Focus mode** active. Via a Shortcuts automation (`breakreminder://focus-on` / `focus-off`): macOS won't tell free-signed apps about Focus.
- [x] Cooldown after smart pause ends (default 1 min).
- [x] Smart-pause alerts (moved from Phase 6): a small pill when a smart pause starts/ends, using `AlertPanel` and the alert position setting.
- [ ] ✅ **Done when:** joining a FaceTime call, opening a deep focus app, and stepping away each pause the timer, and it resumes correctly afterward. (Tests pass; waiting on the by-eye check.)
- (Video playback detection was dropped: the point is to make sure breaks happen.)

## Phase 8: Wellness reminders
- [x] 📸 DeskRest settings screenshots: `resources/deskrest-settings-screenshots/`. Flash reminder in action: `resources/deskrest-flash-reminder.mov`.
- [x] Two styles to try, pick per reminder:
  - [x] **LookAway style**: glossy bubble (below).
  - [x] **DeskRest style**: screen darkens briefly, app icon appears, "Watch your posture" text underneath, then fades back to normal.
- [x] **Posture reminder** bubble (glossy gradient circle, up-arrow animation). Default every 10 min.
- [x] **Blink reminder** bubble (closing/opening eyes animation). Default every 5 min.
- [x] Per reminder: enabled, interval, style, size, 3×3 position grid, ▶ preview button. (Both start **off**.)
- [x] Common: dim screen while showing · keep active during smart pause · hide from screen recordings (`sharingType = .none`) · reset timers after a break.
- [ ] ✅ **Done when:** both reminders show at the chosen spot/size/interval and don't appear in a screen recording. (Tests pass; waiting on the by-eye check.)

## Phase 9: Sounds
- [x] Use sounds from the open-source **BreakTimer** app (GPL-3.0: fine for personal use; sharing the app would mean publishing its source). Gong pair for breaks, blip for reminders.
- [x] Two toggles: **break sounds** (start/end) and **reminder sounds** (posture, blink, alerts).
- [x] One volume slider.
- [ ] ✅ **Done when:** sounds play at the chosen volume, and each toggle silences its group. (Tests pass; waiting on the by-ear check.)

## Phase 10: Keyboard shortcuts
- [ ] Global shortcut recorder rows (the [`KeyboardShortcuts`](https://github.com/sindresorhus/KeyboardShortcuts) Swift package does this well).
- [ ] Three actions: **Pause/Resume** · **Start break now** · **Snooze 5 min**.
- [ ] ✅ **Done when:** each shortcut works while another app is in front.

## Phase 11: Scheduling
- [ ] **Office/working hours**: per-weekday hours. Outside them, the app sleeps.
- [ ] **Planned breaks**: fixed-time breaks (e.g. 12:30 lunch, 45 min).
- [ ] **Clock Out** (DeskRest): at your end-of-day time, show a full-screen "time to stop" with a personal message.
- [ ] ✅ **Done when:** with hours set to end in 2 minutes, the app stops and Clock Out appears. A planned break fires on time.

## Phase 12: Break screen customization & exercises
- [ ] "Customize break screen" page: background = blurred wallpaper (default) / image / gradient · custom messages list · show/hide clock.
- [ ] **Built-in exercises** (DeskRest): about 10 eye/neck/shoulder/stand exercises with short instructions. Separate lists for short vs long breaks.
- [ ] ✅ **Done when:** a long break shows an exercise from the long-break list, and a custom message/background shows up.

## Phase 13: Stats
- [ ] Save a small daily log on disk: breaks taken, skipped, snoozed.
- [ ] Stats page: today's numbers, a 7-day bar chart (Swift Charts), and a **streak** (days in a row hitting your goal).
- [ ] ✅ **Done when:** after a few days of use, the numbers and streak match what actually happened.

## Phase 14: Polish
- [ ] App icon + menu bar glyph: based on **BreakTimer's** icons, restyled with LookAway's gradient (purplish-pink → orange; check colours against `resources/lookaway-free-trial-screenshots/app_icon.png`).
- [ ] Every animation is smooth (no jank) on all connected displays, including when a display is plugged in or out mid-break.
- [ ] Respect "Reduce motion" and "Reduce transparency" accessibility settings.
- [ ] First-launch onboarding: quick intro + ask for permissions only when a feature needs them.
- [ ] About page (version, credits).
- [ ] Check memory/CPU use stays low over a full day (Activity Monitor).
- [ ] ✅ **Done when:** a full workday of real use goes by with no bugs, glitches, or high CPU.

## Phase 15: Packaging (for your own Mac)
- [ ] Archive a Release build in Xcode.
- [ ] Sign it with your Apple ID ("Sign to Run Locally" is enough for personal use).
- [ ] Copy to `/Applications`, turn on Launch at login.
- [ ] ✅ **Done when:** it runs from `/Applications` after a reboot.

---

### Deliberately skipped
See [`FEATURES.md`](FEATURES.md) §3.2 for the full list and reasons.

## Later: Themes
- [ ] Turn `Mocha` into a `Theme` with the same colour names, one set per theme (Catppuccin Latte / Frappé / Macchiato / Mocha, maybe our own). Picker in General.
- [ ] Light themes (Latte) set light mode; dark ones set dark mode.
- [ ] Preset app icons: one `.icon` per theme, rendered at build time, set with `NSApp.applicationIconImage`. Only the **Dock** icon can change while running; Finder/Spotlight keep the built-in (Mocha) one.
