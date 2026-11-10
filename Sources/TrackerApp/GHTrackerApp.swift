import SwiftUI

public struct GHTrackerApp: App {
    private let notifier = Notifier()

    public init() {
        let notifier = notifier
        Task {
            await notifier.requestAuthorization()
        }
    }

    public var body: some Scene {
        MenuBarExtra("gh-tracker", systemImage: "square") {
            Button("Quit") { NSApplication.shared.terminate(nil) }
        }
    }
}
