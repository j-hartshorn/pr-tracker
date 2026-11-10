import SwiftUI

/// An in-page message in a hairline box. The glyph shows urgency, and the text must say what happened and what to do.
public struct AlertBox: View {
    public enum Level: Sendable {
        case info, success, warning, error
    }

    private let level: Level
    private let title: String
    private let detail: String

    public init(_ level: Level, title: String, detail: String) {
        self.level = level
        self.title = title
        self.detail = detail
    }

    public var body: some View {
        HStack(alignment: .top, spacing: Space.s3) {
            Glyph(fill).padding(.top, 2)
            VStack(alignment: .leading, spacing: Space.s1) {
                Text(title).textStyle(.controlStrong).foregroundStyle(Palette.ink)
                Text(detail).textStyle(.control).foregroundStyle(Palette.inkMuted).fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.vertical, Space.s3)
        .padding(.horizontal, Space.s4)
        .frame(maxWidth: 560, alignment: .leading)
        .border(level == .error ? Palette.ink : Palette.lineStrong, width: Stroke.hair)
    }

    private var fill: Glyph.Fill {
        switch level {
        case .info: .empty
        case .success: .nested
        case .warning: .half
        case .error: .solid
        }
    }
}
