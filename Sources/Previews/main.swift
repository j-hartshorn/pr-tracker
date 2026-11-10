// Renders the app's views to PNG files, so the interface can be checked without Xcode previews.
// Usage: swift run Previews [output directory]
import AppKit
import Hairline
import SwiftUI
import TrackerApp
import TrackerCore

let arguments = CommandLine.arguments.dropFirst()
let output = URL(fileURLWithPath: arguments.first ?? "build/previews")
try FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)

_ = NSApplication.shared
Fonts.register(in: URL(fileURLWithPath: "docs/design-system/fonts"))

let file = SnapshotFile(url: FileManager.default.temporaryDirectory.appending(path: "gh-tracker-previews/snapshot.json"))
try file.save(Fixtures.snapshot)
let model = AppModel(client: GitHubClient(), file: file, notify: { _ in })

let missingFile = SnapshotFile(url: FileManager.default.temporaryDirectory.appending(path: "gh-tracker-previews/missing.json"))
let failingModel = AppModel(client: GitHubClient(token: { throw GitHubError.ghFailed("not logged in") }), file: missingFile, notify: { _ in })
await failingModel.refresh()
let copier = LinkCopier()

for (name, appearance) in [("paper", NSAppearance.Name.aqua), ("dark", .darkAqua)] {
    try render(MainWindow().environment(model).environment(copier), size: CGSize(width: 820, height: 1180), appearance: appearance, to: output.appending(path: "window-\(name).png"))
    try render(MainWindow().environment(failingModel).environment(copier), size: CGSize(width: 820, height: 400), appearance: appearance, to: output.appending(path: "window-error-\(name).png"))
    try render(MenuPanel().environment(model).environment(copier), size: CGSize(width: 600, height: 520), appearance: appearance, to: output.appending(path: "menu-\(name).png"))
    try render(SettingsView().environment(model).environment(LaunchAtLogin()), size: CGSize(width: 420, height: 300), appearance: appearance, to: output.appending(path: "settings-\(name).png"))
    try render(ComponentSheet(), size: CGSize(width: 820, height: 680), appearance: appearance, to: output.appending(path: "components-\(name).png"))
}
print("Wrote previews to \(output.path)")

@MainActor
func render(_ view: some View, size: CGSize, appearance: NSAppearance.Name, to url: URL) throws {
    let host = NSHostingView(rootView: view.frame(width: size.width, height: size.height))
    let window = NSWindow(contentRect: CGRect(origin: .zero, size: size), styleMask: [.borderless], backing: .buffered, defer: false)
    window.appearance = NSAppearance(named: appearance)
    window.contentView = host
    host.layoutSubtreeIfNeeded()
    RunLoop.main.run(until: Date().addingTimeInterval(0.2))
    guard let bitmap = host.bitmapImageRepForCachingDisplay(in: host.bounds) else { return }
    host.cacheDisplay(in: host.bounds, to: bitmap)
    try bitmap.representation(using: .png, properties: [:])?.write(to: url)
}
