import AppKit
import Observation
import TrackerCore

/// Copies a pull request's link, and keeps it as `lastCopied` for a moment so the views can confirm it.
@MainActor @Observable
public final class LinkCopier {
    public private(set) var lastCopied: PullRequest?
    private var clearing: Task<Void, Never>?

    public init() {}

    public func copyLink(of pullRequest: PullRequest) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(pullRequest.url.absoluteString, forType: .string)
        lastCopied = pullRequest
        clearing?.cancel()
        clearing = Task {
            try? await Task.sleep(for: .seconds(2))
            if !Task.isCancelled { lastCopied = nil }
        }
    }
}
