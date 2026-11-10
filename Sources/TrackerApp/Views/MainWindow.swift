import Hairline
import SwiftUI
import TrackerCore

/// One page: what needs me, then everything of mine.
public struct MainWindow: View {
    @Environment(AppModel.self) private var model

    public init() {}

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
                .padding(.horizontal, Space.s4)
                .padding(.vertical, Space.s2)
            Rule()
            if let error = model.lastError {
                AlertBox(.error, title: "The last refresh failed", detail: error)
                    .padding([.horizontal, .top], Space.s4)
            }
            if let snapshot = model.snapshot {
                ScrollView {
                    sections(snapshot)
                        .padding(Space.s4)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            } else if model.lastError == nil {
                Text("Loading pull requests.")
                    .textStyle(.small)
                    .foregroundStyle(Palette.inkMuted)
                    .padding(Space.s4)
            }
            Spacer(minLength: 0)
        }
        .frame(minWidth: 640, minHeight: 360, alignment: .topLeading)
        .background(Palette.bg)
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline, spacing: Space.s3) {
            Spacer()
            if let fetchedAt = model.snapshot?.fetchedAt {
                Text("Updated \(fetchedAt.formatted(date: .omitted, time: .shortened))")
                    .textStyle(.label)
                    .foregroundStyle(Palette.inkMuted)
            }
            Button(model.isRefreshing ? "Refreshing" : "Refresh") {
                Task { await model.refresh() }
            }
            .buttonStyle(.hairline(.quiet, size: .small))
            .disabled(model.isRefreshing)
        }
    }

    private func sections(_ snapshot: Snapshot) -> some View {
        VStack(alignment: .leading, spacing: Space.s5) {
            section(
                "Needs attention", rows: snapshot.needingAttention.map { PullRequestListRow(pullRequest: $0) },
                in: snapshot, emptyText: "Nothing needs you right now."
            )
            section("Mine", rows: PullRequestListRow.rows(from: snapshot.stacks), in: snapshot, emptyText: "You have no open pull requests.")
        }
    }

    private func section(_ title: String, rows: [PullRequestListRow], in snapshot: Snapshot, emptyText: String) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline, spacing: Space.s2) {
                Text(title).textStyle(.heading).foregroundStyle(Palette.ink)
                Text("\(rows.count)").textStyle(.label).foregroundStyle(Palette.inkMuted)
            }
            .padding(.bottom, Space.s2)
            Rule()
            PullRequestList(rows: rows, snapshot: snapshot, emptyText: emptyText, setDraft: setDraft)
        }
    }

    /// Asks first, because both directions are visible to other people.
    private func setDraft(_ isDraft: Bool, for pr: PullRequest) {
        let alert = NSAlert()
        alert.messageText = isDraft ? "Convert #\(pr.number) to a draft?" : "Mark #\(pr.number) ready for review?"
        alert.informativeText = isDraft ? "It cannot merge until it is marked ready again." : "Its reviewers will be notified."
        alert.addButton(withTitle: isDraft ? "Convert to draft" : "Mark ready")
        alert.addButton(withTitle: "Cancel")
        guard alert.runModal() == .alertFirstButtonReturn else { return }
        Task { await model.setDraft(isDraft, for: pr) }
    }
}
