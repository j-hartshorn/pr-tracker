import Foundation

/// The one query a poll makes, and the mapping from its response to a `Snapshot`.
enum SnapshotQuery {
    static let text = """
    query {
      viewer { login }
      authored: search(query: "is:pr is:open archived:false author:@me sort:updated-desc", type: ISSUE, first: 100) {
        nodes { ...PullRequestFields }
      }
      reviewRequested: search(query: "is:pr is:open archived:false user-review-requested:@me sort:updated-desc", type: ISSUE, first: 100) {
        nodes { ...PullRequestFields }
      }
    }

    fragment PullRequestFields on PullRequest {
      id number title url isDraft updatedAt
      author { login }
      repository { nameWithOwner }
      headRepository { nameWithOwner }
      baseRefName headRefName
      mergeable reviewDecision
      commits(last: 1) { nodes { commit { committedDate statusCheckRollup { state } } } }
      reviewRequests(first: 20) { nodes { requestedReviewer { ...ReviewerName } } }
      timelineItems(last: 30, itemTypes: [REVIEW_REQUESTED_EVENT]) {
        nodes { ... on ReviewRequestedEvent { createdAt requestedReviewer { ...ReviewerName } } }
      }
      reviews(last: 30) {
        nodes { id state submittedAt url author { __typename login } comments { totalCount } }
      }
      reviewThreads(first: 100) {
        nodes { isResolved comments(last: 1) { nodes { author { __typename login } } } }
      }
    }

    fragment ReviewerName on RequestedReviewer {
      ... on User { login }
      ... on Team { slug }
      ... on Bot { login }
      ... on Mannequin { login }
    }
    """

    static func decode(_ data: Data, fetchedAt: Date) throws -> Snapshot {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let response = try decoder.decode(Response.self, from: data)
        // GitHub can return partial data next to errors, for example when one org needs SSO.
        guard let data = response.data else {
            throw GitHubError.graphQL(response.errors?.first?.message ?? "empty response")
        }
        return Snapshot(
            viewer: data.viewer.login,
            authored: data.authored.pullRequests,
            reviewRequested: data.reviewRequested.pullRequests,
            fetchedAt: fetchedAt
        )
    }

    private struct Response: Decodable {
        var data: Payload?
        var errors: [GraphQLError]?
    }

    private struct GraphQLError: Decodable {
        var message: String
    }

    private struct Payload: Decodable {
        var viewer: Actor
        var authored: Search
        var reviewRequested: Search
    }

    private struct Search: Decodable {
        var nodes: [Node?]
        var pullRequests: [PullRequest] { nodes.compactMap { $0?.pullRequest } }
    }

    private struct Actor: Decodable {
        var login: String
        var __typename: String?
    }

    private struct Repository: Decodable {
        var nameWithOwner: String
    }

    private struct Connection<Element: Decodable>: Decodable {
        var nodes: [Element?]
    }

    private struct CommitNode: Decodable {
        struct Commit: Decodable {
            struct Rollup: Decodable { var state: String }
            var committedDate: Date
            var statusCheckRollup: Rollup?
        }
        var commit: Commit
    }

    private struct ReviewRequest: Decodable {
        struct Reviewer: Decodable {
            var login: String?
            var slug: String?
            var name: String? { login ?? slug }
        }
        var requestedReviewer: Reviewer?
        /// Only on the timeline's request events.
        var createdAt: Date?
    }

    private struct ThreadNode: Decodable {
        var isResolved: Bool
        var comments: Connection<Comment>

        struct Comment: Decodable {
            var author: Actor?
        }

        func isUnanswered(byAuthor author: String) -> Bool {
            guard !isResolved, let last = comments.nodes.compactMap({ $0 }).last else { return false }
            return last.author?.__typename != "Bot" && last.author?.login != author
        }
    }

    private struct ReviewNode: Decodable {
        struct Comments: Decodable { var totalCount: Int }
        var id: String
        var state: String
        var submittedAt: Date?
        var url: URL
        var author: Actor?
        var comments: Comments

        var review: Review {
            Review(
                id: id,
                author: author?.login ?? "ghost",
                isBot: author?.__typename == "Bot",
                state: Review.State(graphQL: state),
                submittedAt: submittedAt,
                url: url,
                commentCount: comments.totalCount
            )
        }
    }

    private struct Node: Decodable {
        var id: String
        var number: Int
        var title: String
        var url: URL
        var isDraft: Bool
        var updatedAt: Date
        var author: Actor?
        var repository: Repository
        var headRepository: Repository?
        var baseRefName: String
        var headRefName: String
        var mergeable: String
        var reviewDecision: String?
        var commits: Connection<CommitNode>
        var reviewRequests: Connection<ReviewRequest>
        var timelineItems: Connection<ReviewRequest>
        var reviews: Connection<ReviewNode>
        var reviewThreads: Connection<ThreadNode>

        var pullRequest: PullRequest {
            let author = author?.login ?? "ghost"
            let lastCommit = commits.nodes.compactMap { $0 }.last?.commit
            let requestedReviewers = reviewRequests.nodes.compactMap { $0?.requestedReviewer?.name }
            return PullRequest(
                id: id,
                number: number,
                title: title,
                url: url,
                repository: repository.nameWithOwner,
                author: author,
                isDraft: isDraft,
                baseRef: baseRefName,
                headRef: headRefName,
                isFromFork: headRepository?.nameWithOwner != repository.nameWithOwner,
                updatedAt: updatedAt,
                mergeability: Mergeability(graphQL: mergeable),
                checks: Checks(graphQL: lastCommit?.statusCheckRollup?.state),
                reviewDecision: reviewDecision.flatMap(ReviewDecision.init(graphQL:)),
                requestedReviewers: requestedReviewers,
                waitingSince: requestedReviewers.compactMap(lastRequested).min(),
                reviews: reviews.nodes.compactMap { $0?.review },
                unansweredThreadCount: reviewThreads.nodes.compactMap { $0 }.count { $0.isUnanswered(byAuthor: author) },
                lastCommitAt: lastCommit?.committedDate
            )
        }

        private func lastRequested(_ reviewer: String) -> Date? {
            timelineItems.nodes.compactMap { $0 }.filter { $0.requestedReviewer?.name == reviewer }.compactMap(\.createdAt).max()
        }
    }
}

private extension Mergeability {
    init(graphQL: String) {
        self = switch graphQL {
        case "MERGEABLE": .mergeable
        case "CONFLICTING": .conflicting
        default: .unknown
        }
    }
}

private extension Checks {
    init(graphQL: String?) {
        self = switch graphQL {
        case nil: .none
        case "SUCCESS": .passing
        case "FAILURE", "ERROR": .failing
        default: .pending
        }
    }
}

private extension ReviewDecision {
    init?(graphQL: String) {
        switch graphQL {
        case "APPROVED": self = .approved
        case "CHANGES_REQUESTED": self = .changesRequested
        case "REVIEW_REQUIRED": self = .reviewRequired
        default: return nil
        }
    }
}

private extension Review.State {
    init(graphQL: String) {
        self = switch graphQL {
        case "APPROVED": .approved
        case "CHANGES_REQUESTED": .changesRequested
        case "DISMISSED": .dismissed
        case "PENDING": .pending
        default: .commented
        }
    }
}
