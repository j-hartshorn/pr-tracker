import Foundation

/// The shapes that both queries share.
enum GraphQL {
    /// GitHub can return partial data next to errors, for example when one org needs SSO.
    struct Response<Payload: Decodable>: Decodable {
        var data: Payload?
        var errors: [ResponseError]?
    }

    struct ResponseError: Decodable {
        var type: String?
        var message: String
    }

    struct Connection<Element: Decodable>: Decodable {
        var nodes: [Element?]
        var elements: [Element] { nodes.compactMap { $0 } }
    }

    struct Actor: Decodable {
        var login: String
        var __typename: String?
    }

    struct ThreadComment: Decodable {
        struct ReactionGroup: Decodable {
            var viewerHasReacted: Bool
        }
        var author: Actor?
        var reactionGroups: [ReactionGroup]?

        func isUnanswered(by viewer: String) -> Bool {
            let reacted = (reactionGroups ?? []).contains { $0.viewerHasReacted }
            return author?.__typename != "Bot" && author?.login != viewer && !reacted
        }
    }

    /// A requested reviewer, on a pull request or on a "review requested" event in its timeline.
    struct ReviewRequest: Decodable {
        struct Reviewer: Decodable {
            var login: String?
            var slug: String?
        }
        var requestedReviewer: Reviewer?
        var createdAt: Date?
        var name: String? { requestedReviewer?.login ?? requestedReviewer?.slug }
    }

    static let reviewerNameFragment = """
    fragment ReviewerName on RequestedReviewer {
      ... on User { login }
      ... on Team { slug }
      ... on Bot { login }
      ... on Mannequin { login }
    }
    """

    static func decode<Payload: Decodable>(_ type: Payload.Type, from data: Data) throws -> Payload {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let response = try decoder.decode(Response<Payload>.self, from: data)
        guard let payload = response.data else {
            throw GitHubError.graphQL(response.errors?.first?.message ?? "empty response")
        }
        return payload
    }
}
