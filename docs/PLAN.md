# Plan

The Canopy redesign is done (see `PROGRESS.md`). This file keeps the design rules every screen follows and what's left to do.

## Design principles (the rules every screen follows)

1. **System first.** System colours (`.primary`, `.secondary`, window/control backgrounds), SF Pro, SF Symbols, standard controls. Follows light/dark mode. No hard-coded palette.
2. **Follow the system accent colour.** No brand colours in the app. The app's own AccentColor (green) only shows when the system accent is Multicolor. Exceptions the user asked for: the menu bar leaf is plain black/white, sidebar icons are coloured by group like System Settings.
3. **Glass for things that float, never for content:** alert pills, heads-up, break-screen buttons, Clock Out buttons. One glass style each (`.regular`, `.regular.interactive()` for clickable), no tints.
4. **One shape scale:** capsules for buttons/pills, 12 pt corners for cards, circles for badges. One spacing scale (8/12/16/24).
5. **Signature, not decoration:** the leaf is the app icon and the menu bar glyph. Everything else stays plain.
6. **Typography:** SF Pro for all text; SF Mono for every number.
7. **Things move in, they don't pop.** Every floating window or view that appears gets a short spring/fade (plain fade with Reduce Motion).

## Next (user's October 2026 list)

1. ✅ **Phase A, small fixes:** flash reminder without the icon; separate sound toggles and pickers for wellness reminders and alerts; menu bar leaf dims while idle (stepped away); Clear History in Stats; Reverie sound added (Stretchly, no licence listed: personal use only).
   - ⏸ **Shortcuts with `fn`:** on hold. KeyboardShortcuts strips `fn` on purpose and Carbon global hotkeys can't use it; supporting it means replacing the library with our own key listener (needs Input Monitoring permission). Ask the user what they need.
2. ✅ **Phase B, alerts and animation:** heads-up loses the clock badge and gets a bar underneath that drains from full to empty; every rolling number uses the break timer's fade roll (no blur), menu bar included.
3. **Phase C, messages:** custom messages split into a Short-break and a Long-break list; built-in messages and exercises listed in Settings, each with an on/off switch.
4. **Phase D, icon (last):** more transparent leaf, no line down its middle, more macOS-like overall. Ask the user for references first.

## Done before
- ✅ Clean out, printable test checklist, `ARCHITECTURE.md` for the Linux friend.

## Later

- **App icon:** the user says the current two-leaf icon is "off". Ask what's off before changing it. Style references: `resources/icon-references/two-leaves-screenshot.png`, and macOS 27 icons (near-black background, one big coloured glass shape filling ~70–80%). SF Symbols aren't allowed in app icons, so the leaves are our own drawing (`design/make-icon.swift`).

## Verification (for any change)

- `xcodebuild test …` green.
- Install to `/Applications`; the user checks by eye (light/dark, accent Multicolor vs blue, Reduce Transparency and Reduce Motion where relevant).
- The installed app keeps old settings and stats.
