import Foundation

/// The review activity on a pull request. It costs about 60 times more to fetch than the overview, and it only changes when the pull request is updated.
struct PullRequestDetails: Equatable {
    var reviews: [Review]
    var unansweredThreadCount: Int
    var waitingSince: Date?
    var lastCommentAt: Date?
}

/// Fetches the details of the pull requests with the given ids.
enum DetailsQuery {
    static let text = """
    query($ids: [ID!]!) {
      nodes(ids: $ids) {
        ... on PullRequest {
          id
          reviewRequests(first: 20) { nodes { requestedReviewer { ...ReviewerName } } }
          timelineItems(last: 30, itemTypes: [REVIEW_REQUESTED_EVENT]) {
            nodes { ... on ReviewRequestedEvent { createdAt requestedReviewer { ...ReviewerName } } }
          }
          comments(last: 30) {
            nodes { createdAt author { __typename login } }
          }
          reviews(last: 30) {
            nodes { id state submittedAt url author { __typename login } comments { totalCount } }
          }
          reviewThreads(first: 100) {
            nodes {
              isResolved
              comments(last: 1) { nodes { author { __typename login } reactionGroups { viewerHasReacted } } }
            }
          }
        }
      }
    }

    \(GraphQL.reviewerNameFragment)
    """

    static func decode(_ data: Data, viewer: String) throws -> [String: PullRequestDetails] {
        let payload = try GraphQL.decode(Payload.self, from: data)
        return Dictionary(payload.nodes.compactMap { $0 }.map { ($0.id, $0.details(viewer: viewer)) }, uniquingKeysWith: { first, _ in first })
    }

    private struct Payload: Decodable {
        var nodes: [Node?]
    }

    private struct Node: Decodable {
        var id: String
        var reviewRequests: GraphQL.Connection<GraphQL.ReviewRequest>
        var timelineItems: GraphQL.Connection<GraphQL.ReviewRequest>
        var comments: GraphQL.Connection<CommentNode>
        var reviews: GraphQL.Connection<ReviewNode>
        var reviewThreads: GraphQL.Connection<ThreadNode>

        func details(viewer: String) -> PullRequestDetails {
            PullRequestDetails(
                reviews: reviews.elements.map(\.review),
                unansweredThreadCount: reviewThreads.elements.count { $0.waits(on: viewer) },
                // The longest-waiting of the reviewers who are still asked.
                waitingSince: reviewRequests.elements.compactMap(\.name).compactMap(lastRequested).min(),
                lastCommentAt: comments.elements.filter { $0.author?.__typename != "Bot" }.map(\.createdAt).max()
            )
        }

        private func lastRequested(_ reviewer: String) -> Date? {
            timelineItems.elements.filter { $0.name == reviewer }.compactMap(\.createdAt).max()
        }
    }

    private struct CommentNode: Decodable {
        var createdAt: Date
        var author: GraphQL.Actor?
    }

    private struct ThreadNode: Decodable {
        var isResolved: Bool
        var comments: GraphQL.Connection<GraphQL.ThreadComment>

        func waits(on viewer: String) -> Bool {
            guard !isResolved, let last = comments.elements.last else { return false }
            return last.isUnanswered(by: viewer)
        }
    }

    private struct ReviewNode: Decodable {
        struct Comments: Decodable { var totalCount: Int }
        var id: String
        var state: String
        var submittedAt: Date?
        var url: URL
        var author: GraphQL.Actor?
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
}

extension Snapshot {
    /// My pull requests that are new or updated since `previous`, or that had a thread waiting on me. Only these need their details fetched.
    /// A reaction does not change `updatedAt`, so a waiting thread is checked again on every poll to see whether I reacted to it.
    func idsNeedingDetails(since previous: Snapshot?) -> [String] {
        Self.needingDetails(authored, previous: previous?.authored ?? [])
    }

    static func needingDetails(_ current: [PullRequest], previous: [PullRequest]) -> [String] {
        let known = Dictionary(previous.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        return current.filter { pr in
            guard let old = known[pr.id] else { return true }
            return old.updatedAt != pr.updatedAt || old.unansweredThreadCount > 0
        }.map(\.id)
    }

    /// Fills in the details of my pull requests: the fetched ones, and for the rest what `previous` already had.
    func withDetails(_ fetched: [String: PullRequestDetails], reusing previous: Snapshot?) -> Snapshot {
        let known = Dictionary((previous?.authored ?? []).map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        var copy = self
        for index in copy.authored.indices {
            let id = copy.authored[index].id
            if let details = fetched[id] {
                copy.authored[index].reviews = details.reviews
                copy.authored[index].unansweredThreadCount = details.unansweredThreadCount
                copy.authored[index].waitingSince = details.waitingSince
                copy.authored[index].lastCommentAt = details.lastCommentAt
            } else if let old = known[id] {
                copy.authored[index].reviews = old.reviews
                copy.authored[index].unansweredThreadCount = old.unansweredThreadCount
                copy.authored[index].waitingSince = old.waitingSince
                copy.authored[index].lastCommentAt = old.lastCommentAt
            }
        }
        return copy
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
