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
    /// When the longest-waiting of the requested reviewers was asked.
    public var waitingSince: Date?
    public var reviews: [Review]
    /// Open review threads that wait on the viewer. On their own pull request, a person other than them spoke last. On another person's, the viewer began the thread and someone else spoke last.
    public var unansweredThreadCount: Int
    public var lastCommitAt: Date?
    /// On another person's pull request: when the viewer was last mentioned, if they have not commented or reviewed since.
    public var mentionedAt: Date?

    public init(
        id: String, number: Int, title: String, url: URL, repository: String, author: String,
        isDraft: Bool, baseRef: String, headRef: String, isFromFork: Bool, updatedAt: Date,
        mergeability: Mergeability, checks: Checks, reviewDecision: ReviewDecision?,
        requestedReviewers: [String], waitingSince: Date?, reviews: [Review],
        unansweredThreadCount: Int, lastCommitAt: Date?, mentionedAt: Date? = nil
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
        self.waitingSince = waitingSince
        self.reviews = reviews
        self.unansweredThreadCount = unansweredThreadCount
        self.lastCommitAt = lastCommitAt
        self.mentionedAt = mentionedAt
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
