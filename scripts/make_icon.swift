// Renders the "Cycle" logo: AppIcon.icns for the Mac app and the web remote's home-screen icon.
// Usage (from the repo root): swift scripts/make_icon.swift

import SwiftUI
import AppKit

let clay  = Color(red: 0xD9 / 255, green: 0x77 / 255, blue: 0x57 / 255)
let oat   = Color(red: 0xE3 / 255, green: 0xDA / 255, blue: 0xCC / 255)
let ivory = Color(red: 0xFA / 255, green: 0xF9 / 255, blue: 0xF5 / 255)

/// Four arcs, one per session in a round: three done, one to go.
/// Drawn on a 100-unit grid scaled to the view's width.
struct CycleMark: View {
    var lineWidth: CGFloat

    var body: some View {
        GeometryReader { geo in
            let unit = geo.size.width / 100
            ZStack {
                ForEach(0..<4, id: \.self) { i in
                    Circle()
                        .trim(from: Double(i) * 0.25 + 15.0 / 360, to: Double(i + 1) * 0.25 - 15.0 / 360)
                        .stroke(i < 3 ? clay : oat, style: StrokeStyle(lineWidth: lineWidth * unit, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .frame(width: 52 * unit, height: 52 * unit)
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
    }
}

/// macOS icon grid: an 824-point rounded square centred on a 1024-point canvas.
struct MacIcon: View {
    var lineWidth: CGFloat

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: 185, style: .continuous)
        ZStack {
            shape
                .fill(ivory)
                .overlay(shape.strokeBorder(Color.black.opacity(0.06), lineWidth: 2))
                .shadow(color: .black.opacity(0.18), radius: 12, y: 8)
            CycleMark(lineWidth: lineWidth)
        }
        .frame(width: 824, height: 824)
        .frame(width: 1024, height: 1024)
    }
}

/// Full-bleed square; iOS rounds the corners itself.
struct TouchIcon: View {
    var body: some View {
        ZStack {
            ivory
            CycleMark(lineWidth: 9)
        }
        .frame(width: 180, height: 180)
    }
}

@MainActor
func writePNG<V: View>(_ view: V, scale: CGFloat, to url: URL) throws {
    let renderer = ImageRenderer(content: view)
    renderer.scale = scale
    guard let image = renderer.cgImage,
          let data = NSBitmapImageRep(cgImage: image).representation(using: .png, properties: [:]) else {
        throw CocoaError(.fileWriteUnknown)
    }
    try data.write(to: url)
}

let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let iconset = FileManager.default.temporaryDirectory.appendingPathComponent("AppIcon.iconset")
try? FileManager.default.removeItem(at: iconset)
try FileManager.default.createDirectory(at: iconset, withIntermediateDirectories: true)

try MainActor.assumeIsolated {
    for points in [16, 32, 128, 256, 512] {
        for multiplier in [1, 2] {
            let pixels = points * multiplier
            // Thicker arcs at small sizes so the gaps stay readable.
            let lineWidth: CGFloat = pixels <= 32 ? 12 : pixels <= 64 ? 10 : 9
            let name = multiplier == 1 ? "icon_\(points)x\(points).png" : "icon_\(points)x\(points)@2x.png"
            try writePNG(MacIcon(lineWidth: lineWidth), scale: CGFloat(pixels) / 1024,
                         to: iconset.appendingPathComponent(name))
        }
    }
    try writePNG(TouchIcon(), scale: 1, to: root.appendingPathComponent("web/app/apple-icon.png"))
}

let iconutil = Process()
iconutil.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
iconutil.arguments = ["-c", "icns", iconset.path, "-o", root.appendingPathComponent("AppIcon.icns").path]
try iconutil.run()
iconutil.waitUntilExit()
print(iconutil.terminationStatus == 0 ? "Wrote AppIcon.icns and web/app/apple-icon.png" : "iconutil failed")
