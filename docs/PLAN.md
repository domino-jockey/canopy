# Plan: "Canopy", a native, glass, minimal redesign

## Context

The app works (Phases 1–15 done), but its look is borrowed: Catppuccin Mocha colours, an always-dark custom settings window, LookAway-style layouts. The user wants it to:
- feel native: use macOS Liquid Glass wherever it makes sense, and have a settings window that looks like a real macOS app;
- have its own identity: new name **Canopy** (was going to be Frond), with a leaf icon;
- be consistent and minimal, look different from other break apps, and use native features where possible.

Replaces the "Later: Themes" plan (Catppuccin palettes): native colours + light/dark make it unnecessary.
Updated with the "Not handled" list in `PROBLEMS.md` (October 2026).

## Design principles (the rules every screen follows)

1. **System first.** System colours (`.primary`, `.secondary`, window/control backgrounds), SF Pro, SF Symbols, standard controls. Follows light/dark mode. No hard-coded palette.
2. **Follow the system accent colour.** No brand colours in the app: tints, sidebar icons, the clock badge, the break screen glow and the leaf all use the accent colour. The app's own AccentColor (green) only shows when the system accent is Multicolor.
3. **Glass for things that float, never for content:** alert pills, heads-up, break-screen buttons, Clock Out buttons. One glass style each (`.regular`, `.regular.interactive()` for clickable), no tints.
4. **One shape scale:** capsules for buttons/pills, 12 pt corners for cards, circles for badges. One spacing scale (8/12/16/24).
5. **Signature, not decoration:** the leaf is the app icon and the menu bar glyph. Everything else stays plain.
6. **Typography:** SF Pro for all text; SF Mono for every number.
7. **Things move in, they don't pop.** Every floating window or view that appears gets a short spring/fade (respecting Reduce Motion).

## Icon (done)

