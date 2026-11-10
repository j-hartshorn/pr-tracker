import Foundation
import Observation
import TrackerCore
import os

private let log = Logger(subsystem: "local.gh-tracker", category: "poll")

/// Owns the poll loop and the latest snapshot. The views read from here.
@MainActor @Observable
public final class AppModel {
    public private(set) var snapshot: Snapshot?
    /// Why the last refresh failed, or nil if it worked.
    public private(set) var lastError: String?
    public private(set) var isRefreshing = false
    /// Set when GitHub says its rate limit was hit. Nothing is sent before this time.
    private var pausedUntil: Date?

    private let client: GitHubClient
    private let file: SnapshotFile
    private let notify: @Sendable (Event) async -> Void

    public init(client: GitHubClient, file: SnapshotFile, notify: @escaping @Sendable (Event) async -> Void) {
        self.client = client
        self.file = file
        self.notify = notify
        self.snapshot = file.load()
    }

    public func start() {
        Task {
            while !Task.isCancelled {
                await refresh()
                try? await Task.sleep(for: .seconds(60))
            }
        }
    }

    /// A poll only fetches the details of pull requests that changed. `everything` fetches them all again.
    public func refresh(everything: Bool = false) async {
        guard !isRefreshing, pausedUntil.map({ $0 <= Date() }) ?? true else { return }
        isRefreshing = true
        defer { isRefreshing = false }
        do {
            let new = try await client.fetchSnapshot(reusing: everything ? nil : snapshot).carryingMergeability(from: snapshot)
            let events = new.events(since: snapshot)
            snapshot = new
            lastError = nil
            log.info("refreshed: \(new.authored.count) authored, \(new.reviewRequested.count) to review, \(events.count) events")
            for event in events { await notify(event) }
            try file.save(new)
        } catch {
            if case GitHubError.rateLimited(let until) = error { pausedUntil = until }
            lastError = error.localizedDescription
            log.error("refresh failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    public func setDraft(_ isDraft: Bool, for pullRequest: PullRequest) async {
        do {
            try await client.setDraft(isDraft, pullRequestID: pullRequest.id)
            // Shown at once. The next poll brings the reviewers and checks that follow from the change.
            if let index = snapshot?.authored.firstIndex(where: { $0.id == pullRequest.id }) {
                snapshot?.authored[index].isDraft = isDraft
            }
        } catch {
            lastError = error.localizedDescription
            log.error("setting draft failed: \(error.localizedDescription, privacy: .public)")
        }
    }
}
