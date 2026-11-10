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
                if pullRequests.isEmpty {
                    Text("Nothing needs you right now.")
                        .textStyle(.small)
                        .foregroundStyle(Palette.inkMuted)
                }
                ForEach(pullRequests.prefix(Self.rowLimit)) { pullRequest in
                    CompactPullRequestRow(pullRequest: pullRequest, snapshot: snapshot)
                }
                if pullRequests.count > Self.rowLimit {
                    Text("And \(pullRequests.count - Self.rowLimit) more in the window.")
                        .textStyle(.small)
                        .foregroundStyle(Palette.inkMuted)
                        .padding(.top, Space.s2)
                }
            }
            Rule().padding(.top, Space.s3)
            HStack(spacing: Space.s2) {
                Button("Open window") {
                    openWindow(id: GHTrackerApp.windowID)
                    NSApplication.shared.activate()
                }
                .buttonStyle(.hairline(size: .small))
                Spacer()
                Button(model.isRefreshing ? "Refreshing" : "Refresh") { Task { await model.refresh(everything: true) } }
                    .buttonStyle(.hairline(size: .small))
                    .disabled(model.isRefreshing)
                Button("Quit") { NSApplication.shared.terminate(nil) }
                    .buttonStyle(.hairline(size: .small))
            }
            .padding(.top, Space.s3)
        }
        .padding(Space.s3)
        .frame(width: 800, alignment: .leading)
        .overlay(alignment: .bottom) { CopiedLinkToast().padding(Space.s3) }
        .background(Palette.bg)
    }
}
