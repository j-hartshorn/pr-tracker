import SwiftUI
import TrackerCore

public struct GHTrackerApp: App {
    private let model: AppModel

    public init() {
        let notifier = Notifier()
        let client = GitHubClient()
        let model = AppModel(fetch: client.fetchSnapshot, file: .applicationSupport, notify: notifier.post)
        self.model = model
        Task {
            await notifier.requestAuthorization()
            model.start()
        }
    }

    public var body: some Scene {
        MenuBarExtra("gh-tracker", systemImage: "square") {
            if let snapshot = model.snapshot {
                Text("\(snapshot.reviewRequested.count) to review, \(snapshot.authored.count) of mine")
            }
            if let error = model.lastError {
                Text(error)
            }
            Button("Refresh") { Task { await model.refresh() } }
            Button("Quit") { NSApplication.shared.terminate(nil) }
        }
    }
}
