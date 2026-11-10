import SwiftUI

public struct HairlineButtonStyle: ButtonStyle {
    public enum Kind: Sendable {
        /// Most actions.
        case standard
        /// The main action. One per view.
        case primary
        /// The one thing the screen is for. It uses up the screen's accent.
        case accent
        /// Low-priority actions in text.
        case quiet
    }

    public enum Size: Sendable {
        case regular, small
    }

    let kind: Kind
    let size: Size

    public func makeBody(configuration: Configuration) -> some View {
        StyledLabel(kind: kind, size: size, configuration: configuration)
    }

    private struct StyledLabel: View {
        let kind: Kind
        let size: Size
        let configuration: Configuration
        @Environment(\.isEnabled) private var isEnabled
        @Environment(\.isFocused) private var isFocused

        var body: some View {
            configuration.label
                .textStyle(.control)
                .underline(kind == .quiet)
                .foregroundStyle(foreground)
                .padding(.vertical, size == .regular ? 9 : 5)
                .padding(.horizontal, kind == .quiet ? 0 : (size == .regular ? Space.s3 : 12))
                .background(background)
                .border(border, width: Stroke.hair)
                .padding(Stroke.focus * 2)
                .border(isFocused ? Palette.focus : .clear, width: Stroke.focus)
                .padding(-Stroke.focus * 2)
                .contentShape(Rectangle())
        }

        private var foreground: Color {
            guard isEnabled else { return Palette.lineStrong }
            return switch kind {
            case .standard, .quiet: Palette.ink
            case .primary: Palette.bg
            case .accent: Palette.accentInk
            }
        }

        private var background: Color {
            guard isEnabled else { return Palette.bg }
            return switch kind {
            case .standard: Palette.bg
            case .quiet: .clear
            case .primary: configuration.isPressed ? Palette.inkMuted : Palette.ink
            case .accent: Palette.accent
            }
        }

        private var border: Color {
            guard isEnabled else { return kind == .quiet ? .clear : Palette.line }
            return switch kind {
            case .standard: configuration.isPressed ? Palette.ink : Palette.lineStrong
            case .quiet: .clear
            case .primary: configuration.isPressed ? Palette.inkMuted : Palette.ink
            case .accent: Palette.accent
            }
        }
    }
}

extension ButtonStyle where Self == HairlineButtonStyle {
    public static func hairline(_ kind: HairlineButtonStyle.Kind = .standard, size: HairlineButtonStyle.Size = .regular) -> HairlineButtonStyle {
        HairlineButtonStyle(kind: kind, size: size)
    }
}
