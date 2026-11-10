import Foundation

/// Everything one poll learned about the pull requests the viewer is involved with.
public struct Snapshot: Codable, Equatable, Sendable {
    public var viewer: String
    public var authored: [PullRequest]
    /// Pull requests where the viewer is requested by name, not through a team.
    public var reviewRequested: [PullRequest]
    /// Other people's pull requests where the viewer is mentioned or has commented, and is not requested.
    public var involved: [PullRequest]
    public var fetchedAt: Date

    public init(viewer: String, authored: [PullRequest], reviewRequested: [PullRequest], involved: [PullRequest] = [], fetchedAt: Date) {
        self.viewer = viewer
        self.authored = authored
        self.reviewRequested = reviewRequested
        self.involved = involved
        self.fetchedAt = fetchedAt
    }
}
