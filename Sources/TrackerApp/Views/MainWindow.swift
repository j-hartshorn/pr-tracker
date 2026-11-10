import Hairline
import SwiftUI
import TrackerCore

/// Everything on one page, as sections from top to bottom.
public struct MainWindow: View {
    @Environment(AppModel.self) private var model
    @Environment(\.openURL) private var openURL

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
            section("To review", snapshot.reviewRequested, in: snapshot, emptyText: "No reviews are waiting on you.") { pr in
                // The accent marks the one suggested next action: the review at the top.
                Button("Review") { openURL(pr.url) }
                    .buttonStyle(.hairline(pr.id == snapshot.reviewRequested.first?.id ? .accent : .standard, size: .small))
            }
            section("Mine", rows: PullRequestListRow.rows(from: snapshot.stacks), in: snapshot, emptyText: "You have no open pull requests.") { pr in
                Button(pr.isDraft ? "Mark ready" : "Convert to draft") { setDraft(!pr.isDraft, for: pr) }
                    .buttonStyle(.hairline(.quiet, size: .small))
            }
            section(
                "Awaiting review", snapshot.authored.filter { !$0.isDraft && !$0.requestedReviewers.isEmpty },
                in: snapshot, emptyText: "None of your pull requests are waiting on a reviewer."
            ) { _ in }
            section("Drafts", snapshot.authored.filter(\.isDraft), in: snapshot, emptyText: "You have no drafts.") { pr in
                Button("Mark ready") { setDraft(false, for: pr) }
                    .buttonStyle(.hairline(size: .small))
            }
        }
    }

    private func section<Trailing: View>(
        _ title: String, rows: [PullRequestListRow], in snapshot: Snapshot, emptyText: String,
        @ViewBuilder trailing: @escaping (PullRequest) -> Trailing
    ) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline, spacing: Space.s2) {
                Text(title).textStyle(.heading).foregroundStyle(Palette.ink)
                Text("\(rows.count)").textStyle(.label).foregroundStyle(Palette.inkMuted)
            }
            .padding(.bottom, Space.s2)
            Rule()
            PullRequestList(rows: rows, snapshot: snapshot, emptyText: emptyText, trailing: trailing)
        }
    }

    private func section<Trailing: View>(
        _ title: String, _ pullRequests: [PullRequest], in snapshot: Snapshot, emptyText: String,
        @ViewBuilder trailing: @escaping (PullRequest) -> Trailing
    ) -> some View {
        section(title, rows: pullRequests.map { PullRequestListRow(pullRequest: $0) }, in: snapshot, emptyText: emptyText, trailing: trailing)
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
