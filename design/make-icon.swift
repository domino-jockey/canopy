// Draws the Canopy icon: the leaf.fill SF Symbol as a glass layer on Icon Composer's dark background.
// Usage, from the project root: swift design/make-icon.swift
// Writes design/icon-mockups/Canopy.icon and copies it to BreakReminder/AppIcon.icon.
// Note: Apple's SF Symbols licence doesn't allow symbols in app icons. Fine on this Mac; replace it before sharing the app.
import AppKit

let size = 1024
let dir = "design/icon-mockups/Canopy.icon"
let fm = FileManager.default
try? fm.removeItem(atPath: "design/icon-mockups")
try! fm.createDirectory(atPath: dir + "/Assets", withIntermediateDirectories: true)

// The symbol, about 60% of the icon wide, centred.
let symbol = NSImage(systemSymbolName: "leaf.fill", accessibilityDescription: nil)!
    .withSymbolConfiguration(.init(pointSize: 470, weight: .regular))!
let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: size, pixelsHigh: size, bitsPerSample: 8,
                           samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB,
                           bytesPerRow: 0, bitsPerPixel: 0)!
NSGraphicsContext.saveGraphicsState()
let context = NSGraphicsContext(bitmapImageRep: rep)!
NSGraphicsContext.current = context
let s = symbol.size
symbol.draw(in: NSRect(x: (CGFloat(size) - s.width) / 2, y: (CGFloat(size) - s.height) / 2, width: s.width, height: s.height))
// Fill the symbol's shape with green, lighter at the top right (fixed colour for Finder;
// inside the app the leaf follows the accent colour, see AccentIcon).
context.compositingOperation = .sourceIn
NSGradient(starting: NSColor(srgbRed: 0.18, green: 0.72, blue: 0.31, alpha: 1),
           ending: NSColor(srgbRed: 0.36, green: 0.88, blue: 0.48, alpha: 1))!
    .draw(in: NSRect(x: 0, y: 0, width: size, height: size), angle: 45)
NSGraphicsContext.restoreGraphicsState()
try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: dir + "/Assets/leaf.png"))

let json = """
{
  "fill" : {
    "linear-gradient" : [
      "srgb:0.13300,0.13300,0.13300,1.00000",
      "srgb:0.06700,0.06700,0.06700,1.00000"
    ]
  },
  "groups" : [
    {
      "layers" : [
        {
          "glass" : true,
          "image-name" : "leaf.png",
          "name" : "leaf"
        }
      ],
      "name" : "Leaf",
      "shadow" : {
        "kind" : "none",
        "opacity" : 0
      },
      "specular" : true,
      "translucency" : {
        "enabled" : true,
        "value" : 0.3
      }
    }
  ],
  "supported-platforms" : {
    "squares" : [
      "macOS"
    ]
  }
}

"""
try! json.write(toFile: dir + "/icon.json", atomically: true, encoding: .utf8)
try? fm.removeItem(atPath: "BreakReminder/AppIcon.icon")
try! fm.copyItem(atPath: dir, toPath: "BreakReminder/AppIcon.icon")
print("wrote", dir, "and BreakReminder/AppIcon.icon")
