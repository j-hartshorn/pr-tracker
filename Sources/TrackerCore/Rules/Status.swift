import Foundation

/// The colour of a pull request: how urgent its next steps are. Ordered from most to least urgent.
public enum Status: Int, Comparable, Sendable {
    /// Something of mine is broken.
    case failing
    /// A review is mine to do or to answer.
    case attention
    /// It is approved and can merge, now or when the pull request beneath it does.
    case ready
    /// It is approved, and its checks are still running.
    case approved
    /// The ball is with someone else.
    case waiting

    public static func < (lhs: Status, rhs: Status) -> Bool { lhs.rawValue < rhs.rawValue }
}

extension NextStep {
    public var status: Status {
        switch self {
        case .fixChecks, .resolveConflicts: .failing
        case .review, .answerComments, .answerMention, .respond, .requestReview: .attention
        case .merge, .waitingOnStack: .ready
        case .waitingOnChecks: .approved
        case .waitingOnReviewers, .waitingOnAuthor, .draft: .waiting
        }
    }
}

extension Snapshot {
    public func status(of pr: PullRequest) -> Status {
        nextSteps(for: pr).map(\.status).min() ?? .waiting
    }

    /// The most urgent status among the pull requests that need me.
    public var mostUrgentStatus: Status {
        statusesNeedingAttention.first ?? .waiting
    }

    /// One status for each pull request that needs me, most urgent first.
    public var statusesNeedingAttention: [Status] {
        needingAttention.map(status(of:)).sorted()
    }
}
