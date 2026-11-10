import AppKit
import SwiftUI
import TrackerCore

/// A click opens the pull request on GitHub. A right-click copies its link.
struct PullRequestLink<Label: View>: View {
    let pullRequest: PullRequest
    @ViewBuilder let label: Label
    @Environment(\.openURL) private var openURL

    var body: some View {
        Button { openURL(pullRequest.url) } label: { label.contentShape(Rectangle()) }
            .buttonStyle(.plain)
            .pointerStyle(.link)
            .contextMenu {
                Button("Copy link") {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(pullRequest.url.absoluteString, forType: .string)
                }
            }
    }
}
