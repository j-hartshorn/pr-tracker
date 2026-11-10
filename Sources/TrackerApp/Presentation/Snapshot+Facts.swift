import Foundation
import TrackerCore

extension Snapshot {
    /// What the pull request waits on, in words. This is the line that says who has the ball.
    func nextStepsText(for pr: PullRequest) -> String {
        nextSteps(for: pr).map { text(for: $0, of: pr) }.joined(separator: " · ")
    }

    private func text(for step: NextStep, of pr: PullRequest) -> String {
        switch step {
        case .review: "review for \(pr.author)"
        case .answerComments(1): "answer 1 comment"
        case .answerComments(let count): "answer \(count) comments"
        case .answerMention: "answer a mention"
        case .respond(let reviewers): "respond to \(reviewers.joined(separator: ", "))"
        case .fixChecks: "fix CI"
        case .resolveConflicts: "resolve conflicts"
        case .requestReview: "request a review"
        case .merge: "ready to merge"
        case .waitingOnReviewers(let reviewers, let since):
            "waiting on \(reviewers.joined(separator: ", "))" + (since.map { " for \(duration(since: $0))" } ?? "")
        case .waitingOnChecks: "waiting on CI"
        case .waitingOnStack(let number): "waiting on #\(number)"
        case .waitingOnAuthor: "waiting on \(pr.author)"
        case .draft: "draft"
        }
    }

    /// The quiet facts after the pull request's number. They add what the next step does not already say.
    func facts(about pr: PullRequest) -> [String] {
        var facts = [pr.repository]
        let isMine = pr.author == viewer
        let steps = nextSteps(for: pr)
        if pr.isDraft, steps != [.draft] { facts.append("draft") }
        if isMine, steps[0].isMine, !pr.requestedReviewers.isEmpty {
            facts.append("waiting on \(pr.requestedReviewers.joined(separator: ", "))")
        }
        // "review for alice" names the author already. The other steps on someone else's pull request do not.
        if !isMine, steps != [.review] { facts.append("by \(pr.author)") }
        // Only failing CI is news. On my own pull requests it is already the step "fix CI".
        guard isMine else { return pr.checks == .failing ? facts + ["CI failing"] : facts }
        switch pr.approval {
        case .approved: facts.append("approved")
        case .changesRequested: facts.append("changes requested")
        case .reviewRequired, nil: break
        }
        return facts + botFacts(pr)
    }

    /// Bots are kept apart from people: their latest review is a note, not something to answer.
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

    /// Minutes ago within the hour, then the time of day.
    func updatedText(now: Date) -> String {
        let minutes = Int(max(0, now.timeIntervalSince(fetchedAt)) / 60)
        return switch minutes {
        case 0: "Updated just now"
        case 1: "Updated 1 minute ago"
        case ..<60: "Updated \(minutes) minutes ago"
        default: "Updated \(fetchedAt.formatted(date: .omitted, time: .shortened))"
        }
    }

    /// How long before this snapshot the pull request last changed.
    func age(of pr: PullRequest) -> String {
        duration(since: pr.updatedAt)
    }

    private func duration(since date: Date) -> String {
        let seconds = max(0, fetchedAt.timeIntervalSince(date))
        return switch seconds {
        case ..<3600: "\(Int(seconds / 60))m"
        case ..<86400: "\(Int(seconds / 3600))h"
        default: "\(Int(seconds / 86400))d"
        }
    }
}
