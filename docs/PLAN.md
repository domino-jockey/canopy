# Plan

The Canopy redesign is done (see `PROGRESS.md`). This file keeps the design rules every screen follows and what's left to do.

## Design principles (the rules every screen follows)

1. **System first.** System colours (`.primary`, `.secondary`, window/control backgrounds), SF Pro, SF Symbols, standard controls. Follows light/dark mode. No hard-coded palette.
2. **Follow the system accent colour.** No brand colours in the app. The app's own AccentColor (green) only shows when the system accent is Multicolor. Exceptions the user asked for: the menu bar leaf is plain black/white, the heads-up clock badge is grey, sidebar icons are coloured by group like System Settings.
3. **Glass for things that float, never for content:** alert pills, heads-up, break-screen buttons, Clock Out buttons. One glass style each (`.regular`, `.regular.interactive()` for clickable), no tints.
4. **One shape scale:** capsules for buttons/pills, 12 pt corners for cards, circles for badges. One spacing scale (8/12/16/24).
5. **Signature, not decoration:** the leaf is the app icon and the menu bar glyph. Everything else stays plain.
6. **Typography:** SF Pro for all text; SF Mono for every number.
7. **Things move in, they don't pop.** Every floating window or view that appears gets a short spring/fade (plain fade with Reduce Motion).

## Next

1. ✅ **Clean out** unused code, outdated docs and build leftovers.
2. ✅ **Test everything:** a printable `docs/TEST-CHECKLIST.md` (the user will export it to PDF), grouped so related checks happen together ("while the break screen is up, also check…").
3. ✅ **Linux friend:** a short `docs/ARCHITECTURE.md` explaining the parts, which logic is portable (scheduler, wellness timer, stats, schedule rules: plain Swift, no Mac APIs) and which parts are Mac-only and what the Linux equivalent would be. Plus a licence note (BreakTimer sounds are GPL-3.0).

## Later

- **App icon:** the user says the current two-leaf icon is "off". Ask what's off before changing it. Style references: `resources/icon-references/two-leaves-screenshot.png`, and macOS 27 icons (near-black background, one big coloured glass shape filling ~70–80%). SF Symbols aren't allowed in app icons, so the leaves are our own drawing (`design/make-icon.swift`).

## Verification (for any change)

- `xcodebuild test …` green.
- Install to `/Applications`; the user checks by eye (light/dark, accent Multicolor vs blue, Reduce Transparency and Reduce Motion where relevant).
- The installed app keeps old settings and stats.
