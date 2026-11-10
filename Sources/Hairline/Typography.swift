import CoreText
import SwiftUI

/// Hairline type styles. Prose is Iosevka Aile, and code, data and labels are Iosevka.
public struct TextStyle: Sendable {
    var fontName: String
    var size: CGFloat
    var lineHeight: CGFloat

    public static let display = TextStyle(fontName: "Iosevka-Aile-Light", size: 48, lineHeight: 52)
    public static let heading = TextStyle(fontName: "Iosevka-Aile", size: 24, lineHeight: 32)
    public static let subheading = TextStyle(fontName: "Iosevka-Aile-Semibold", size: 18, lineHeight: 26)
    public static let body = TextStyle(fontName: "Iosevka-Aile", size: 16, lineHeight: 26)
    /// Buttons, navigation and other interface text.
    public static let control = TextStyle(fontName: "Iosevka-Aile", size: 14, lineHeight: 20)
    public static let controlStrong = TextStyle(fontName: "Iosevka-Aile-Semibold", size: 14, lineHeight: 20)
    public static let small = TextStyle(fontName: "Iosevka-Aile", size: 13, lineHeight: 20)
    public static let code = TextStyle(fontName: "Iosevka", size: 14, lineHeight: 22)
    public static let data = TextStyle(fontName: "Iosevka", size: 14, lineHeight: 20)
    public static let label = TextStyle(fontName: "Iosevka", size: 12, lineHeight: 16)
}

extension View {
    public func textStyle(_ style: TextStyle) -> some View {
        font(.custom(style.fontName, fixedSize: style.size)).lineHeight(.exact(points: style.lineHeight))
    }
}

public enum Fonts {
    /// Registers every font file in `directory` for this process. Text falls back to the system font if this is not called.
    public static func register(in directory: URL) {
        let files = (try? FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)) ?? []
        CTFontManagerRegisterFontURLs(files.filter { $0.pathExtension == "woff2" } as CFArray, .process, true, nil)
    }
}
