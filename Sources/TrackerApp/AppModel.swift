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

    private let fetch: @Sendable () async throws -> Snapshot
    private let file: SnapshotFile
    private let notify: @Sendable (Event) async -> Void
    private let interval: Duration

    public init(
        fetch: @escaping @Sendable () async throws -> Snapshot,
        file: SnapshotFile,
        notify: @escaping @Sendable (Event) async -> Void,
        interval: Duration = .seconds(60)
    ) {
        self.fetch = fetch
        self.file = file
        self.notify = notify
        self.interval = interval
        self.snapshot = file.load()
    }

    public func start() {
        Task {
            while !Task.isCancelled {
                await refresh()
                try? await Task.sleep(for: interval)
            }
        }
    }

    public func refresh() async {
        guard !isRefreshing else { return }
        isRefreshing = true
        defer { isRefreshing = false }
        do {
            let new = try await fetch().carryingMergeability(from: snapshot)
            let events = new.events(since: snapshot)
            snapshot = new
            lastError = nil
            try file.save(new)
            log.info("refreshed: \(new.authored.count) authored, \(new.reviewRequested.count) to review, \(events.count) events")
            for event in events { await notify(event) }
        } catch {
            lastError = error.localizedDescription
            log.error("refresh failed: \(error.localizedDescription, privacy: .public)")
        }
    }
}
