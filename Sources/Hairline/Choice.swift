import SwiftUI

/// A short row of options, one of them current. The current one has an ink underline.
public struct Choice<Value: Hashable>: View {
    private let options: [Value]
    private let selection: Binding<Value>
    private let title: (Value) -> String

    public init(_ options: [Value], selection: Binding<Value>, title: @escaping (Value) -> String) {
        self.options = options
        self.selection = selection
        self.title = title
    }

    public var body: some View {
        HStack(spacing: Space.s4) {
            ForEach(options, id: \.self) { option in
                let isCurrent = option == selection.wrappedValue
                Button { selection.wrappedValue = option } label: {
                    Text(title(option))
                        .textStyle(.control)
                        .foregroundStyle(isCurrent ? Palette.ink : Palette.inkMuted)
                        .padding(.bottom, Space.s1)
                        .overlay(alignment: .bottom) {
                            Rectangle().fill(isCurrent ? Palette.ink : .clear).frame(height: Stroke.focus)
                        }
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(isCurrent ? .isSelected : [])
            }
        }
    }
}
