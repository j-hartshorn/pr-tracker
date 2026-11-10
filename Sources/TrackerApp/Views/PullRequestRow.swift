import Hairline
import SwiftUI
import TrackerCore

/// One pull request: status glyph, title, who has the ball, and its age.
struct PullRequestRow: View {
    /// The height of the title line (20) and the facts line (16). The glyph's own margin then puts its square between the top of the title's capitals and the baseline of the facts.
    private static let glyphSize: CGFloat = 36
    private static let nextStepColumnWidth: CGFloat = 240
    private static let ageColumnWidth: CGFloat = 32

    let pullRequest: PullRequest
    let snapshot: Snapshot
    var depth = 0

    var body: some View {
        let status = snapshot.status(of: pullRequest)
        PullRequestLink(pullRequest: pullRequest) {
            HStack(alignment: .top, spacing: Space.s3) {
                Glyph(status.glyph, color: isParked ? Palette.lineStrong : status.color, size: Self.glyphSize)
                    // The glyph has a margin of its own, so it sits one step closer to the text than the columns do to each other.
                    .padding(.trailing, -Space.s1)
                VStack(alignment: .leading, spacing: 0) {
                    Text(pullRequest.title)
                        .textStyle(.control)
                        .foregroundStyle(pullRequest.isDraft ? Palette.lineStrong : Palette.ink)
                        .lineLimit(1)
                    Text(snapshot.facts(about: pullRequest).joined(separator: " · "))
                        .textStyle(.label)
                        .foregroundStyle(quiet)
                        .lineLimit(2)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                Text(snapshot.nextStepsText(for: pullRequest))
                    .textStyle(.control)
                    .foregroundStyle(isParked ? Palette.lineStrong : Palette.ink)
                    .lineLimit(2)
                    .frame(width: Self.nextStepColumnWidth, alignment: .leading)
                Text(snapshot.age(of: pullRequest))
                    .textStyle(.label)
                    .foregroundStyle(quiet)
                    .padding(.top, 2)
                    .frame(width: Self.ageColumnWidth, alignment: .trailing)
            }
        }
        .padding(.vertical, Space.s2)
        .padding(.leading, CGFloat(depth) * Self.glyphSize)
        .overlay(alignment: .leading) { stackGuides }
    }

    /// A draft with nothing for me to do. The whole row drops to the disabled grey.
    private var isParked: Bool {
        pullRequest.isDraft && !snapshot.nextSteps(for: pullRequest)[0].isMine
    }

    private var quiet: Color {
        isParked ? Palette.lineStrong : Palette.inkMuted
    }

    /// One vertical hairline for each pull request beneath this one in its stack. Each indent is one glyph wide, so a line runs down from the centre of the glyph it belongs to.
    private var stackGuides: some View {
        HStack(spacing: 0) {
            ForEach(0..<depth, id: \.self) { _ in
                Rule(.vertical).frame(width: Self.glyphSize)
            }
        }
    }
}
