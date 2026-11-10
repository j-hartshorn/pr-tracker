import Foundation

/// What a pull request is waiting on: who has the ball. The first group is mine to do, in the order to look at them. The second is someone or something else.
public enum NextStep: Equatable, Sendable {
    /// Someone else's pull request, and my review is requested by name.
    case review
    /// Open review threads where another person spoke last.
    case answerComments(Int)
    /// Someone else's pull request, where I was mentioned and have not commented or reviewed since.
    case answerMention
    /// Reviewers who commented or requested changes, and nothing has gone back to them since.
    case respond(to: [String])
    case fixChecks
    case resolveConflicts
    /// Not approved, and nobody is asked to review.
    case requestReview
    case merge

    case waitingOnReviewers([String], since: Date?)
    case waitingOnChecks
    /// Approved, but stacked on an open pull request with this number.
    case waitingOnStack(below: Int)
    /// Someone else's pull request that I took part in, with nothing of theirs for me to answer.
    case waitingOnAuthor
    case draft

    public var isMine: Bool {
        switch self {
        case .review, .answerComments, .answerMention, .respond, .fixChecks, .resolveConflicts, .requestReview, .merge: true
        case .waitingOnReviewers, .waitingOnChecks, .waitingOnStack, .waitingOnAuthor, .draft: false
        }
    }

    /// Where a pull request sorts in the list of things that need me.
    fileprivate var rank: Int {
        switch self {
        case .review: 0
        case .answerComments, .answerMention, .respond: 1
        case .fixChecks, .resolveConflicts: 2
        case .requestReview: 3
        case .merge: 4
        case .waitingOnReviewers, .waitingOnChecks, .waitingOnStack, .waitingOnAuthor, .draft: 5
        }
    }
}

extension Snapshot {
    /// Every step that is mine to take, or else the one thing the pull request waits on. Never empty.
    public func nextSteps(for pr: PullRequest) -> [NextStep] {
        guard pr.author == viewer else { return [stepOnTheirs(pr)] }

        let reviewers = pr.reviewersAwaitingResponse
        let approved = pr.approval == .approved
        let below = parent(of: pr)
        var mine: [NextStep] = []

        if pr.unansweredThreadCount > 0 {
            mine.append(.answerComments(pr.unansweredThreadCount))
        } else if !reviewers.isEmpty {
            mine.append(.respond(to: reviewers))
        }
        if pr.checks == .failing { mine.append(.fixChecks) }
        if pr.mergeability == .conflicting { mine.append(.resolveConflicts) }

        let canMerge = pr.checks != .failing && pr.checks != .pending && pr.mergeability == .mergeable
        if !pr.isDraft {
            let hasReviewToAnswer = pr.unansweredThreadCount > 0 || !reviewers.isEmpty
            if !approved, !hasReviewToAnswer, pr.requestedReviewers.isEmpty { mine.append(.requestReview) }
            if approved, canMerge, below == nil { mine.append(.merge) }
        }
        if !mine.isEmpty { return mine }

        if pr.isDraft { return [.draft] }
        if !approved { return [.waitingOnReviewers(pr.requestedReviewers, since: pr.waitingSince)] }
        if canMerge, let below { return [.waitingOnStack(below: below.number)] }
        return [.waitingOnChecks]
    }

    private func stepOnTheirs(_ pr: PullRequest) -> NextStep {
        if reviewRequested.contains(where: { $0.id == pr.id }) { return .review }
        if pr.unansweredThreadCount > 0 { return .answerComments(pr.unansweredThreadCount) }
        return pr.mentionedAt == nil ? .waitingOnAuthor : .answerMention
    }

    /// The pull requests where the ball is with me, in the order to look at them.
    public var needingAttention: [PullRequest] {
        (reviewRequested + involved + authored)
            .map { (pullRequest: $0, rank: nextSteps(for: $0)[0].rank) }
            .filter { $0.rank < NextStep.draft.rank }
            .enumerated()
            .sorted { ($0.element.rank, $0.offset) < ($1.element.rank, $1.offset) }
            .map(\.element.pullRequest)
    }
}

extension PullRequest {
    /// GitHub only gives a review decision when the repository requires reviews. Without one, the reviews themselves decide.
    public var approval: ReviewDecision? {
        if let reviewDecision { return reviewDecision }
        let verdicts = reviewsByPerson.values.compactMap(Self.verdict)
        if verdicts.contains(.changesRequested) { return .changesRequested }
        return verdicts.contains(.approved) ? .approved : nil
    }

    /// People whose review did not approve, who are not asked again, and who have seen no commit or reply from the author since.
    var reviewersAwaitingResponse: [String] {
        let myReplies = reviews.filter { $0.author == author }.compactMap(\.submittedAt)
        let myLastMove = (myReplies + [lastCommitAt].compactMap { $0 }).max()
        return reviewsByPerson
            .filter { reviewer, reviews in
                guard Self.verdict(reviews) != .approved, !requestedReviewers.contains(reviewer) else { return false }
                guard let myLastMove, let theirLast = reviews.compactMap(\.submittedAt).max() else { return true }
                return myLastMove <= theirLast
            }
            .keys.sorted()
    }

    private var reviewsByPerson: [String: [Review]] {
        let submitted = reviews.filter { !$0.isBot && $0.author != author && $0.state != .pending && $0.state != .dismissed }
        return Dictionary(grouping: submitted, by: \.author)
    }

    /// A person's latest approval or request for changes stands until they give another. A later comment does not replace it.
    private static func verdict(_ reviews: [Review]) -> Review.State? {
        reviews.last { $0.state == .approved || $0.state == .changesRequested }?.state
    }
}
