import Foundation

/// The query every poll makes. It is cheap: it lists the pull requests with the fields that can change without the pull request itself being updated, such as checks and mergeability. Everything expensive is in `DetailsQuery`.
enum OverviewQuery {
    // GitHub charges for the page size asked for, not for what comes back, so this is no larger than it needs to be.
    static let text = """
    query {
      viewer { login }
      authored: search(query: "is:pr is:open archived:false author:@me sort:updated-desc", type: ISSUE, first: 50) {
        nodes { ...Overview }
      }
      reviewRequested: search(query: "is:pr is:open archived:false user-review-requested:@me sort:updated-desc", type: ISSUE, first: 50) {
        nodes { ...Overview }
      }
      involved: search(query: "is:pr is:open archived:false involves:@me -author:@me -user-review-requested:@me sort:updated-desc", type: ISSUE, first: 30) {
        nodes { ...Overview }
      }
    }

    fragment Overview on PullRequest {
      id number title url isDraft updatedAt
      author { login }
      repository { nameWithOwner }
      headRepository { nameWithOwner }
      baseRefName headRefName
      mergeable reviewDecision
      commits(last: 1) { nodes { commit { committedDate statusCheckRollup { state } } } }
      reviewRequests(first: 20) { nodes { requestedReviewer { ...ReviewerName } } }
    }

    \(GraphQL.reviewerNameFragment)
    """

    /// The pull requests come back without details: no reviews, no threads and no waiting time.
    static func decode(_ data: Data, fetchedAt: Date) throws -> Snapshot {
        let payload = try GraphQL.decode(Payload.self, from: data)
        return Snapshot(
            viewer: payload.viewer.login,
            authored: payload.authored.elements.map(\.pullRequest),
            reviewRequested: payload.reviewRequested.elements.map(\.pullRequest),
            involved: payload.involved?.elements.map(\.pullRequest) ?? [],
            fetchedAt: fetchedAt
        )
    }

    private struct Payload: Decodable {
        var viewer: GraphQL.Actor
        var authored: GraphQL.Connection<Node>
        var reviewRequested: GraphQL.Connection<Node>
        var involved: GraphQL.Connection<Node>?
    }

    private struct Repository: Decodable {
        var nameWithOwner: String
    }

    private struct CommitNode: Decodable {
        struct Commit: Decodable {
            struct Rollup: Decodable { var state: String }
            var committedDate: Date
            var statusCheckRollup: Rollup?
        }
        var commit: Commit
    }

    private struct Node: Decodable {
        var id: String
        var number: Int
        var title: String
        var url: URL
        var isDraft: Bool
        var updatedAt: Date
        var author: GraphQL.Actor?
        var repository: Repository
        var headRepository: Repository?
        var baseRefName: String
        var headRefName: String
        var mergeable: String
        var reviewDecision: String?
        var commits: GraphQL.Connection<CommitNode>
        var reviewRequests: GraphQL.Connection<GraphQL.ReviewRequest>

        var pullRequest: PullRequest {
            let lastCommit = commits.elements.last?.commit
            return PullRequest(
                id: id,
                number: number,
                title: title,
                url: url,
                repository: repository.nameWithOwner,
                author: author?.login ?? "ghost",
                isDraft: isDraft,
                baseRef: baseRefName,
                headRef: headRefName,
                isFromFork: headRepository?.nameWithOwner != repository.nameWithOwner,
                updatedAt: updatedAt,
                mergeability: Mergeability(graphQL: mergeable),
                checks: Checks(graphQL: lastCommit?.statusCheckRollup?.state),
                reviewDecision: reviewDecision.flatMap(ReviewDecision.init(graphQL:)),
                requestedReviewers: reviewRequests.elements.compactMap(\.name),
                waitingSince: nil,
                reviews: [],
                unansweredThreadCount: 0,
                lastCommitAt: lastCommit?.committedDate
            )
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
