// Draws the app icon: two leaves (a big front leaf, a smaller one behind it), each its own see-through
// Liquid Glass layer, on Icon Composer's dark background. The back leaf shows through where they overlap. Our own drawing (SF Symbols aren't
// allowed in app icons). Also writes the menu bar glyph from the same shapes.
// Usage, from the project root: swift design/make-icon.swift
// Writes design/icon-mockups/Canopy.icon, copies it to Canopy/Resources/AppIcon.icon, and writes
// Canopy/Resources/Assets.xcassets/MenuBarIcon.imageset/menubar-leaf.svg. Then renders design/icon-preview.png.
import Foundation

// Shapes on a 1024 canvas. Leaves grow from a shared base at the bottom left.
let front = "M215,830 C150,560 310,250 715,190 C780,520 570,810 215,830 Z"
let back = "M255,840 C450,610 650,530 830,570 C760,770 530,870 255,840 Z"

func svg(_ body: String) -> String {
    """
    <svg xmlns="http://www.w3.org/2000/svg" width="1024" height="1024" viewBox="0 0 1024 1024">
    \(body)
    </svg>
    """
}

func gradient(_ id: String, _ top: String, _ bottom: String) -> String {
    """
    <defs><linearGradient id="\(id)" x1="0" y1="0" x2="0" y2="1">
    <stop offset="0" stop-color="\(top)"/><stop offset="1" stop-color="\(bottom)"/></linearGradient></defs>
    """
}

let fm = FileManager.default
let dir = "design/icon-mockups/Canopy.icon"
try? fm.removeItem(atPath: "design/icon-mockups")
try! fm.createDirectory(atPath: dir + "/Assets", withIntermediateDirectories: true)

try! svg(gradient("g", "#FFE36B", "#E8A100") + "<path fill=\"url(#g)\" d=\"\(front)\"/>")
    .write(toFile: dir + "/Assets/front-leaf.svg", atomically: true, encoding: .utf8)
try! svg(gradient("g", "#F5C633", "#B87400") + "<path fill=\"url(#g)\" d=\"\(back)\"/>")
    .write(toFile: dir + "/Assets/back-leaf.svg", atomically: true, encoding: .utf8)

// The first group is drawn in front.
func group(_ name: String, _ image: String, translucency: Double) -> String {
    """
        {
          "layers" : [ { "glass" : true, "image-name" : "\(image)", "name" : "\(name)" } ],
          "name" : "\(name)",
          "shadow" : { "kind" : "neutral", "opacity" : 0.5 },
          "specular" : true,
          "translucency" : { "enabled" : true, "value" : \(translucency) }
        }
    """
}
let json = """
{
  "fill" : {
    "linear-gradient" : [
      "srgb:0.13300,0.13300,0.13300,1.00000",
      "srgb:0.06700,0.06700,0.06700,1.00000"
    ]
  },
  "groups" : [
\(group("Front leaf", "front-leaf.svg", translucency: 0.55)),
\(group("Back leaf", "back-leaf.svg", translucency: 0.6))
  ],
  "supported-platforms" : { "squares" : [ "macOS" ] }
}

"""
try! json.write(toFile: dir + "/icon.json", atomically: true, encoding: .utf8)
try? fm.removeItem(atPath: "Canopy/Resources/AppIcon.icon")
try! fm.copyItem(atPath: dir, toPath: "Canopy/Resources/AppIcon.icon")

// Menu bar glyph: both leaves in one colour (a template image, so macOS colours it). The back leaf is
// trimmed where the front one covers it, with a small gap so the two read as separate leaves.
let menuBar = """
<svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="130 160 740 700">
  <!-- The app icon's leaves in one colour. Made by design/make-icon.swift. -->
  <defs><mask id="m"><rect x="0" y="0" width="1024" height="1024" fill="#fff"/>
    <path d="\(front)" fill="#000" stroke="#000" stroke-width="44"/></mask></defs>
  <path d="\(back)" fill="#000" mask="url(#m)"/>
  <path d="\(front)" fill="#000"/>
</svg>

"""
try! menuBar.write(toFile: "Canopy/Resources/Assets.xcassets/MenuBarIcon.imageset/menubar-leaf.svg", atomically: true, encoding: .utf8)

// Preview, rendered by Icon Composer's command-line tool.
let preview = Process()
preview.executableURL = URL(fileURLWithPath: "/Applications/Xcode.app/Contents/Applications/Icon Composer.app/Contents/Executables/ictool")
preview.arguments = [dir, "--export-image", "--output-file", "design/icon-preview.png", "--platform", "macOS",
                     "--rendition", "Default", "--width", "512", "--height", "512", "--scale", "2"]
try! preview.run()
preview.waitUntilExit()
print("wrote", dir, "Canopy/Resources/AppIcon.icon, the menu bar SVG and design/icon-preview.png")
