import Hairline
import SwiftUI
import TrackerCore

/// One pull request: status glyph, title, then who has the ball. A click opens it on GitHub.
struct PullRequestRow: View {
    let pullRequest: PullRequest
    let snapshot: Snapshot
    var depth = 0
    /// Offered on right-click for my own pull requests. The argument is the new draft state.
    var setDraft: ((Bool) -> Void)?
    @Environment(\.openURL) private var openURL

    var body: some View {
        let status = snapshot.status(of: pullRequest)
        Button { openURL(pullRequest.url) } label: {
            HStack(alignment: .top, spacing: Space.s3) {
                Glyph(status.glyph, color: status.color).padding(.top, 2)
                VStack(alignment: .leading, spacing: 0) {
                    Text(pullRequest.title)
                        .textStyle(.control)
                        .foregroundStyle(Palette.ink)
                        .lineLimit(1)
                    detail.lineLimit(2)
                }
                Spacer(minLength: 0)
                Text(snapshot.age(of: pullRequest))
                    .textStyle(.label)
                    .foregroundStyle(Palette.inkMuted)
                    .padding(.top, 2)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .pointerStyle(.link)
        .contextMenu {
            if let setDraft, pullRequest.author == snapshot.viewer {
                Button(pullRequest.isDraft ? "Mark ready" : "Convert to draft") { setDraft(!pullRequest.isDraft) }
            }
        }
        .padding(.vertical, Space.s2)
        .padding(.leading, CGFloat(depth) * Space.s4)
        .overlay(alignment: .leading) { stackGuides }
    }

    /// The next step in ink, then the quiet facts.
    private var detail: some View {
        let nextSteps = Text(snapshot.nextStepsText(for: pullRequest))
            .font(TextStyle.small.font)
            .foregroundStyle(Palette.ink)
        let facts = Text(snapshot.facts(about: pullRequest).joined(separator: " · "))
            .font(TextStyle.label.font)
            .foregroundStyle(Palette.inkMuted)
        return Text("\(nextSteps)   \(facts)").lineHeight(.exact(points: 20))
    }

    /// One vertical hairline for each pull request beneath this one in its stack.
    private var stackGuides: some View {
        HStack(spacing: 0) {
            ForEach(0..<depth, id: \.self) { _ in
                Rule(.vertical).frame(width: Space.s4)
            }
        }
    }
}
