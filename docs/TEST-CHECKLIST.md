# Canopy test checklist

Test the installed copy (`/Applications/Canopy.app`). Tick each box as you go and note anything odd in the margin. Sessions are grouped so one setup covers many checks; do them in order.

**Before you start:** note your current settings (or take screenshots of each settings page) so you can put them back at the end. Most breaks below are started from the menu bar with **Start break now**, so you don't have to wait.

---

## 1. Menu bar and first launch

- [ ] Menu bar shows the leaf and a countdown (`19:42`). Digits just change (no animation) and the text doesn't jiggle.
- [ ] Leaf is plain black or white (matches the other menu bar icons), in light and dark mode, with no line down its middle.
- [ ] App icon (Finder, Dock, About, Welcome): two see-through gold glass leaves on near-black, no line in the leaf; the back leaf shows through the front one.
- [ ] Menu lists: next break time, Pause, Start break now, Snooze ▸, Skip next break, Settings…, Quit Canopy.
- [ ] **Pause** → countdown stops, leaf dims, item becomes **Resume**. Resume → countdown continues from where it was.
- [ ] Leave the Mac untouched for longer than "pause after" idle (default 2 min) → leaf dims. Move the mouse → it brightens again.
- [ ] **Snooze ▸ 5 min** → countdown grows by 5 minutes.
- [ ] **Skip next break** → countdown restarts at the full interval.
- [ ] Settings › General › Menu bar: **Live Status** off → icon only. **Display: Text only** → no leaf. **Timer style: 20m** → `20m` instead of `19:42`. Put them back.
- [ ] Welcome window: in Terminal run `defaults delete com.jammyjellyfish.BreakReminder hasSeenWelcome`, then quit and reopen Canopy. The welcome window shows the gold leaf icon; Open Settings and Get Started both work. It doesn't show again on the next launch.

## 2. Settings window

