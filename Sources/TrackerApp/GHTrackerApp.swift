import Hairline
import SwiftUI
import TrackerCore

public struct GHTrackerApp: App {
    static let windowID = "main"

    // Held with let and not @State, because @State needs a compiler plugin that ships only with Xcode.
    private let model: AppModel

    public init() {
        if let resources = Bundle.main.resourceURL {
            Fonts.register(in: resources.appending(path: "Fonts"))
        }
        let notifier = Notifier()
        let model = AppModel(client: GitHubClient(), file: .applicationSupport, notify: notifier.post)
        self.model = model
        Task {
            await notifier.requestAuthorization()
            model.start()
        }
    }

    public var body: some Scene {
        Window("gh-tracker", id: Self.windowID) {
            MainWindow()
                .environment(model)
                .containerBackground(Palette.bg, for: .window)
        }
        .defaultSize(width: 860, height: 900)

        MenuBarExtra {
            MenuPanel()
                .environment(model)
        } label: {
            MenuBarIcon(status: model.snapshot?.mostUrgentStatus ?? .waiting)
        }
        .menuBarExtraStyle(.window)
    }
}
