# Plan

The Canopy redesign is done (see `PROGRESS.md`). This file keeps the design rules every screen follows and what's left to do.

## Design principles (the rules every screen follows)

1. **System first.** System colours (`.primary`, `.secondary`, window/control backgrounds), SF Pro, SF Symbols, standard controls. Follows light/dark mode. No hard-coded palette.
2. **Follow the system accent colour.** No brand colours in the app. The app's own AccentColor (green) only shows when the system accent is Multicolor. Exceptions the user asked for: the app icon's leaves are a fixed gold gradient everywhere (Dock included), the menu bar leaf is plain black/white, alerts and nudges are plain greys (no colour, not even the accent) except the heads-up bar, which uses the accent like the break screen bar, sidebar icons are coloured by group like System Settings.
3. **Glass for things that float, never for content:** alert pills, heads-up, break-screen buttons, Clock Out buttons. One glass style each (`.regular`, `.regular.interactive()` for clickable), no tints.
4. **One shape scale:** capsules for buttons/pills, 12 pt corners for cards, circles for badges. One spacing scale (8/12/16/24).
5. **Signature, not decoration:** the leaf is the app icon and the menu bar glyph. Everything else stays plain.
6. **Typography:** SF Pro for all text; SF Mono for every number.
7. **Things move in, they don't pop.** Every floating window or view that appears gets a short spring/fade (plain fade with Reduce Motion).

## Next (user's October 2026 list)

1. ✅ **Phase A, small fixes:** flash reminder without the icon; separate sound toggles and pickers for wellness reminders and alerts; menu bar leaf dims while idle (stepped away); Clear History in Stats; Reverie sound added (Stretchly, no licence listed: personal use only).
   - ✗ **Shortcuts with `fn`:** dropped by the user (KeyboardShortcuts strips `fn` on purpose; Carbon global hotkeys can't use it).
   - **Follow-ups:** "Pitch down break end sound" switch (only for sounds without their own end file); menu bar and pointer countdown numbers back to plain, not animated.
2. ✅ **Phase B, alerts and animation:** heads-up loses the clock badge and gets a bar underneath that drains from full to empty; every rolling number uses the break timer's fade roll (no blur). Later the user asked for the menu bar and pointer countdown not to animate at all.
3. ✅ **Phase C, messages:** custom messages split into a Short-break and a Long-break list; built-in messages and exercises listed in Settings, each with an on/off switch.
4. ✅ **Phase D, icon:** mockup A picked: the same two leaves, see-through glass, no vein, gold gradient (purple was too close to the user's Obsidian). The accent-coloured in-app redraw (`AccentIcon`) is gone; the real icon shows everywhere.

## Done before
- ✅ Clean out, printable test checklist, `ARCHITECTURE.md` for the Linux friend.

## Verification (for any change)

- `xcodebuild test …` green.
- Install to `/Applications`; the user checks by eye (light/dark, accent Multicolor vs blue, Reduce Transparency and Reduce Motion where relevant).
- The installed app keeps old settings and stats.
