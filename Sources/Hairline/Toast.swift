import SwiftUI

/// A one-line confirmation after an action: the success glyph and what happened.
public struct Toast: View {
    private let message: String

    public init(_ message: String) {
        self.message = message
    }

    public var body: some View {
        HStack(spacing: 12) {
            Glyph(.nested)
            Text(message).textStyle(.control).foregroundStyle(Palette.ink).lineLimit(1)
        }
        .padding(.vertical, 14)
        .padding(.horizontal, Space.s3)
        .background(Palette.bg)
        .border(Palette.ink, width: Stroke.hair)
    }
}
