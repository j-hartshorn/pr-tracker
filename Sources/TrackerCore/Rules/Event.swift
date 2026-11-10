import Foundation

/// Something that changed between two polls and is worth a notification.
public struct Event: Equatable, Sendable {
    public enum Kind: Equatable, Sendable {
        case reviewRequested
        /// On someone else's pull request.
        case mentioned
        /// On someone else's pull request, in a thread I began.
        case replied
        case reviewPosted(by: String, state: Review.State)
        case botReviewPosted(by: String, commentCount: Int)
        case checksFailed
        case conflicted
    }

    public var kind: Kind
    public var pullRequest: PullRequest
    public var url: URL

    /// Stable per pull request and kind, so a repeat replaces the earlier notification.
    public var id: String {
        let suffix = switch kind {
        case .reviewRequested: "review-requested"
        case .mentioned: "mention"
        case .replied: "replies"
        case .reviewPosted(let reviewer, _), .botReviewPosted(let reviewer, _): "review/\(reviewer)"
        case .checksFailed: "checks"
        case .conflicted: "conflict"
        }
        return "\(pullRequest.id)/\(suffix)"
    }

    public var title: String {
        switch kind {
        case .reviewRequested:
            "\(pullRequest.author) requested your review"
        case .mentioned:
            "You were mentioned"
        case .replied:
            "\(pullRequest.author) replied to your review"
        case .reviewPosted(let reviewer, .approved):
            "\(reviewer) approved"
        case .reviewPosted(let reviewer, .changesRequested):
            "\(reviewer) requested changes"
        case .reviewPosted(let reviewer, _):
            "\(reviewer) commented"
        case .botReviewPosted(let bot, let count):
            "\(Review.displayName(ofBot: bot)) left \(count) \(count == 1 ? "comment" : "comments")"
        case .checksFailed:
            "CI failed"
        case .conflicted:
            "Merge conflict"
        }
    }

    public var body: String {
        "\(pullRequest.repository) #\(pullRequest.number): \(pullRequest.title)"
    }
}

extension Review {
    public static func displayName(ofBot login: String) -> String {
        login == "copilot-pull-request-reviewer" ? "Copilot" : login
    }
}
