import AppKit
import SwiftUI

extension View {
    /// Hides the close, minimise and zoom buttons of the window this view is in. SwiftUI can hide the title bar but not its buttons.
    func windowButtonsHidden() -> some View { background(WindowButtonsHidden()) }
}

private struct WindowButtonsHidden: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView { Probe() }
    func updateNSView(_ view: NSView, context: Context) {}

    private final class Probe: NSView {
        override func viewDidMoveToWindow() {
            for button in [NSWindow.ButtonType.closeButton, .miniaturizeButton, .zoomButton] {
                window?.standardWindowButton(button)?.isHidden = true
            }
        }
    }
}
