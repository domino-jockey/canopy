# Features: LookAway & DeskRest

Sources:
- `resources/lookaway-free-trial-screenshots/`: LookAway's settings window (free trial).
- `resources/lookaway-website-screenshots/`: break screen, heads-up alert, floating countdown.
- `resources/macos-timer-menu-bar-appearance/`: the menu bar look we want for the timer.
- `resources/break_screen_recording/`: LookAway's real break screen, including the snooze stack (`extended_snooze_options.png`).
- LookAway screenshots are named after the settings page they show (e.g. `smart_pause.png`, `lock_screen.png`).
- [lookaway.com](https://lookaway.com/) and [deskrest.com](https://deskrest.com/): for anything not visible in screenshots.

Legend: 📸 = seen in a screenshot · 🌐 = from the website only · ❌ = out of scope (iPhone/iPad/other devices).

---

## 1. LookAway

Requires macOS 13+. Settings window is a sidebar app (like System Settings) with sections:
**General · Focus & Wellbeing · Behavior & Feedback · Integrations · About**.

### 1.1 General 📸
- Launch at login (toggle).
- Language picker (System default).
- **Menu bar** (with a live preview strip of the menu bar):
  - **Live Status**: on/off · Display: *Icon and text* (other options likely icon only / text only) · Timer style: e.g. `20m`.
  - **Screen Score**: on/off · Display: *Icon and text* · Colored rings (toggle).
- **Updates**: automatically check · automatically download · "Check for updates" button.

### 1.2 Screen Breaks 📸
- **Show a break after** `20 minutes` *of focused screen time* (it counts active screen time, not wall-clock time).
- **Break duration**: `1 minute`.
- **Customize break screen** (sub-page, not captured). 🌐 Website says: custom backgrounds (images, wallpapers, gradients), personalized messages, custom sounds.
- **Long breaks**: "Every 4th break is a 3 mins long break".
- **Planned breaks**: fixed-time breaks (e.g. lunch, afternoon walk). Default: None.
- **Office hours**: only run during set hours. Default: Disabled.
- **Break enforcement** (3 visual cards):
  - *Casual*: skip anytime.
  - *Balanced*: skip after a pause (the Skip button has a loading ring that fills first).
  - *Hardcore*: no skips allowed.
- Advance skips allowed per day: `None` (skip a break before it arrives).
- Snoozes allowed per day: `No limit`.
- Snoozes allowed per break: `No limit`.
- **More**:
  - Double escape action on break screen: `Skip the break` (press Esc twice).
  - Let me "End Break" early if nearly done.
  - Keep the break screen up until I press "End Break". (While it's held, end-of-break automations and the next focus cycle wait.)
  - Lock my Mac automatically when a break starts.

### 1.3 Smart Pause 📸
- Hold off breaks while I'm typing, dragging, or dictating.
- **Dictation apps**: list of apps whose mic use counts as dictation, not a call ("+ Add an app").
- **Automatically pause during** (each has a toggle, most have "Options"):
  - Meetings or Calls (detects mic/camera use).
  - Video playback.
  - Screen recording or sharing.
  - Calendar Events (needs Calendar permission).
  - Deep focus apps (pick apps).
  - Gaming (fullscreen games).
- Cooldown after smart pause ends: `1 minute`.
- **Idle Tracking**:
  - Pause or resume when I step away: `Automatic` (pause or reset timers based on activity; asks if unsure).
  - Show a heads-up after returning from idle.

### 1.4 Wellness Reminders 📸
Two reminders side by side, each with an animated preview and a ▶ "try it" button:
- **Posture Reminder** (default every 10 min), shown as a small glossy bubble with an up-arrow.
- **Blink Reminder** (default every 5 min), shown as a small glossy bubble with blinking eyes.
- Per reminder: Enabled · Show every · Size (`Large`) · Position (3×3 grid picker) · Sound.
- **Common settings**:
  - Dim the screen when showing reminders.
  - Keep reminders active during smart-pause.
  - Make reminders invisible in screen recordings.
  - Reset timers after break.

### 1.5 Stats 📸
- Screen time stats per app (implied by "combine apps and websites").
- **Website usage stats**: per-domain time (e.g. `x.com 30m`), for chosen browsers (Brave, Safari…).
- Combine apps and websites stats (one list sorted by duration).
- "Screen Score" (shown in menu bar, with colored rings).

### 1.6 Alerts / Nudges 📸
- **Positioning**: Top left · **Top center** · Top right.
- Progressive blur (alert edges fade with blur).
- **Break reminder** (heads-up before a break):
  - Show a reminder before a break appears: on.
  - Show reminder `1 minute` before the break starts.
  - Keep the reminder visible for `10 seconds`.
  - 📸 Website: pill shows "00:03 · Almost time. Your eyes will appreciate this." with buttons **Start this break now · +1m · +5m · +15m**.
- **Smart pause alerts** (notify when smart pause kicks in) for: Meetings or Calls, Video playback, Calendar Events, Deep focus apps, Gaming, Focus Mode.
- **Countdown before break**: small pill "Short break in 05" that **follows your cursor**. Enabled, duration `5 seconds`.
- **Overtime nudge**: pill "45 minutes without a break" when you work past your screen time. **Shake (the mouse) to dismiss.** Option: show even when paused.

### 1.7 Lock Screen 📸
- Show break status on the Mac lock screen (pill: "☕ Coffee break • 14:40").
- Position: Below the clock / Above your picture.
- Liquid Glass style (toggle).
- Show over screen saver.
- Vertical offset slider.

### 1.8 Sounds 📸
- **Break sounds**: Sound pair (`Default`) · Play on break start ▶ · Play on break end ▶ · Volume.
- **Wellness reminder sounds**: Posture sound · Blink sound · Volume.
- **Alerts and nudges**: Break reminder sound · Smart pause notification sound · Return-from-idle sound · Overtime nudge sound · Volume.

### 1.9 Keyboard Shortcuts 📸
All are user-recordable global shortcuts ("Record Shortcut"):
- **Quick Look**: Show Quick Look (a quick status popup).
- **General**: Start · Stop · Restart (reset timers and cycles) · Pause or Resume.
- **Break**: Start next break now · Start a short break now · Start a long break now · Take a break for a custom duration.
- **Snooze**: Snooze upcoming break by 1 / 5 / 15 minutes.

### 1.10 Integrations
- ❌ iPhone / iPad Sync: breaks sync to iPhone/iPad, Live Activities on iPhone.
- **Automation** (page not captured) 🌐: run AppleScript at break start/end · Apple Shortcuts actions · macOS Focus Filters.

### 1.11 Break screen 📸 (website)
- Full screen, **blurred wallpaper** background (soft, colourful, out-of-focus), rounded corners.
- Small clock at top (`🕒 17:41`).
- Big title ("Eyes to the horizon") + subtitle ("Set your eyes on something distant until the countdown is over").
- Short divider line, then a large countdown (`00:02`).
- Buttons: **Skip Break** · **Lock Screen** (frosted glass pills).
- Footer hints: "4 snoozes available" · "Press [Esc] twice to skip the break".

### 1.12 Look & feel 📸
- App icon: pink/purple/orange gradient blob with sleepy closed eyes.
- Menu bar icon: same sleepy-eyes glyph + `20m`.
- Dark UI, coral/red accent toggles, gradient pink-purple-orange section icons.
- Light/dark mode follows the system 🌐.

---

## 2. DeskRest 🌐

Requires macOS 14.2+. (No screenshots, so this all comes from the website.)

### 2.1 Breaks
- Short breaks (default 20 s) for eyes and posture.
- Long breaks (default 3 min) for standing and stretching.
- Customizable durations.
- Different exercises assigned to short vs. long breaks.

### 2.2 Pause logic
- Pauses during video calls, meetings, and Focus mode.
- Idle detection (knows when you step away).
- Timer reset after long absence, so you don't get several breaks at once.

### 2.3 Reminder display
- Cursor-following countdown.
- Traditional notifications.
- **Posture flash**: a customizable brief screen flash.
- Customizable advance warning.
- Custom backgrounds/themes and audio cues.

### 2.4 Exercises & wellness
- **Unlimited custom break routines**.
- Custom exercises (eye strain, shoulder tension, standing).
- Posture correction alerts / "posture coach".

### 2.5 Scheduling
- Working hours (weekdays, weekends, custom).
- **Focus session mode**: deep-work blocks with automatic transitions; pause or extend them.
- **Clock Out**: tells you to stop working at your set time, with a personal message.
- Launch at login.

### 2.6 Stats
- **Streaks** for habit building.
- Progress tracking and charts.

### 2.7 Control
- Menu bar countdown to the next break.
- Keyboard shortcuts, Apple Shortcuts support.
- Adjust timer on the fly.

---

## 3. What we'll build

Trimmed on purpose: only features worth their build effort. Cuts and simplifications are listed in 3.2.

### 3.1 Feature list

| # | Feature | From | Notes |
|---|---|:-:|---|
| 1 | Menu bar timer: mug icon + countdown, rolling digits | Both | Live Status on/off, icon and text / text only, `19:42` or `20m` |
| 2 | Menu bar dropdown with quick actions | Both | |
| 3 | Break every N min of *active* screen time | Both | |
| 4 | Short + long breaks (every Nth is long) | Both | |
| 5 | Full-screen break overlay, **blurred wallpaper** | Both | Core look. Wallpaper blur only. |
| 6 | Break screen customization: background, messages | Both | |
| 7 | Built-in exercises (~10, separate short/long lists) | DeskRest | No routine editor |
| 8 | Enforcement modes: Casual / Balanced / Hardcore | LookAway | |
| 9 | Max snoozes per break (default 2) + **daily skip limit** (default 3, counts on-screen skips and "Skip next break") | LookAway | Emergency skips don't count |
| 10 | Double-Esc action, End Break early, hold until End Break, **emergency skip by typing "emergency"** | LookAway + ours | |
| 11 | Lock Mac on break start + Lock Screen button | LookAway | |
| 12 | Heads-up alert before break (Start now / +1m / +5m / +15m) | Both | One "N seconds before" setting; stays until the break |
| 13 | Cursor-following countdown pill | Both | |
| 14 | Overtime nudge, click to dismiss | LookAway | |
| 15 | Smart-pause alerts (small pill when pausing/resuming) | LookAway | Built with Smart Pause (Phase 7) |
| 16 | Hold off breaks while typing or dragging | LookAway | |
| 17 | Smart pause: meetings/calls (mic/camera), deep focus apps, macOS Focus mode | Both | Add Zoom, OBS, games etc. as deep focus apps. No video detection. |
| 18 | Idle detection + timer reset + "welcome back" heads-up | Both | |
| 19 | Posture & blink reminders as a DeskRest-style screen flash (screen darkens briefly, icon and "Watch your posture" appear, fades back). The LookAway bubble was tried and dropped | Both | DeskRest reference: `deskrest-settings-screenshots/flash_reminder*.png`, `deskrest-flash-reminder.mov` |
| 20 | Office / working hours | Both | |
| 21 | Planned breaks at fixed times | LookAway | |
| 22 | Clock Out (end-of-day stop) | DeskRest | |
| 23 | Stats: breaks taken/skipped today, weekly chart, streak | Both | |
| 24 | Sounds: one volume, toggles and a choice of 8 sounds for break start, break end and reminders | Both | Sounds from BreakTimer (GPL-3.0) and Stretchly |
| 27 | Visual style: native macOS (system colours, accent colour, Liquid Glass); leaf app icon | Ours | Replaced the earlier Catppuccin Mocha look and its planned Themes |
| 25 | Global shortcuts: Pause/Resume, Start break now, Snooze 5 min | Both | |
| 26 | Launch at login | Both | |

### 3.2 Cut or simplified

**Cut**
| Feature | Why |
|---|---|
| iPhone/iPad sync, mobile Live Activities | Mac only |
| Lock-screen break status | No official macOS way to do it. Fragile hacks. |
| Per-app & per-website screen time | macOS Screen Time already does it. Extra permission. |
| Video playback detection | The point is to make sure breaks happen |
| Screen recording/sharing detection | No reliable detection. Use deep focus apps instead. |
| Gaming detection | Use deep focus apps instead |
| Calendar-event pause | Not used. Mic detection covers calls. |
| Dictation apps list | Not used |
| Apple Shortcuts, AppleScript hooks, Focus Filters | Rarely used. Overlaps with Focus mode pause. |
| Focus sessions | Duplicates the break cycle |
| Custom routine editor | Built-in exercise list is enough |
| Live-screen blur | Needs Screen Recording permission. Wallpaper blur is the target look. |
| Screen Score + coloured rings | Simple stats instead |
| Auto-updates, language picker | Not needed for a personal app |

**Simplified**
| Was | Now |
|---|---|
| Advance skips/day, snoozes/day, snoozes/break | Max snoozes per break + one daily skip limit (includes advance skips) |
| Menu bar changes during a break | None: the break screen covers the menu bar anyway |
| 13 keyboard shortcuts | 3 |
| 3 volume sliders, 8 sound toggles | 1 volume, 2 toggles |
| Overtime nudge: shake to dismiss | Click to dismiss |
| Break reminder: "N min before" + "visible for N s" | One setting: appears N s before, stays until the break |
| Progressive blur on alert pills | Plain glass (may come back later) |
