# Canopy architecture

A short tour of how Canopy is built, for anyone who wants to read the code or port it (for example to Linux). Canopy is a macOS menu bar app in Swift: about 4,200 lines, of which ~900 are plain logic that doesn't depend on the Mac.

## The big idea: one tick a second

Nothing in the app has its own timer for breaks. `App/AppDelegate.swift` runs one loop, once a second:

1. Ask macOS how long since the last mouse/keyboard input (and since the last key press or drag).
2. Ask Smart Pause whether something should hold the timer (a call, a focus app, Focus mode).
3. `scheduler.tick(now:idleSeconds:typingIdleSeconds:smartPause:)`: the scheduler updates its state.
4. Each feature looks at the scheduler's new state and shows or hides its windows (alerts, wellness flash, Clock Out, menu bar text). The break screen watches the scheduler's state and opens itself.

Because the scheduler gets the time passed in, tests can say "20 minutes later" without waiting, and a gap of more than 10 s between ticks is treated as "the Mac was asleep".

```
          every second
AppDelegate ──────────────► BreakScheduler (Core)  ◄── settings, stats, rules
    │  idle time, Smart Pause        │ state: working / on break / paused / stopped
    ▼                                ▼
 Features read the state and draw: menu bar · break screen · alerts · wellness · Clock Out · settings
```

## The parts

### Portable: `Canopy/Core/` (Foundation only, no Mac UI)

| File                   | What it does                                                                                  |
|------------------------|-----------------------------------------------------------------------------------------------|
| `BreakScheduler.swift` | The state machine: work countdown, breaks, long breaks, snooze/skip rules, idle and sleep, Smart Pause hold and cooldown, typing hold, overtime, office hours, planned breaks, Clock Out time, stats recording. |
| `TimerSettings.swift`  | Every setting, saved as one JSON blob in `UserDefaults`. Old saved data keeps its values when new settings are added. |
| `WellnessTimer.swift`  | When posture and blink reminders are due (screen time only).                                   |
| `DaySchedule.swift`    | Office hours and planned breaks (clock-time rules).                                            |
| `StatsLog.swift`       | Breaks taken / skipped / snoozed per day, the 7-day numbers and the streak.                    |
| `BreakMessages.swift`  | Built-in exercises and messages, plus the user's own; picks one per break.                     |
| `TimeFormat.swift`     | `19:42`, `20m`, `00:03` formatting.                                                            |
| `SoundChoice.swift`    | The list of sounds and their file names.                                                       |

These only use `Foundation` and `Observation`, both part of the open-source Swift toolchain, so they should build on Linux unchanged (`UserDefaults` exists in Linux Foundation too, or swap it for a JSON file in `~/.config/canopy/`). Tests are in `CanopyTests/` (Swift Testing, 93 tests). Today they run inside the Mac app (`@testable import Canopy`). To run them on Linux, move `Core/` into its own Swift package target and point the tests at that.

Not quite all the logic is in Core. Some "when to show what" decisions live in the Mac-side controllers, e.g. `AlertsController` (when the heads-up, countdown and overtime nudge appear) and `WellnessController` (when screen time counts). A port would copy those rules.

### Mac-only: `Canopy/App/`, `Canopy/Features/`, `Canopy/Shared/`

SwiftUI and AppKit, one folder per feature. Each row is what Canopy uses on the Mac and what a Linux version could use instead. Linux answers depend a lot on the desktop (GNOME, KDE, Sway/Hyprland) and on X11 vs Wayland.

