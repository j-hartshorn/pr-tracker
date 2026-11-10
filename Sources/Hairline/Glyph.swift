import AppKit
import SwiftUI

/// The square status mark. The more of it is filled, the more urgent the message.
public struct Glyph: View {
    public enum Fill: Sendable {
        case empty, nested, half, solid
    }

    private let fill: Fill
    private let color: Color
    private let size: CGFloat

    public init(_ fill: Fill, color: Color = Palette.ink, size: CGFloat = 16) {
        self.fill = fill
        self.color = color
        self.size = size
    }

    public var body: some View {
        Canvas { context, canvasSize in
            let resolved = color.resolve(in: context.environment).cgColor
            context.withCGContext { cgContext in
                Self.draw(fill, color: resolved, in: CGRect(origin: .zero, size: canvasSize), context: cgContext)
            }
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }

    /// The glyph as an image, for places that cannot host a view, such as the menu bar. It is drawn on demand, so its colour follows the appearance of wherever it is shown.
    public static func image(_ fill: Fill, color: Color = Palette.ink, size: CGFloat = 16) -> NSImage {
        let nsColor = NSColor(color)
        return NSImage(size: CGSize(width: size, height: size), flipped: true) { rect in
            guard let context = NSGraphicsContext.current?.cgContext else { return false }
            draw(fill, color: nsColor.cgColor, in: rect, context: context)
            return true
        }
    }

    /// Geometry from the design system's 20-unit grid. Expects a top-left origin.
    private static func draw(_ fill: Fill, color: CGColor, in rect: CGRect, context: CGContext) {
        let unit = rect.width / 20
        let outer = rect.insetBy(dx: 2 * unit, dy: 2 * unit)
        context.setFillColor(color)
        context.setStrokeColor(color)
        context.setLineWidth(Stroke.mark)
        switch fill {
        case .solid:
            context.fill(outer)
            return
        case .nested:
            context.fill(rect.insetBy(dx: 5.5 * unit, dy: 5.5 * unit))
        case .half:
            context.move(to: CGPoint(x: outer.minX, y: outer.maxY))
            context.addLine(to: CGPoint(x: outer.maxX, y: outer.minY))
            context.addLine(to: CGPoint(x: outer.maxX, y: outer.maxY))
            context.closePath()
            context.fillPath()
        case .empty:
            break
        }
        context.stroke(outer.insetBy(dx: Stroke.mark / 2, dy: Stroke.mark / 2))
    }
}
