import Hairline
import SwiftUI
import TrackerCore

/// One line for the menu bar panel: status glyph, next step and title.
struct CompactPullRequestRow: View {
    let pullRequest: PullRequest
    let snapshot: Snapshot

    var body: some View {
        let status = snapshot.status(of: pullRequest)
        PullRequestLink(pullRequest: pullRequest) {
            HStack(spacing: Space.s2) {
                Glyph(status.glyph, color: status.color, size: 20)
                Text(snapshot.nextStepsText(for: pullRequest))
                    .foregroundStyle(Palette.ink)
                    .layoutPriority(1)
                Text(pullRequest.title)
                    .foregroundStyle(pullRequest.isDraft ? Palette.lineStrong : Palette.inkMuted)
                Spacer(minLength: 0)
            }
            .textStyle(.small)
            .lineLimit(1)
        }
        .padding(.vertical, Space.s1)
    }
}