| Feature (folder)                     | macOS API used                                                       | Linux equivalent                                                                                       |
|--------------------------------------|----------------------------------------------------------------------|--------------------------------------------------------------------------------------------------------|
| Idle time (`App/AppDelegate`)        | `CGEventSource.secondsSinceLastEventType`                            | X11: XScreenSaver extension. Wayland: `ext-idle-notify-v1`, or GNOME's `org.gnome.Mutter.IdleMonitor` (D-Bus). |
| Menu bar countdown (`MenuBar`)       | `NSStatusItem` with a SwiftUI label                                  | StatusNotifierItem / AppIndicator (KDE, most desktops; GNOME needs the AppIndicator extension).         |
| Break screen (`BreakScreen`)         | Borderless `NSPanel` per display above everything, `NSVisualEffectView` blur, wallpaper via `NSWorkspace.desktopImageURL`, Core Animation timer | GTK4 + `gtk4-layer-shell` (wlroots/KDE) or fullscreen X11 windows. Blur is compositor-specific; easier to blur the wallpaper image (read from `gsettings org.gnome.desktop.background picture-uri`). |
| Keyboard on break screen             | `NSEvent.addLocalMonitorForEvents` (swallows typing, Esc, "emergency") | Grab the keyboard in the overlay window (GTK key controller).                                          |
| Lock screen                          | Private `SACLockScreenImmediate`                                     | `loginctl lock-session`.                                                                               |
| Alert pills (`Alerts`)               | Floating `NSPanel`s with Liquid Glass                                | Small layer-shell / always-on-top undecorated windows.                                                 |
| Alerts as notifications              | `UNUserNotificationCenter` with action buttons                       | `org.freedesktop.Notifications` (libnotify), which supports actions.                                   |
| Smart Pause: mic / camera (`SmartPause`) | CoreAudio `DeviceIsRunningSomewhere`, CoreMediaIO                | PipeWire: look for running audio-input and video nodes (`pw-dump`).                                    |
| Smart Pause: app in front            | `NSWorkspace.frontmostApplication`                                   | X11: `_NET_ACTIVE_WINDOW`. Wayland: compositor-specific (Sway/Hyprland IPC, a GNOME extension).        |
| Smart Pause: Focus mode              | Shortcuts automations opening `canopy://focus-on` / `focus-off`      | GNOME Do Not Disturb (`gsettings org.gnome.desktop.notifications show-banners`), KDE via D-Bus.        |
| Wellness flash (`Wellness`)          | Click-through full-screen `NSPanel`; hidden from recordings with `sharingType = .none` | Same overlay approach as the break screen. No general way to hide from recordings.        |
| Sounds (`Shared/SoundPlayer`)        | `NSSound` playing `.m4a` files                                       | `pw-play` / `paplay`, GStreamer or libcanberra (convert sounds to `.ogg`).                             |
| Global shortcuts (`Shortcuts`)       | KeyboardShortcuts package (MIT)                                      | XDG desktop portal GlobalShortcuts (KDE, newer GNOME); X11 `XGrabKey`.                                 |
| Launch at login                      | `SMAppService.mainApp`                                               | A `.desktop` file in `~/.config/autostart/`, or a systemd user service.                                |
| Settings window (`Settings`), Welcome, Clock Out | SwiftUI (`NavigationSplitView`, Swift Charts for stats)  | GTK4 + libadwaita (from Swift via a binding such as Adwaita for Swift, or rewrite the UI in another language). |
| Accent-coloured app icon (`Shared/Accent`) | SwiftUI `ImageRenderer` → `NSApp.applicationIconImage`         | Not needed; use a fixed icon.                                                                          |

## Project setup

- The Xcode project is generated from `project.yml` by XcodeGen (`xcodegen`), so it isn't in git.
- One dependency: KeyboardShortcuts (Sindre Sorhus, MIT), Mac-only.
- Commands to build, test and install are in `CLAUDE.md`. Design decisions and gotchas are in `docs/DECISIONS.md`.

## Licences

- **Canopy's own code** has no licence file yet, which legally means "all rights reserved". If you share it with someone to port or reuse, add a `LICENSE` first (e.g. MIT, or GPL-3.0 to match the sounds).
- **Sounds:**
  - gong, blip, bloop, ping and sci-fi come from **BreakTimer** and are **GPL-3.0**. Fine for personal use. If the app is shared with them inside, it has to be shared under GPL-3.0 with its source.
  - From **Stretchly**: crystal glass is **CC BY 3.0** (credit required), wind chime and tic-toc are **CC0**.
  - Credits are in `Canopy/Resources/Sounds/CREDITS.md`.
- A Linux port that reuses only `Core/` and brings its own sounds has none of these constraints, apart from whatever licence Canopy's code gets.
