import Hairline
import SwiftUI
import TrackerCore

/// One pull request: status glyph, title, who has the ball, and its age. A click opens it on GitHub.
struct PullRequestRow: View {
    private static let nextStepColumnWidth: CGFloat = 240
    private static let ageColumnWidth: CGFloat = 32

    let pullRequest: PullRequest
    let snapshot: Snapshot
    var depth = 0
    /// The next step gets its own column where there is room. Otherwise it leads the second line.
    var showsNextStepColumn = false
    /// Offered on right-click for my own pull requests. The argument is the new draft state.
    var setDraft: ((Bool) -> Void)?
    @Environment(\.openURL) private var openURL

    var body: some View {
        let status = snapshot.status(of: pullRequest)
        Button { openURL(pullRequest.url) } label: {
            HStack(alignment: .top, spacing: Space.s3) {
                Glyph(status.glyph, color: isParked ? Palette.lineStrong : status.color).padding(.top, 2)
                VStack(alignment: .leading, spacing: 0) {
                    Text(pullRequest.title)
                        .textStyle(.control)
                        .foregroundStyle(pullRequest.isDraft ? Palette.lineStrong : Palette.ink)
                        .lineLimit(1)
                    (showsNextStepColumn ? facts : Text("\(nextSteps)   \(facts)"))
                        .lineHeight(.exact(points: 20))
                        .lineLimit(2)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                if showsNextStepColumn {
                    nextSteps
                        .lineHeight(.exact(points: 20))
                        .lineLimit(2)
                        .frame(width: Self.nextStepColumnWidth, alignment: .leading)
                }
                Text(snapshot.age(of: pullRequest))
                    .textStyle(.label)
                    .foregroundStyle(quiet)
                    .padding(.top, 2)
                    .frame(width: Self.ageColumnWidth, alignment: .trailing)
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

    /// A draft with nothing for me to do. The whole row drops to the disabled grey.
    private var isParked: Bool {
        pullRequest.isDraft && !snapshot.nextSteps(for: pullRequest)[0].isMine
    }

    private var quiet: Color {
        isParked ? Palette.lineStrong : Palette.inkMuted
    }

    private var nextSteps: Text {
        Text(snapshot.nextStepsText(for: pullRequest))
            .font((showsNextStepColumn ? TextStyle.control : .small).font)
            .foregroundStyle(isParked ? Palette.lineStrong : Palette.ink)
    }

    private var facts: Text {
        Text(snapshot.facts(about: pullRequest).joined(separator: " · "))
            .font(TextStyle.label.font)
            .foregroundStyle(quiet)
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
