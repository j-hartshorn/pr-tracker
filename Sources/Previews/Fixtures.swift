import Foundation
import TrackerCore

/// A made-up snapshot that covers every state the interface can show.
enum Fixtures {
    static let now = Date(timeIntervalSince1970: 1_800_000_000)

    static let snapshot = Snapshot(
        viewer: "joe",
        authored: [
            pr(101, "Split the importer into stages", head: "importer-1", checks: .failing, hoursAgo: 2,
               reviewers: ["alice"], reviews: [bot("b1", comments: 3)]),
            pr(102, "Add a retry stage to the importer", base: "importer-1", head: "importer-2", hoursAgo: 3, reviewers: ["alice", "platform"]),
            pr(103, "Report importer progress", base: "importer-2", head: "importer-3", isDraft: true, checks: .pending, hoursAgo: 3),
            pr(104, "Importer metrics", base: "importer-1", head: "importer-metrics", isDraft: true, mergeability: .conflicting, hoursAgo: 30),
            pr(110, "Cache the dashboard query", repository: "acme/gadgets", decision: .approved, hoursAgo: 1,
               reviews: [review("r1", by: "bob", .approved), bot("b2", comments: 0)]),
            pr(111, "Rename the billing tables with a much longer title that will need to be cut off somewhere along the row", repository: "acme/gadgets",
               decision: .changesRequested, hoursAgo: 50, reviews: [review("r2", by: "carol", .changesRequested)]),
            pr(112, "Remove the old feature flags", repository: "acme/gadgets", decision: .reviewRequired, hoursAgo: 0.4, reviewers: ["dave"]),
            pr(113, "Try a new layout for settings", repository: "acme/gadgets", isDraft: true, checks: .none, hoursAgo: 200),
        ],
        reviewRequested: [
            pr(201, "Make the scheduler idempotent", author: "alice", checks: .passing, hoursAgo: 5),
            pr(202, "Bump the Go toolchain", repository: "acme/gadgets", author: "bob", checks: .failing, hoursAgo: 26),
        ],
        fetchedAt: now
    )

    private static func pr(
        _ number: Int, _ title: String, repository: String = "acme/widgets", author: String = "joe",
        base: String = "main", head: String? = nil, isDraft: Bool = false,
        mergeability: Mergeability = .mergeable, checks: Checks = .passing, decision: ReviewDecision? = .reviewRequired,
        hoursAgo: Double, reviewers: [String] = [], reviews: [Review] = []
    ) -> PullRequest {
        PullRequest(
            id: "PR_\(number)", number: number, title: title,
            url: URL(string: "https://github.com/\(repository)/pull/\(number)")!,
            repository: repository, author: author, isDraft: isDraft,
            baseRef: base, headRef: head ?? "branch-\(number)", isFromFork: false,
            updatedAt: now.addingTimeInterval(-hoursAgo * 3600),
            mergeability: mergeability, checks: checks, reviewDecision: decision,
            requestedReviewers: reviewers, reviews: reviews
        )
    }

    private static func review(_ id: String, by author: String, _ state: Review.State) -> Review {
        Review(id: id, author: author, isBot: false, state: state, submittedAt: now, url: URL(string: "https://github.com")!, commentCount: 0)
    }

    private static func bot(_ id: String, comments: Int) -> Review {
        Review(id: id, author: "copilot-pull-request-reviewer", isBot: true, state: .commented, submittedAt: now, url: URL(string: "https://github.com")!, commentCount: comments)
    }
}
