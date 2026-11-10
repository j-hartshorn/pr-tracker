import AppKit
import SwiftUI

/// macOS gives an app the menu bar only while it is in the Dock, so the app joins the Dock while one of its windows is open.
@MainActor
enum DockPresence {
    private static var openWindows = 0

    static func windowOpened() {
        openWindows += 1
        NSApplication.shared.setActivationPolicy(.regular)
    }

    static func windowClosed() {
        openWindows -= 1
        if openWindows == 0 { NSApplication.shared.setActivationPolicy(.accessory) }
    }
}

extension View {
    func joinsDockWhileOpen() -> some View {
        onAppear(perform: DockPresence.windowOpened).onDisappear(perform: DockPresence.windowClosed)
    }
}
