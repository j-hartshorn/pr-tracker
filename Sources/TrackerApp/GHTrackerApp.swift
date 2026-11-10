import Hairline
import SwiftUI
import TrackerCore

public struct GHTrackerApp: App {
    static let windowID = "main"

    // Held with let and not @State, because @State needs a compiler plugin that ships only with Xcode.
    private let model: AppModel
    private let launchAtLogin = LaunchAtLogin()
    private let copier = LinkCopier()

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
        Window("PR Tracker", id: Self.windowID) {
            MainWindow()
                .environment(model)
                .environment(copier)
                .containerBackground(Palette.bg, for: .window)
                .ignoresSafeArea(edges: .top)
                .darkWhenSet()
                .joinsDockWhileOpen(model)
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 860, height: 900)
        .commands {
            CommandGroup(before: .toolbar) {
                Button("Refresh") { Task { await model.refresh(everything: true) } }
                    .keyboardShortcut("r")
                    .disabled(model.isRefreshing)
            }
            CommandGroup(replacing: .help) {}
        }

        Settings {
            SettingsView()
                .environment(model)
                .environment(launchAtLogin)
                .containerBackground(Palette.bg, for: .window)
                .darkWhenSet()
                .joinsDockWhileOpen(model)
        }

        MenuBarExtra {
            MenuPanel()
                .environment(model)
                .environment(copier)
                .darkWhenSet()
        } label: {
            MenuBarIcon(status: model.snapshot?.mostUrgentStatus ?? .waiting)
        }
        .menuBarExtraStyle(.window)
    }
}