- **History:** round 1 was a glass fern on a grid (Horizon floor picked). Then changed: ferns are hard to see.
- **Now:** one big leaf in the style of the `leaf.fill` symbol (Screen Breaks' sidebar icon) but our own drawing, since SF Symbols aren't allowed in app icons: wide rounded blade, curved vein cut out, curved stem. Liquid Glass, no shadow, on Icon Composer's dark background (near-black, a touch lighter at the top). No grid.
- **Colour:** Finder/Launchpad show a fixed green leaf (macOS can't tint an app's icon to the accent colour). Inside the app (Dock while Settings is open, About, Welcome, flash reminder) the icon is redrawn with the leaf in your accent colour, and redrawn when the accent changes. The menu bar leaf is the same shape, in the accent colour.
- Made by `design/make-icon.swift` (writes `design/icon-mockups/Canopy.icon`, `Canopy/Resources/AppIcon.icon`, the menu bar SVG and `design/icon-preview.png`).

## Stats graph (replaces daily progress)

Daily progress (Day dots) was **dropped** (October 2026). Instead, the bars on the existing 7-day graph show **% skipped + % snoozed** each day as a **stacked bar** (two colours), out of all break decisions that day (taken + skipped + snoozed).

**Streak:** days in a row with **no skips and no snoozes**. Days with no breaks at all (Mac not used) neither break nor extend it. The daily break goal setting goes away.

## Other changes from PROBLEMS.md

- **Sidebar:** wider by default. Icons are white SF Symbols on rounded squares **coloured by category like System Settings** (see `resources/settings_sidebar_macos.png`), not the accent gradient.
- **Wellness reminders: screen flash only.** Remove the bubble style and its settings (size, position, dim). Flash uses the new icon.
- **Animations:** alert pills, heads-up, cursor countdown, snooze stack, Clock Out and welcome back slide + fade in with a spring, and out the same way. (Pills currently only fade 0.25 s, which reads as "popping".) Reduce Motion → plain fade.
- **Break screen clock** touching the top edge with a picture background: fix layout so the clock respects the safe area / menu bar on every background.
- **New break screen layout:** big timer at the middle-top, a **thin** progress bar (accent colour, time passed) in the middle, the message right below it. No icon (not even for exercises), no current time. Skip buttons etc. below stay the same.
- **Smart Pause cooldown:** today it freezes the countdown for the cooldown time after every Smart Pause. Change it so the countdown keeps running and only a break that comes due within the cooldown waits until it's over.
- **Alerts/nudges:** setting to show them as normal macOS notifications instead (heads-up gets Start now / Snooze buttons; the cursor countdown stays a pill). Making them bigger isn't needed anymore: the sizing fix made the text fit. Position cards in settings: no accent tint, just wallpaper / black.
- **Menu bar icon:** plain black/white (template image), not coloured.
- **Preview buttons:** every one says "Preview" (wellness reminders didn't).
- **Idle detection:** add **30 seconds** and **1 minute** to the "pause when away" options (currently 2 min).
- **Sounds:** several choices per group (break start/end, reminders), taken from BreakTimer (GPL-3.0) and Stretchly (check its sound licences first), with ▶ preview. Credits updated.
- **Exercises:** add your own exercises with a title and instructions. No icons (the new break screen has none).
- ~~**General page:** live status and timer style~~: already there (Phase 3).

## Unchanged from the earlier plan

- **Settings window:** plain `NavigationSplitView`, system sidebar and selection, standard toolbar title; no forced dark. Native menu Pickers instead of `StopSlider`. Picture cards drawn like System Settings' Appearance picker.
- **Break screen:** blurred wallpaper (no tint), white vibrant text, accent countdown, glass buttons.
- **Pills & heads-up:** plain Liquid Glass, system text colours, LookAway's two-row heads-up layout.
- **Remove `Theme/Mocha.swift`:** every `Mocha.x` becomes a system colour or `.tint`.
- **SF Mono** helper (one `Font` extension) for every number.
- **Rename to Canopy:** `PRODUCT_NAME: Canopy`, keep bundle ID `com.jammyjellyfish.BreakReminder` (settings, stats, shortcuts carry over), user-visible text → "Canopy", URL scheme `canopy://`, docs + CLAUDE.md commands. After install, remove the old `/Applications/BreakReminder.app` (will confirm first).

## Steps

Order (October 2026): **bugs and features first, appearance after.** Don't get carried away with the look.

1. ✅ **Icon:** big leaf on dark grey, in the app (see "Icon" above). **To be redone in step 5** (it's the `leaf.fill` SF Symbol, which isn't allowed in app icons, and too small):
   - Our own drawing of **two leaves**, inspired by the user's screenshot (`resources/icon-references/two-leaves-screenshot.png`) (big front leaf with a curved vein cut out, smaller leaf behind). Drawn in code, no SVG needed.
   - Style like the macOS 27 icons the user downloaded (Obsidian, Steam, YouTube, Surfshark in `~/Downloads`): near-black background, one big coloured glass shape filling ~70–80%.
   - Two layers (back leaf, front leaf) so each gets its own glass. Preview image first, user checks.
   - Chosen: green leaves on black. First version made in step 5 (`design/icon-preview.png`); the user says it's off and will come back to it later. Ask what's off before changing it.
2. ✅ **Native foundation:** system accent colour everywhere, Mocha removed (pills, break screen and Clock Out got plain glass and system colours here too), settings window, gradient sidebar icons, duration menus. Waiting on the by-eye check.
3. ✅ **Bugs:** see the Bugs list in `PROBLEMS.md` (preview crash, typing crash, double flash, jumping alerts, "Untitled" title), plus the Smart Pause cooldown change.
4. ✅ **Feature changes** (checked by the user): flash-only wellness, idle 30 s / 1 min (new "pause when away" setting), sound choices, custom exercises (title + instructions), alerts as notifications option, stats graph (stacked % skipped + snoozed) and the no-skip streak.
5. **Appearance:** animations, break screen clock fix, new break screen layout, sidebar, position cards, menu bar icon, Preview labels, new app icon.
6. ✅ **Rename to Canopy**, reinstall, docs. Project/target/folders renamed too in "Organize source".

## After the redesign (your "theorized next steps")

1. ✅ **Organize source** into a standard layout (e.g. `App/`, `Features/<Feature>/`, `Core/` for the timer logic, `Resources/`), like other open-source Mac apps.
2. **Optimize:** measure CPU/memory with Instruments, use native APIs where possible. Baseline (Activity Monitor): ~0.3% of a core idle, ~8% during a flash reminder, **25–50% during breaks** (the main target).
3. **Clean out** everything not needed: unused code, outdated docs, Xcode build artifacts. Keep the bare minimum to come back later with Claude Code.
4. **Test everything:** a printable `docs/TEST-CHECKLIST.md` (you'll export it to PDF), grouped so related checks happen together ("while the break screen is up, also check…").
5. **Linux friend:** a short `docs/ARCHITECTURE.md` explaining the parts, which logic is portable (scheduler, wellness timer, stats, schedule rules: plain Swift, no Mac APIs) and which parts are Mac-only and what the Linux equivalent would be. Plus a licence note (BreakTimer sounds are GPL-3.0).

## Verification

- `xcodebuild test …` green after each step.
- Off-screen renders of every settings page, break screen, pills, in light and dark.
- By eye: settings window next to System Settings; light/dark; system accent Multicolor vs blue; Reduce Transparency and Reduce Motion.
- Installed `/Applications/Canopy.app` launches and keeps old settings and stats.
