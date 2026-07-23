#!/usr/bin/env swift
//
// Draws AppIcon.icns. Run via Scripts/build.sh; there is no design asset to keep
// in sync, the icon is generated from these few shapes.
//
import AppKit
import Foundation

func drawIcon(size: CGFloat) -> NSImage {
    let image = NSImage(size: NSSize(width: size, height: size))
    image.lockFocus()

    let s = size / 1024   // everything below is authored at 1024pt

    // Rounded-rect background, macOS "squircle"-ish.
    let background = NSBezierPath(
        roundedRect: NSRect(x: 84 * s, y: 84 * s, width: 856 * s, height: 856 * s),
        xRadius: 190 * s,
        yRadius: 190 * s
    )
    let gradient = NSGradient(
        colors: [NSColor(red: 0.94, green: 0.32, blue: 0.28, alpha: 1),
                 NSColor(red: 0.78, green: 0.15, blue: 0.18, alpha: 1)]
    )
    gradient?.draw(in: background, angle: -90)

    // Dial ring.
    let ringRect = NSRect(x: 292 * s, y: 268 * s, width: 440 * s, height: 440 * s)
    NSColor(white: 1, alpha: 0.22).setStroke()
    let ring = NSBezierPath(ovalIn: ringRect)
    ring.lineWidth = 44 * s
    ring.stroke()

    // Elapsed arc — three quarters, so the icon reads as "a timer running".
    let center = NSPoint(x: ringRect.midX, y: ringRect.midY)
    let arc = NSBezierPath()
    arc.appendArc(withCenter: center, radius: ringRect.width / 2, startAngle: 90, endAngle: -180, clockwise: true)
    arc.lineWidth = 44 * s
    arc.lineCapStyle = .round
    NSColor.white.setStroke()
    arc.stroke()

    // Stem.
    let stem = NSBezierPath(
        roundedRect: NSRect(x: center.x - 26 * s, y: ringRect.maxY - 6 * s, width: 52 * s, height: 96 * s),
        xRadius: 26 * s, yRadius: 26 * s
    )
    NSColor(red: 0.29, green: 0.6, blue: 0.31, alpha: 1).setFill()
    stem.fill()

    image.unlockFocus()
    return image
}

let outputDir = CommandLine.arguments.count > 1
    ? URL(fileURLWithPath: CommandLine.arguments[1])
    : URL(fileURLWithPath: ".")

let iconset = outputDir.appendingPathComponent("AppIcon.iconset")
try? FileManager.default.removeItem(at: iconset)
try FileManager.default.createDirectory(at: iconset, withIntermediateDirectories: true)

// The sizes `iconutil` expects, each in 1x and 2x.
for base in [16, 32, 128, 256, 512] {
    for scale in [1, 2] {
        let pixels = CGFloat(base * scale)
        let image = drawIcon(size: pixels)
        guard let tiff = image.tiffRepresentation,
              let rep = NSBitmapImageRep(data: tiff),
              let png = rep.representation(using: .png, properties: [:])
        else { continue }
        let suffix = scale == 1 ? "" : "@2x"
        try png.write(to: iconset.appendingPathComponent("icon_\(base)x\(base)\(suffix).png"))
    }
}

print("Wrote \(iconset.path)")
