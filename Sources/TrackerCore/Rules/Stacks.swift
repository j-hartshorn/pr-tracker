import Foundation

/// A pull request and the pull requests stacked on top of it.
public struct Stack: Equatable, Identifiable, Sendable {
    public var pullRequest: PullRequest
    public var children: [Stack]

    public var id: String { pullRequest.id }

    public init(pullRequest: PullRequest, children: [Stack] = []) {
        self.pullRequest = pullRequest
        self.children = children
    }
}

extension Snapshot {
    /// The authored pull request that `pr` is stacked on: the one whose head branch is this one's base.
    public func parent(of pr: PullRequest) -> PullRequest? {
        authored.first {
            // A head in a fork shares a branch name with the base repository only by chance.
            $0.id != pr.id && $0.repository == pr.repository && !$0.isFromFork && $0.headRef == pr.baseRef
        }
    }

    /// My pull requests as a forest. A pull request with nothing beneath it is a root, alone or not.
    public var stacks: [Stack] {
        var childrenByParent: [String: [PullRequest]] = [:]
        var roots: [PullRequest] = []
        for pr in authored {
            if let parent = parent(of: pr) {
                childrenByParent[parent.id, default: []].append(pr)
            } else {
                roots.append(pr)
            }
        }
        var placed: Set<String> = []
        func stack(_ pr: PullRequest) -> Stack {
            placed.insert(pr.id)
            let children = (childrenByParent[pr.id] ?? []).filter { !placed.contains($0.id) }
            return Stack(pullRequest: pr, children: children.map(stack))
        }
        var forest = roots.map(stack)
        // Branches that are each other's base form a loop with no root. Start it at any member so it still shows.
        for pr in authored where !placed.contains(pr.id) {
            forest.append(stack(pr))
        }
        return forest
    }
}
