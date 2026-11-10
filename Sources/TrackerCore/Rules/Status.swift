import Foundation

/// The one thing to know about a pull request at a glance. Ordered from most to least urgent.
public enum Status: Int, Comparable, Sendable {
    /// My pull request has failed CI or a merge conflict.
    case failing
    /// The next move is mine: changes were requested, or my review is requested by name.
    case attention
    /// My pull request can merge: approved, green, no conflicts, and nothing open beneath it.
    case ready
    case waiting

    public static func < (lhs: Status, rhs: Status) -> Bool { lhs.rawValue < rhs.rawValue }
}

extension Snapshot {
    public func status(of pr: PullRequest) -> Status {
        guard pr.author == viewer else {
            return reviewRequested.contains { $0.id == pr.id } ? .attention : .waiting
        }
        if pr.checks == .failing || pr.mergeability == .conflicting { return .failing }
        if pr.approval == .changesRequested { return .attention }
        let canMerge = !pr.isDraft && pr.approval == .approved && pr.checks != .pending && pr.mergeability == .mergeable
        return canMerge && parent(of: pr) == nil ? .ready : .waiting
    }

    public var mostUrgentStatus: Status {
        (authored + reviewRequested).map(status(of:)).min() ?? .waiting
    }
}

extension PullRequest {
    /// GitHub only gives a review decision when the repository requires reviews. Without one, the reviews themselves decide.
    public var approval: ReviewDecision? {
        if let reviewDecision { return reviewDecision }
        let opinions = Dictionary(grouping: reviews.filter { !$0.isBot && ($0.state == .approved || $0.state == .changesRequested) }, by: \.author)
            .compactMap { $0.value.last?.state }
        if opinions.contains(.changesRequested) { return .changesRequested }
        return opinions.contains(.approved) ? .approved : nil
    }
}
