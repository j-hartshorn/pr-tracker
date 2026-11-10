import Foundation

public struct PullRequest: Codable, Equatable, Identifiable, Sendable {
    public var id: String
    public var number: Int
    public var title: String
    public var url: URL
    public var repository: String
    public var author: String
    public var isDraft: Bool
    public var baseRef: String
    public var headRef: String
    public var isFromFork: Bool
    public var updatedAt: Date
    public var mergeability: Mergeability
    public var checks: Checks
    public var reviewDecision: ReviewDecision?
    /// User logins and team slugs.
    public var requestedReviewers: [String]
    public var reviews: [Review]

    public init(
        id: String, number: Int, title: String, url: URL, repository: String, author: String,
        isDraft: Bool, baseRef: String, headRef: String, isFromFork: Bool, updatedAt: Date,
        mergeability: Mergeability, checks: Checks, reviewDecision: ReviewDecision?,
        requestedReviewers: [String], reviews: [Review]
    ) {
        self.id = id
        self.number = number
        self.title = title
        self.url = url
        self.repository = repository
        self.author = author
        self.isDraft = isDraft
        self.baseRef = baseRef
        self.headRef = headRef
        self.isFromFork = isFromFork
        self.updatedAt = updatedAt
        self.mergeability = mergeability
        self.checks = checks
        self.reviewDecision = reviewDecision
        self.requestedReviewers = requestedReviewers
        self.reviews = reviews
    }
}

public enum Mergeability: String, Codable, Sendable {
    case mergeable, conflicting, unknown
}

public enum Checks: String, Codable, Sendable {
    case none, pending, passing, failing
}

public enum ReviewDecision: String, Codable, Sendable {
    case approved, changesRequested, reviewRequired
}

public struct Review: Codable, Equatable, Identifiable, Sendable {
    public enum State: String, Codable, Sendable {
        case approved, changesRequested, commented, dismissed, pending
    }

    public var id: String
    public var author: String
    public var isBot: Bool
    public var state: State
    public var submittedAt: Date?
    public var url: URL
    public var commentCount: Int

    public init(id: String, author: String, isBot: Bool, state: State, submittedAt: Date?, url: URL, commentCount: Int) {
        self.id = id
        self.author = author
        self.isBot = isBot
        self.state = state
        self.submittedAt = submittedAt
        self.url = url
        self.commentCount = commentCount
    }
}