- [ ] Opens titled **General**, with a Dock icon while open (gone when closed).
- [ ] Sidebar labels aren't cut off. Icon colours by group: grey (General, About), teal (Screen Breaks, Break Screen, Wellness), purple (Schedule, Smart Pause, Stats), red (Alerts, Sounds), orange (Keyboard Shortcuts).
- [ ] ‹ › buttons go back and forward through the pages you visited.
- [ ] Looks right in **light and dark** mode, and next to System Settings it feels like the same kind of window.
- [ ] System Settings › Appearance › accent colour **Blue**, then **Multicolor**: toggles and tints follow it (Multicolor → green). The Dock icon stays gold (it doesn't follow the accent).
- [ ] Every page has a **Preview** button where something can be shown (Alerts, Wellness, Clock Out).
- [ ] Change a setting, quit Canopy, reopen: the setting is kept.

## 3. Break screen (use Start break now; set Break duration to 60 s for time to look)

While a break is on screen, check:

- [ ] Fades in smoothly: a live blur first, then the blurred wallpaper and text.
- [ ] Big timer near the middle; digits rise and fade as they change, no bounce.
- [ ] Thin accent-coloured bar starts full and drains smoothly to empty (no jumps), message right under it.
- [ ] Clock and text don't touch the menu bar area, on every background (wallpaper, picture, gradient).
- [ ] Buttons at the bottom are Liquid Glass.
- [ ] Typing does nothing in the app behind (no beeps); ⌘Q doesn't quit Canopy.
- [ ] Type **emergency**: the letters light up in the footer as you type, and the break ends.
- [ ] **Lock** button locks the Mac. After unlocking, the break is still up and Esc still works.
- [ ] With a second display: both screens are covered. Plug or unplug one mid-break: still covered, same message.
- [ ] Break ends: everything fades out in reverse, nothing changes while fading.
- [ ] Every 4th break is long (or set Screen Breaks › Long breaks to "Every 2nd break" to see it sooner): longer timer, long-break exercise.

### Enforcement (Settings › Screen Breaks)

- [ ] **Casual:** Skip works right away.
- [ ] **Balanced:** Skip shows a ring that fills; Skip only works from halfway.
- [ ] **Hardcore:** no Skip, no snooze; typing "emergency" still works and the footer mentions it.
- [ ] **Snooze stack:** hover over Skip → +1 min and +5 min float up; clicking one ends the break and adds the time. After 2 snoozes (or your limit) they're gone.
- [ ] **Skips allowed per day:** set to 1, skip once → next break says **No skips left**.
- [ ] **Double escape action:** Skip / Snooze 5 minutes / Do nothing each do what they say. Holding Esc down doesn't count as a double press.
- [ ] **End Break early** on → End Break button appears in the last quarter.
- [ ] **Keep the break screen up until I press End Break** on → at the end it says the break's over and waits; text and buttons animate in.
- [ ] **Lock my Mac automatically when a break starts** on → the Mac locks at break start. Turn it back off.

### Break Screen page

- [ ] Background **Blurred wallpaper**, **Picture** (Choose… a photo), **Gradient**: each shows on the next break.
- [ ] Exercises on → short breaks show an eye/neck exercise, long breaks a get-up one. Turning one off means it doesn't come up.
- [ ] Exercises off → the Built-in lists switch to plain messages (5 short, 3 long), each with a switch. Turning one off means it doesn't come up. Turn exercises back on.
- [ ] **My short-break messages:** add one with a title and instructions → it shows up on short breaks only (try a few), instructions under the title. **My long-break messages:** same, long breaks only. Remove them.
- [ ] Your old custom messages (from before this update) appear in both lists.

## 4. Alerts and nudges (Settings › Alerts / Nudges)

Use each section's **Preview** first, then check the real thing by waiting for a break with the countdown set short.

- [ ] **Heads-up:** slides down from the menu bar with a small overshoot, counts down (digits roll and fade), has Start this break now and +1m / +5m / +15m. Each button works. No clock badge. The bar along the bottom (accent colour, same as the break screen bar) starts full and glides down to empty as the break arrives. Slides back up when it goes.
- [ ] **Pointer countdown:** follows the mouse, fades in and out, clicks go through it, text is white in dark mode (black in light), the number just changes (no animation).
- [ ] **Smart Pause alerts** and **Overtime nudge:** Preview shows each; overtime is dismissed by clicking.
- [ ] No colour on any pill: symbols sit on grey circles, overtime's minutes are plain text. Only the heads-up bar has colour (the accent). Check light and dark mode.
- [ ] **Position:** top left / center / right cards show your desktop picture; pills move to the chosen spot.
- [ ] Pills appear on the display the mouse is on.
- [ ] **Show alerts as: Notifications** → heads-up arrives as a macOS notification with Start Break Now and Snooze buttons (both work); the pointer countdown stays a pill. Switch back to Pills.

## 5. Smart Pause and stepping away (Settings › Smart Pause)

- [ ] **Meetings or calls:** join a call or open Photo Booth → countdown stops, leaf dims, menu says "Smart Pause · …", a pill says it paused. Close it → "Timer resumed".
- [ ] **Cooldown:** with 1 minute set, a break that would come right after Smart Pause ends waits until the cooldown is over.
- [ ] **Deep focus apps:** Add App… (e.g. Xcode), bring it to the front → paused. Remove it.
- [ ] **macOS Focus:** in Terminal run `open canopy://focus-on` → paused; `open canopy://focus-off` → resumes. (Open Shortcuts sets up the real automation.)
- [ ] **Typing hold:** keep typing when a break is due → it waits for a pause (at most 30 s).
- [ ] **Stop counting when I'm away for** (30 s): leave the mouse and keyboard alone that long → countdown stops.
- [ ] **Count as a break when I'm away for** (3 min): stay away that long → on return, a welcome back pill says it counted as a break and the countdown is full.
- [ ] Lock the screen or sleep the Mac for longer than that → same welcome back on return.

## 6. Wellness reminders (Settings › Wellness Reminders)

- [ ] Posture and blink **Preview**: every display darkens briefly with just the message (no icon), then fades. One reminder sound.
- [ ] Enable both with the shortest interval; they come on time while you work, not while you're away.
- [ ] Both due within a minute → only one flash.
- [ ] **Make reminders invisible in screen recordings:** start a screen recording (⇧⌘5), Preview → the flash isn't in the recording.
- [ ] **Keep reminders active during Smart Pause** and **Restart reminder timers after a break** do what they say.

## 7. Schedule (Settings › Schedule)

- [ ] **Office hours:** set today's hours to end a few minutes from now → after that, menu bar shows only the dimmed leaf and the menu says "Outside office hours". No breaks or reminders.
- [ ] **Planned break:** add one 2 minutes from now → break screen shows its name for its whole length. The regular countdown isn't affected.
- [ ] **Clock Out Preview:** every display shows "Time to clock out" with your message; text rises in. **Keep working** closes it; **Done for today** stops the timer (menu shows Start).

## 8. Sounds (Settings › Sounds)

- [ ] Each sound menu plays the sound when you pick it; ▶ plays it again.
- [ ] Volume slider plays a sample when you let go; quieter is quieter.
- [ ] **Reverie** is in every sound menu and plays.
- [ ] **Pitch down break end sound:** greyed out for Gong, Blip, Bloop, Ping, Sci-fi (they already have a lower end sound). Pick Crystal glass as the end sound, turn it on → ▶ plays it lower. Turn it off → normal.
- [ ] Break start / end sounds play on a real break; reminder sound on posture/blink flashes; alert sound on pills. Each toggle only silences its own sounds.

## 9. Keyboard shortcuts (Settings › Keyboard Shortcuts)

- [ ] Record **Pause or resume**, **Start break now**, **Snooze 5 minutes**. Each works from any app.
- [ ] The menu bar menu shows the shortcuts next to Pause and Start break now.

## 10. Stats (Settings › Stats)

- [ ] Today's taken / skipped / snoozed match what you did during this test. Numbers are readable in light and dark mode.
- [ ] 7-day chart: stacked bars of % skipped and % snoozed; hovering a day shows its numbers.
- [ ] Streak: 0 after today's skips; days you didn't use the Mac don't break it.
- [ ] **Clear History…** asks first; Cancel keeps everything. Clear History → all zeros, empty chart, still zeros after quitting and reopening. (Do this last.)

## 11. Accessibility

- [ ] **Reduce Motion** (System Settings › Accessibility › Display): pills, Clock Out and the break timer only fade, no sliding or rolling.
- [ ] **Reduce Transparency:** pills and break screen buttons are solid instead of glass; still readable.
- [ ] Turn both back off.

## 12. Startup and everyday use

- [ ] Settings › General › **Launch at login** on. Restart the Mac → Canopy is running, settings and stats are kept.
- [ ] Leave Canopy running for a normal work day: no crashes (nothing new in `~/Library/Logs/DiagnosticReports/Canopy-*`), Activity Monitor shows under ~1% CPU between breaks.

---

**When done:** put your settings back, and give Claude the unticked items and notes.
