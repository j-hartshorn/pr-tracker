import SwiftUI

public struct HairlineCheckboxStyle: ToggleStyle {
    public func makeBody(configuration: Configuration) -> some View {
        Button { configuration.isOn.toggle() } label: {
            HStack(alignment: .top, spacing: Space.s2) {
                Box(isOn: configuration.isOn).padding(.top, 2)
                configuration.label
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private struct Box: View {
        let isOn: Bool

        var body: some View {
            Canvas { context, size in
                let rect = CGRect(origin: .zero, size: size)
                guard isOn else {
                    context.stroke(Path(rect.insetBy(dx: Stroke.mark / 2, dy: Stroke.mark / 2)), with: .color(Palette.lineStrong), lineWidth: Stroke.mark)
                    return
                }
                context.fill(Path(rect), with: .color(Palette.ink))
                var tick = Path()
                tick.move(to: CGPoint(x: 4, y: 8))
                tick.addLine(to: CGPoint(x: 7, y: 11))
                tick.addLine(to: CGPoint(x: 12, y: 5))
                context.stroke(tick, with: .color(Palette.bg), style: StrokeStyle(lineWidth: Stroke.mark, lineCap: .square))
            }
            .frame(width: 16, height: 16)
        }
    }
}

extension ToggleStyle where Self == HairlineCheckboxStyle {
    public static var hairlineCheckbox: HairlineCheckboxStyle { HairlineCheckboxStyle() }
}
