import Foundation

/// What waits on the viewer on another person's pull request.
struct InvolvedDetails: Equatable {
    var unansweredThreadCount: Int
    var mentionedAt: Date?
}

/// Fetches, for other people's pull requests, the mentions of the viewer and the replies to their review comments. It costs about 2 points for each pull request.
enum InvolvedQuery {
    static let text = """
    query($ids: [ID!]!) {
      nodes(ids: $ids) {
        ... on PullRequest {
          id
          timelineItems(last: 40, itemTypes: [MENTIONED_EVENT, ISSUE_COMMENT, PULL_REQUEST_REVIEW]) {
            nodes {
              __typename
              ... on MentionedEvent { createdAt actor { login } }
              ... on IssueComment { createdAt author { login } }
              ... on PullRequestReview { createdAt author { login } }
            }
          }
          reviewThreads(first: 100) {
            nodes {
              isResolved
              first: comments(first: 1) { nodes { author { login } } }
              last: comments(last: 1) { nodes { author { __typename login } reactionGroups { viewerHasReacted } } }
            }
          }
        }
      }
    }
    """

    static func decode(_ data: Data, viewer: String) throws -> [String: InvolvedDetails] {
        let payload = try GraphQL.decode(Payload.self, from: data)
        return Dictionary(payload.nodes.compactMap { $0 }.map { ($0.id, $0.details(viewer: viewer)) }, uniquingKeysWith: { first, _ in first })
    }

    private struct Payload: Decodable {
        var nodes: [Node?]
    }

    private struct Node: Decodable {
        var id: String
        var timelineItems: GraphQL.Connection<TimelineItem>
        var reviewThreads: GraphQL.Connection<ThreadNode>

        func details(viewer: String) -> InvolvedDetails {
            let items = timelineItems.elements
            // A mentioned event's actor is the person who was mentioned.
            let mentioned = items.filter { $0.__typename == "MentionedEvent" && $0.actor?.login == viewer }.map(\.createdAt).max()
            let spoke = items.filter { $0.author?.login == viewer }.map(\.createdAt).max()
            let answered = mentioned.map { mention in spoke.map { $0 >= mention } ?? false } ?? true
            return InvolvedDetails(
                unansweredThreadCount: reviewThreads.elements.count { $0.waits(on: viewer) },
                mentionedAt: answered ? nil : mentioned
            )
        }
    }

    private struct TimelineItem: Decodable {
        var __typename: String
        var createdAt: Date
        var actor: GraphQL.Actor?
        var author: GraphQL.Actor?
    }

    private struct ThreadNode: Decodable {
        var isResolved: Bool
        var first: GraphQL.Connection<GraphQL.ThreadComment>
        var last: GraphQL.Connection<GraphQL.ThreadComment>

        func waits(on viewer: String) -> Bool {
            guard !isResolved, first.elements.first?.author?.login == viewer, let last = last.elements.last else { return false }
            return last.isUnanswered(by: viewer)
        }
    }
}

extension Snapshot {
    /// Other people's pull requests that are new or updated since `previous`, or that had a thread waiting on me (see `idsNeedingDetails`).
    func involvedIDsNeedingDetails(since previous: Snapshot?) -> [String] {
        Self.needingDetails(involved, previous: previous?.involved ?? [])
    }

    /// Fills in what waits on me on other people's pull requests: the fetched ones, and for the rest what `previous` already had.
    func withInvolvedDetails(_ fetched: [String: InvolvedDetails], reusing previous: Snapshot?) -> Snapshot {
        let known = Dictionary((previous?.involved ?? []).map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        var copy = self
        for index in copy.involved.indices {
            let id = copy.involved[index].id
            copy.involved[index].unansweredThreadCount = fetched[id]?.unansweredThreadCount ?? known[id]?.unansweredThreadCount ?? 0
            copy.involved[index].mentionedAt = fetched[id].map(\.mentionedAt) ?? known[id]?.mentionedAt
        }
        return copy
    }
}
