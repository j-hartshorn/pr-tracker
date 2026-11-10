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
        }
    }

    // A made-up id, so GitHub checks both mutations against its schema without changing anything.
    @Test(arguments: [true, false])
    func setDraftReportsThatThePullRequestDoesNotExist(isDraft: Bool) async {
        do {
            try await GitHubClient().setDraft(isDraft, pullRequestID: "PR_does_not_exist")
            Issue.record("expected GitHub to reject the id")
        } catch let GitHubError.graphQL(message) {
            #expect(message.contains("Could not resolve to a node"))
        } catch {
            Issue.record("unexpected error: \(error)")
        }
    }
}
