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

    func body(content: Content) -> some View {
        content.preferredColorScheme(isOn ? .dark : nil)
    }
}
