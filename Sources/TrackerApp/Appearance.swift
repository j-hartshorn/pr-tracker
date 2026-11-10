import AppKit
import SwiftUI

/// The setting for the app's colours: the system's appearance, or always Paper, or always Dark.
enum Appearance: String, CaseIterable {
    case system, light, dark

    static let key = "appearance"

    var title: String {
        switch self {
        case .system: "Match system"
        case .light: "Light"
        case .dark: "Dark"
        }
    }

    fileprivate var nsAppearance: NSAppearance? {
        switch self {
        case .system: nil
        case .light: NSAppearance(named: .aqua)
        case .dark: NSAppearance(named: .darkAqua)
        }
    }
}

extension View {
    func followsAppearanceSetting() -> some View { modifier(FollowsAppearanceSetting()) }
}

private struct FollowsAppearanceSetting: ViewModifier {
    @AppStorage(Appearance.key) private var appearance = Appearance.system

    // Set on the app, as preferredColorScheme does not go back to the system's appearance when it is cleared.
    func body(content: Content) -> some View {
        content.onChange(of: appearance, initial: true) {
            NSApplication.shared.appearance = appearance.nsAppearance
        }
    }
}
