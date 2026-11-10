import Foundation
@testable import TrackerCore

extension PullRequest {
    static func fixture(
        _ number: Int = 1,
        repository: String = "acme/widgets",
        author: String = "joe",
        isDraft: Bool = false,
        base: String = "main",
        head: String? = nil,
        isFromFork: Bool = false,
        mergeability: Mergeability = .mergeable,
        checks: Checks = .passing,
        reviewDecision: ReviewDecision? = nil,
        requestedReviewers: [String] = [],
        waitingSince: Date? = nil,
        reviews: [Review] = [],
        unansweredThreads: Int = 0,
        lastCommitAt: Date? = nil,
        mentionedAt: Date? = nil
    ) -> PullRequest {
        PullRequest(
            id: "\(repository)#\(number)",
            number: number,
            title: "Change \(number)",
            url: URL(string: "https://github.com/\(repository)/pull/\(number)")!,
            repository: repository,
            author: author,
            isDraft: isDraft,
            baseRef: base,
            headRef: head ?? "branch-\(number)",
            isFromFork: isFromFork,
            updatedAt: Date(timeIntervalSince1970: 1_700_000_000),
            mergeability: mergeability,
            checks: checks,
            reviewDecision: reviewDecision,
            requestedReviewers: requestedReviewers,
            waitingSince: waitingSince,
            reviews: reviews,
            unansweredThreadCount: unansweredThreads,
            lastCommitAt: lastCommitAt,
            mentionedAt: mentionedAt
        )
    }
}

extension Review {
    static func fixture(
        _ id: String,
        by author: String = "alice",
        isBot: Bool = false,
        _ state: State = .commented,
        comments: Int = 0,
        at submittedAt: Date = Date(timeIntervalSince1970: 1_700_000_000)
    ) -> Review {
        Review(
            id: id,
            author: author,
            isBot: isBot,
            state: state,
            submittedAt: submittedAt,
            url: URL(string: "https://github.com/acme/widgets/pull/1#pullrequestreview-\(id)")!,
            commentCount: comments
        )
    }
}

extension Snapshot {
    static func fixture(authored: [PullRequest] = [], reviewRequested: [PullRequest] = [], involved: [PullRequest] = []) -> Snapshot {
        Snapshot(viewer: "joe", authored: authored, reviewRequested: reviewRequested, involved: involved, fetchedAt: Date(timeIntervalSince1970: 1_700_000_000))
    }
}
