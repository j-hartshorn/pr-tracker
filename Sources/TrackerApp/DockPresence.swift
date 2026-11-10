import AppKit
import Hairline
import SwiftUI
import TrackerCore

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
    func joinsDockWhileOpen(_ model: AppModel) -> some View { modifier(JoinsDock(model: model)) }
}

private struct JoinsDock: ViewModifier {
    let model: AppModel
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        content
            .onAppear(perform: DockPresence.windowOpened)
            .onDisappear(perform: DockPresence.windowClosed)
            .onChange(of: statuses, initial: true, showIcon)
            .onChange(of: colorScheme, showIcon)
    }

    /// One status for each bar of the icon.
    private var statuses: [Status] {
        Array((model.snapshot?.statusesNeedingAttention ?? []).prefix(3))
    }

    private func showIcon() {
        let icon = AppIcon(bars: statuses.map(\.color), size: 1024).environment(\.colorScheme, colorScheme)
        NSApplication.shared.applicationIconImage = ImageRenderer(content: icon).nsImage
    }
}
