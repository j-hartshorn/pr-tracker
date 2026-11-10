import SwiftUI

/// The app icon: the square mark with three bars, on the tile macOS gives every icon.
public struct AppIcon: View {
    private let bars: [Color]
    private let size: CGFloat

    /// The bars take these colours from the top. A bar with no colour is `lineStrong`.
    public init(bars: [Color], size: CGFloat) {
        self.bars = bars
        self.size = size
    }

    public var body: some View {
        Canvas { context, canvasSize in
            // Geometry from the design system's 1024-unit grid.
            var context = context
            context.scaleBy(x: canvasSize.width / 1024, y: canvasSize.height / 1024)
            let tile = Path(roundedRect: CGRect(x: 100, y: 100, width: 824, height: 824), cornerRadius: 185, style: .continuous)
            context.fill(tile, with: .color(Palette.bg))
            context.stroke(Path(CGRect(x: 294, y: 294, width: 436, height: 436)), with: .color(Palette.ink), lineWidth: 44)
            for (index, y) in [381, 490, 599].enumerated() {
                let color = index < bars.count ? bars[index] : Palette.lineStrong
                context.fill(Path(CGRect(x: 381, y: y, width: 262, height: 44)), with: .color(color))
            }
        }
        .frame(width: size, height: size)
    }
}
