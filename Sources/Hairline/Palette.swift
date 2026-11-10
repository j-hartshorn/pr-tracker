import AppKit
import SwiftUI

/// Hairline colour tokens. Each follows the system appearance: Paper in light, Dark in dark.
public enum Palette {
    public static let bg = token(paper: 0xf4f5f6, dark: 0x15181c)
    public static let surface = token(paper: 0xeceef0, dark: 0x1c2026)
    public static let ink = token(paper: 0x1e2329, dark: 0xe4e7ea)
    public static let inkMuted = token(paper: 0x58606a, dark: 0x9aa2ac)
    public static let line = token(paper: 0xcdd1d6, dark: 0x2c3238)
    public static let lineStrong = token(paper: 0x868e98, dark: 0x6a727c)
    public static let accent = token(paper: 0x2b44c8, dark: 0x8c9cff)
    public static let accentInk = token(paper: 0xffffff, dark: 0x15181c)
    public static let focus = accent
    public static let statusFailing = token(paper: 0xa8261d, dark: 0xf2877d)
    public static let statusAttention = token(paper: 0x7d5600, dark: 0xd9ac55)
    public static let statusReady = token(paper: 0x1f6a3c, dark: 0x7ccf97)

    private static func token(paper: UInt32, dark: UInt32) -> Color {
        Color(nsColor: NSColor(name: nil) { appearance in
            NSColor(hex: appearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua ? dark : paper)
        })
    }
}

private extension NSColor {
    convenience init(hex: UInt32) {
        self.init(
            srgbRed: CGFloat((hex >> 16) & 0xff) / 255,
            green: CGFloat((hex >> 8) & 0xff) / 255,
            blue: CGFloat(hex & 0xff) / 255,
            alpha: 1
        )
    }
}
