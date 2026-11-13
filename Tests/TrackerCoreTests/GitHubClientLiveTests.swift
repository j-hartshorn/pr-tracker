import Foundation
import Testing
@testable import TrackerCore

/// These talk to github.com with the gh token. They only read. Run them with GH_TRACKER_LIVE=1.
@Suite(.enabled(if: ProcessInfo.processInfo.environment["GH_TRACKER_LIVE"] != nil))
struct GitHubClientLiveTests {
    @Test func fetchesASnapshotAndReusesItsDetails() async throws {
        let client = GitHubClient()
        let first = try await client.fetchSnapshot(reusing: nil)
        #expect(!first.viewer.isEmpty)
        #expect(first.authored.allSatisfy { $0.author == first.viewer })

        let second = try await client.fetchSnapshot(reusing: first)
        for pr in second.authored {
            guard let before = first.authored.first(where: { $0.id == pr.id }), before.updatedAt == pr.updatedAt else { continue }
            #expect(pr.reviews == before.reviews)
            #expect(pr.unansweredThreadCount == before.unansweredThreadCount)
            #expect(pr.waitingSince == before.waitingSince)
            #expect(pr.lastCommentAt == before.lastCommentAt)
        }
    }
}
