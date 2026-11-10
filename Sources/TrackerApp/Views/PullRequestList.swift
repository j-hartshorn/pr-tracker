import Hairline
import SwiftUI
import TrackerCore

struct PullRequestListRow: Identifiable {
    var pullRequest: PullRequest
    /// How many pull requests sit beneath this one in its stack.
    var depth = 0
    var id: String { pullRequest.id }

    /// Each stack from the bottom up, with every pull request directly under the one it is stacked on.
    static func rows(from stacks: [Stack], depth: Int = 0) -> [PullRequestListRow] {
        stacks.flatMap { [PullRequestListRow(pullRequest: $0.pullRequest, depth: depth)] + rows(from: $0.children, depth: depth + 1) }
    }
}

/// Rows divided by hairlines, or a line of text when there is nothing to show.
struct PullRequestList: View {
    let rows: [PullRequestListRow]
    let snapshot: Snapshot
    let emptyText: String

    var body: some View {
        if rows.isEmpty {
            Text(emptyText)
                .textStyle(.small)
                .foregroundStyle(Palette.inkMuted)
                .padding(.vertical, Space.s4)
        } else {
            LazyVStack(alignment: .leading, spacing: 0) {
                ForEach(rows) { row in
                    PullRequestRow(pullRequest: row.pullRequest, snapshot: snapshot, depth: row.depth)
                    Rule()
                }
            }
        }
    }
}
