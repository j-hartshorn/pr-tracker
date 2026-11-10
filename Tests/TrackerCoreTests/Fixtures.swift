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
        reviews: [Review] = []
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
            reviews: reviews
        )
    }
}

extension Review {
    static func fixture(
        _ id: String,
        by author: String = "alice",
        isBot: Bool = false,
        _ state: State = .commented,
        comments: Int = 0
    ) -> Review {
        Review(
            id: id,
            author: author,
            isBot: isBot,
            state: state,
            submittedAt: Date(timeIntervalSince1970: 1_700_000_000),
            url: URL(string: "https://github.com/acme/widgets/pull/1#pullrequestreview-\(id)")!,
            commentCount: comments
        )
    }
}

extension Snapshot {
    static func fixture(authored: [PullRequest] = [], reviewRequested: [PullRequest] = []) -> Snapshot {
        Snapshot(viewer: "joe", authored: authored, reviewRequested: reviewRequested, fetchedAt: Date(timeIntervalSince1970: 1_700_000_000))
    }
}
