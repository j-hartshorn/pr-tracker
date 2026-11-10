import Hairline
import SwiftUI
import TrackerCore

/// One pull request: status glyph, title, facts, then whatever action the list wants.
struct PullRequestRow<Trailing: View>: View {
    let pullRequest: PullRequest
    let snapshot: Snapshot
    var depth = 0
    @ViewBuilder var trailing: Trailing
    @Environment(\.openURL) private var openURL

    var body: some View {
        let status = snapshot.status(of: pullRequest)
        HStack(alignment: .top, spacing: Space.s3) {
            Button { openURL(pullRequest.url) } label: {
                HStack(alignment: .top, spacing: Space.s3) {
                    Glyph(status.glyph, color: status.color).padding(.top, 2)
                    VStack(alignment: .leading, spacing: 0) {
                        Text(pullRequest.title)
                            .textStyle(.control)
                            .foregroundStyle(Palette.ink)
                            .lineLimit(1)
                        Text(snapshot.facts(about: pullRequest).joined(separator: " · "))
                            .textStyle(.label)
                            .foregroundStyle(Palette.inkMuted)
                            .lineLimit(2)
                    }
                    Spacer(minLength: 0)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            trailing
            Text(snapshot.age(of: pullRequest))
                .textStyle(.label)
                .foregroundStyle(Palette.inkMuted)
                .frame(minWidth: Space.s4, alignment: .trailing)
                .padding(.top, 2)
        }
        .padding(.vertical, Space.s2)
        .padding(.leading, CGFloat(depth) * Space.s4)
        .overlay(alignment: .leading) { stackGuides }
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
