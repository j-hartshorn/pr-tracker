import Foundation

/// The review activity on a pull request. It costs about 60 times more to fetch than the overview, and it only changes when the pull request is updated.
struct PullRequestDetails: Equatable {
    var reviews: [Review]
    var unansweredThreadCount: Int
    var waitingSince: Date?
}

/// Fetches the details of the pull requests with the given ids.
enum DetailsQuery {
    static let text = """
    query($ids: [ID!]!) {
      nodes(ids: $ids) {
        ... on PullRequest {
          id
          author { login }
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
      }
    }

    \(GraphQL.reviewerNameFragment)
    """

    static func decode(_ data: Data) throws -> [String: PullRequestDetails] {
        let payload = try GraphQL.decode(Payload.self, from: data)
        return Dictionary(payload.nodes.compactMap { $0 }.map { ($0.id, $0.details) }, uniquingKeysWith: { first, _ in first })
    }

    private struct Payload: Decodable {
        var nodes: [Node?]
    }

    private struct Node: Decodable {
        var id: String
        var author: GraphQL.Actor?
        var reviewRequests: GraphQL.Connection<GraphQL.ReviewRequest>
        var timelineItems: GraphQL.Connection<GraphQL.ReviewRequest>
        var reviews: GraphQL.Connection<ReviewNode>
        var reviewThreads: GraphQL.Connection<ThreadNode>

        var details: PullRequestDetails {
            let author = author?.login ?? "ghost"
            return PullRequestDetails(
                reviews: reviews.elements.map(\.review),
                unansweredThreadCount: reviewThreads.elements.count { $0.isUnanswered(byAuthor: author) },
                // The longest-waiting of the reviewers who are still asked.
                waitingSince: reviewRequests.elements.compactMap(\.name).compactMap(lastRequested).min()
            )
        }

        private func lastRequested(_ reviewer: String) -> Date? {
            timelineItems.elements.filter { $0.name == reviewer }.compactMap(\.createdAt).max()
        }
    }

    private struct ThreadNode: Decodable {
        struct Comment: Decodable {
            var author: GraphQL.Actor?
        }
        var isResolved: Bool
        var comments: GraphQL.Connection<Comment>

        /// Open, and the last word is from a person other than the author.
        func isUnanswered(byAuthor author: String) -> Bool {
            guard !isResolved, let last = comments.elements.last else { return false }
            return last.author?.__typename != "Bot" && last.author?.login != author
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
    /// My pull requests that are new or updated since `previous`. Only these need their details fetched.
    func idsNeedingDetails(since previous: Snapshot?) -> [String] {
        let lastUpdated = Dictionary((previous?.authored ?? []).map { ($0.id, $0.updatedAt) }, uniquingKeysWith: { first, _ in first })
        return authored.filter { lastUpdated[$0.id] != $0.updatedAt }.map(\.id)
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
            } else if let old = known[id] {
                copy.authored[index].reviews = old.reviews
                copy.authored[index].unansweredThreadCount = old.unansweredThreadCount
                copy.authored[index].waitingSince = old.waitingSince
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
