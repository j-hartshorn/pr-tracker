import Foundation
import TrackerCore

extension Snapshot {
    /// The short facts shown under a pull request's title. They say in words what the glyph shows.
    func facts(about pr: PullRequest) -> [String] {
        var facts = ["\(pr.repository) #\(pr.number)"]
        guard pr.author == viewer else {
            return facts + [pr.author] + checksFact(pr)
        }
        if status(of: pr) == .ready { facts.append("ready to merge") }
        if pr.isDraft { facts.append("draft") }
        facts += checksFact(pr)
        if pr.mergeability == .conflicting { facts.append("conflicts") }
        switch pr.approval {
        case .approved: facts.append("approved")
        case .changesRequested: facts.append("changes requested")
        case .reviewRequired, nil: break
        }
        if !pr.requestedReviewers.isEmpty {
            facts.append("waiting on \(pr.requestedReviewers.joined(separator: ", "))")
        }
        return facts + botFacts(pr)
    }

    private func checksFact(_ pr: PullRequest) -> [String] {
        switch pr.checks {
        case .failing: ["CI failing"]
        case .pending: ["CI running"]
        case .passing: ["CI passing"]
        case .none: []
        }
    }

    /// Bots are kept apart from people: their latest review is a note, not an approval.
    private func botFacts(_ pr: PullRequest) -> [String] {
        Dictionary(grouping: pr.reviews.filter(\.isBot), by: \.author)
            .sorted { $0.key < $1.key }
            .compactMap { bot, reviews in
                guard let count = reviews.last?.commentCount else { return nil }
                let comments = switch count {
                case 0: "no comments"
                case 1: "1 comment"
                default: "\(count) comments"
                }
                return "\(Review.displayName(ofBot: bot)): \(comments)"
            }
    }

    /// How long before this snapshot the pull request last changed.
    func age(of pr: PullRequest) -> String {
        let seconds = max(0, fetchedAt.timeIntervalSince(pr.updatedAt))
        return switch seconds {
        case ..<3600: "\(Int(seconds / 60))m"
        case ..<86400: "\(Int(seconds / 3600))h"
        default: "\(Int(seconds / 86400))d"
        }
    }
}
