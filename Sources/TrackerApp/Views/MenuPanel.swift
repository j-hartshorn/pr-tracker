import Hairline
import SwiftUI
import TrackerCore

/// The menu bar dropdown: only the pull requests that need me.
public struct MenuPanel: View {
    private static let rowLimit = 8

    @Environment(AppModel.self) private var model
    @Environment(\.openWindow) private var openWindow

    public init() {}

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let error = model.lastError {
                AlertBox(.error, title: "The last refresh failed", detail: error)
                    .padding(.bottom, Space.s3)
            }
            if let snapshot = model.snapshot {
                let pullRequests = snapshot.needingAttention
                PullRequestList(
                    rows: pullRequests.prefix(Self.rowLimit).map { PullRequestListRow(pullRequest: $0) },
                    snapshot: snapshot, emptyText: "Nothing needs you right now."
                )
                if pullRequests.count > Self.rowLimit {
                    Text("And \(pullRequests.count - Self.rowLimit) more in the window.")
                        .textStyle(.small)
                        .foregroundStyle(Palette.inkMuted)
                        .padding(.top, Space.s2)
                }
            }
            HStack(spacing: Space.s3) {
                Button("Open window") {
                    openWindow(id: GHTrackerApp.windowID)
                    NSApplication.shared.activate()
                }
                .buttonStyle(.hairline(size: .small))
                Spacer()
                Button("Refresh") { Task { await model.refresh() } }
                    .buttonStyle(.hairline(.quiet, size: .small))
                    .disabled(model.isRefreshing)
                Button("Quit") { NSApplication.shared.terminate(nil) }
                    .buttonStyle(.hairline(.quiet, size: .small))
            }
            .padding(.top, Space.s3)
        }
        .padding(Space.s3)
        .frame(width: 420, alignment: .leading)
        .background(Palette.bg)
    }
}
