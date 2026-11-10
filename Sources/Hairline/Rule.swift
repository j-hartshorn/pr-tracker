import SwiftUI

/// A hairline divider. Lines make structure here, not fills or shadows.
public struct Rule: View {
    private let axis: Axis

    public init(_ axis: Axis = .horizontal) {
        self.axis = axis
    }

    public var body: some View {
        Rectangle()
            .fill(Palette.line)
            .frame(width: axis == .vertical ? Stroke.hair : nil, height: axis == .horizontal ? Stroke.hair : nil)
    }
}
