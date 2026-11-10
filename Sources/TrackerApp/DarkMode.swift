import AppKit
import SwiftUI

/// The setting that keeps the app dark. When it is off, the app follows the system.
enum DarkMode {
    static let key = "usesDarkMode"
}

extension View {
    func darkWhenSet() -> some View { modifier(DarkWhenSet()) }
}

private struct DarkWhenSet: ViewModifier {
    @AppStorage(DarkMode.key) private var isOn = false

    // Set on the app, as preferredColorScheme does not go back to the system's appearance when it is cleared.
    func body(content: Content) -> some View {
        content.onChange(of: isOn, initial: true) {
            NSApplication.shared.appearance = isOn ? NSAppearance(named: .darkAqua) : nil
        }
    }
}
