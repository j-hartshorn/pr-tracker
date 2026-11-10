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

    public static let refreshChoices = [1, 2, 5, 10, 30]
    private static let refreshMinutesKey = "refreshMinutes"
    /// Minutes between polls. A change is saved, and ends the current wait, so the app polls now and then at the new pace.
    public var refreshMinutes: Int {
        didSet {
            UserDefaults.standard.set(refreshMinutes, forKey: Self.refreshMinutesKey)
            wait?.cancel()
        }
    }
    @ObservationIgnored private var wait: Task<Void, Never>?

    private let client: GitHubClient
    private let file: SnapshotFile
    private let notify: @Sendable (Event) async -> Void

    public init(client: GitHubClient, file: SnapshotFile, notify: @escaping @Sendable (Event) async -> Void) {
        self.client = client
        self.file = file
        self.notify = notify
        self.snapshot = file.load()
        self.refreshMinutes = UserDefaults.standard.object(forKey: Self.refreshMinutesKey) as? Int ?? 1
    }

    public func start() {
        Task {
            while !Task.isCancelled {
                await refresh()
                let wait = Task { [refreshMinutes] in _ = try? await Task.sleep(for: .seconds(60 * refreshMinutes)) }
                self.wait = wait
                await wait.value
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
}
