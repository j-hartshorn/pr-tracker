import Foundation
import Testing
@testable import TrackerCore

/// These talk to github.com with the gh token. They only read. Run them with GH_TRACKER_LIVE=1.
@Suite(.enabled(if: ProcessInfo.processInfo.environment["GH_TRACKER_LIVE"] != nil))
struct GitHubClientLiveTests {
    @Test func fetchesASnapshot() async throws {
        let snapshot = try await GitHubClient().fetchSnapshot()
        #expect(!snapshot.viewer.isEmpty)
        #expect(snapshot.authored.allSatisfy { $0.author == snapshot.viewer })
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
